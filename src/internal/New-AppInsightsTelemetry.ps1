<#
.SYNOPSIS
    Get new telemetry entry.
.EXAMPLE
    PS C:\>New-AppInsightsTelemetry 'AppEvents'
    Get new entry for AppEvent.
.INPUTS
    System.String
#>
function New-AppInsightsTelemetry {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        # Telemetry Type Name
        [Parameter(Mandatory = $true)]
        [ValidateSet('AppDependencies', 'AppEvents', 'AppExceptions', 'AppRequests', 'AppTraces')]
        [string] $Name,
        # Instrumentation Key
        [Parameter(Mandatory = $false)]
        [string] $InstrumentationKey = $script:ModuleConfig.'ai.instrumentationKey'
    )

    [hashtable] $mapNameToBaseType = @{
        'AppDependencies' = 'RemoteDependencyData'
        'AppEvents'       = 'EventData'
        'AppExceptions'   = 'ExceptionData'
        'AppRequests'     = 'RequestData'
        'AppTraces'       = 'MessageData'
    }

    $Operation = $script:AppInsightsRuntimeState.OperationStack.Peek()

    $AppInsightsTelemetry = [ordered]@{
        name = $Name
        time = $null
        iKey = $InstrumentationKey
        tags = [ordered]@{
            "ai.application.ver"    = $MyInvocation.MyCommand.Module.Version.ToString()
            "ai.operation.id"       = $Operation.Id
            "ai.operation.name"     = $Operation.Name
            "ai.operation.parentId" = $Operation.ParentId
            "ai.session.id"         = $script:AppInsightsRuntimeState.SessionId
            "ai.user.id"            = $script:AppInsightsState.UserId
        }
        data = [ordered]@{
            baseType = $mapNameToBaseType[$Name]
            baseData = [ordered]@{
                ver        = 2
                properties = $null
            }
        }
    }

    ## Update Time
    if ($PSVersionTable.PSVersion -ge [version]'7.1') { $AppInsightsTelemetry['time'] = Get-Date -AsUTC -Format 'o' }
    else { $AppInsightsTelemetry['time'] = [datetime]::UtcNow.ToString('o') }

    ## Update OS
    if ($PSVersionTable.PSEdition -eq 'Core') {
        $AppInsightsTelemetry.tags['ai.device.osVersion'] = $PSVersionTable.OS
    }
    else {
        $AppInsightsTelemetry.tags['ai.device.osVersion'] = ('Microsoft Windows {0}' -f $PSVersionTable.BuildVersion)
    }

    ## Add Authenticated MSFT User
    if ($script:ConnectState.MsGraphToken -and $script:ConnectState.MsGraphToken.Account.HomeAccountId.TenantId -in ('72f988bf-86f1-41af-91ab-2d7cd011db47', 'cc7d0b33-84c6-4368-a879-2e47139b7b1f')) {
        $AppInsightsTelemetry.tags['ai.user.authUserId'] = $script:ConnectState.MsGraphToken.Account.HomeAccountId.Identifier
    }

    ## Add Default Custom Properties
    $AppInsightsTelemetry.data.baseData['properties'] = [ordered]@{
        Culture         = [System.Threading.Thread]::CurrentThread.CurrentCulture.Name
        PsEdition       = $PSVersionTable.PSEdition.ToString()
        PsVersion       = $PSVersionTable.PSVersion.ToString()
        DebugPreference = $DebugPreference
    }
    if ($script:ConnectState.MsGraphToken) {
        $AppInsightsTelemetry.data.baseData['properties']['TenantId'] = $script:ConnectState.MsGraphToken.Account.HomeAccountId.TenantId
    }

    return $AppInsightsTelemetry
}
