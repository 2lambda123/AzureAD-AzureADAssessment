<#
.SYNOPSIS
    Start Operation and Stopwatch for Application Insights Request.
.EXAMPLE
    PS C:\>Start-AppInsightsRequest $MyInvocation.MyCommand.Name
    Start Operation and Stopwatch for Application Insights Request.
.INPUTS
    System.String
#>
function Start-AppInsightsRequest {
    [CmdletBinding()]
    [Alias('Start-AIRequest')]
    param (
        # Operation Name
        [Parameter(Mandatory = $true)]
        [string] $Name
    )

    ## Return Immediately when Telemetry is Disabled
    if ($script:ModuleConfig.'ai.disabled') { return }

    $Operation = @{
        Id        = New-Guid
        Name      = $Name
        ParentId  = $null
        Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }

    if ($script:AppInsightsRuntimeState.OperationStack.Count -gt 0) {
        $Operation['ParentId'] = $script:AppInsightsRuntimeState.OperationStack.Peek().Id
        $Operation['Id'] = $script:AppInsightsRuntimeState.OperationStack.Peek().Id  # Use the same id as parent
    }

    $script:AppInsightsRuntimeState.OperationStack.Push($Operation)

    Write-AppInsightsTrace "Invoking Command: $Name" -SeverityLevel Information

    #return $Operation
    #return New-Object System.Collections.ArrayList
}
