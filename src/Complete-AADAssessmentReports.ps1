
function Complete-AADAssessmentReports {
    [CmdletBinding()]
    param
    (
        # Specifies a path
        [Parameter(Mandatory = $true)]
        [Alias("PSPath")]
        [string] $Path
    )

    Start-AppInsightsRequest $MyInvocation.MyCommand.Name
    try {
        if (!$script:ConnectState.MsGraphToken) {
            #Connect-AADAssessment
            if (!$script:ConnectState.ClientApplication) {
                $script:ConnectState.ClientApplication = New-MsalClientApplication -ClientId $script:ModuleConfig.'aad.clientId' -RedirectUri 'http://localhost'
                $script:ConnectState.CloudEnvironment = 'Global'
            }
            $CorrelationId = New-Guid
            if ($script:AppInsightsRuntimeState.OperationStack.Count -gt 0) {
                $CorrelationId = $script:AppInsightsRuntimeState.OperationStack.Peek().Id
            }
            ## Authenticate with Lightweight Consent
            $script:ConnectState.MsGraphToken = Get-MsalToken -PublicClientApplication $script:ConnectState.ClientApplication -Scopes 'openid' -UseEmbeddedWebView:$false -CorrelationId $CorrelationId -Verbose:$false -ErrorAction Stop
        }

        ## Initialize Paths
        $OutputDirectory = Join-Path (Split-Path $Path) ([IO.Path]::GetFileNameWithoutExtension($Path))
        $AssessmentDetailPath = Join-Path $OutputDirectory "AzureADAssessment.json"

        ## Expand Date Package
        Expand-Archive $Path -DestinationPath $OutputDirectory -Force
        $AssessmentDetail = Get-Content $AssessmentDetailPath -Raw | ConvertFrom-Json
        
        ## Copy for PowerBI Dashboard
        $PowerBIWorkingDirectory = 'C:\AAD Configuration Assessment'
        Assert-DirectoryExists $PowerBIWorkingDirectory
        Copy-Item -Path (Join-Path $OutputDirectory 'AAD-*\*') -Destination $PowerBIWorkingDirectory -Force

        ## Report Complete
        Write-AppInsightsEvent 'AAD Assessment Report Generation Complete' -OverrideProperties -Properties @{
            AssessmentId       = $AssessmentDetail.AssessmentId
            AssessmentVersion  = $AssessmentDetail.AssessmentVersion
            AssessmentTenantId = $AssessmentDetail.AssessmentTenantId
            AssessorTenantId   = $script:ConnectState.MsGraphToken.Account.HomeAccountId.TenantId
            AssessorUserId     = if ($script:ConnectState.MsGraphToken -and $script:ConnectState.MsGraphToken.Account.HomeAccountId.TenantId -in ('72f988bf-86f1-41af-91ab-2d7cd011db47', 'cc7d0b33-84c6-4368-a879-2e47139b7b1f')) { $script:ConnectState.MsGraphToken.Account.HomeAccountId.ObjectId }
        }

        ## Download and Save ADFSAADMigrationUtils Module
        $AdfsAadMigrationModulePath = Join-Path $OutputDirectory 'ADFSAADMigrationUtils.psm1'
        Invoke-WebRequest -Uri 'https://github.com/AzureAD/Deployment-Plans/raw/master/ADFS%20to%20AzureAD%20App%20Migration/ADFSAADMigrationUtils.psm1' -UseBasicParsing -OutFile $AdfsAadMigrationModulePath

        ## Download PowerBI Dashboard
        $AdfsAadMigrationModulePath = Join-Path $PowerBIWorkingDirectory '4a-AAD Configuration Assessment - PowerShell.pbit'
        Invoke-WebRequest -Uri 'https://github.com/AzureAD/AzureADAssessment/raw/refactor/assets/4a-AAD%20Configuration%20Assessment%20-%20PowerShell.pbit' -UseBasicParsing -OutFile $AdfsAadMigrationModulePath

        ## Expand AAD Connect

        ## Expand other zips?
    }
    catch { if ($MyInvocation.CommandOrigin -eq 'Runspace') { Write-AppInsightsException $_.Exception }; throw }
    finally { Complete-AppInsightsRequest $MyInvocation.MyCommand.Name -Success $true }
}
