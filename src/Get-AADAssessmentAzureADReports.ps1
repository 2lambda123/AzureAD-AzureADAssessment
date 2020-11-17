<# 
 .Synopsis
  Produces the Azure AD Configuration reports required by the Azure AD assesment
 .Description
  This cmdlet reads the configuration information from the target Azure AD Tenant and produces the output files 
  in a target directory

 .PARAMETER OutputDirectory
    Full path of the directory where the output files will be generated.

.EXAMPLE
   .\Get-AADAssessmentAzureADReports -OutputDirectory "c:\temp\contoso" 

#>
Function Get-AADAssessmentAzureADReports {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [String]$OutputDirectory
    )

    

    $reportsToRun = @{
        "Get-AADAssessNotificationEmailAddresses"     = "NotificationsEmailAddresses.csv"
        "Get-AADAssessAppAssignmentReport"            = "AppAssignments.csv"
        "Get-AADAssessApplicationKeyExpirationReport" = "AppKeysReport.csv"
        "Get-AADAssessConsentGrantList"               = "ConsentGrantList.csv"
    }

    $totalReports = $reportsToRun.Count + 1 #to include conditional access
    $processedReports = 0

    foreach ($reportKvP in $reportsToRun.GetEnumerator()) {
        Connect-AADAssessment
        $functionName = $reportKvP.Name
        $outputFileName = $reportKvP.Value
        $percentComplete = 100 * $processedReports / $totalReports
        Write-Progress -Activity "Reading Azure AD Configuration" -CurrentOperation "Running Report $functionName" -PercentComplete $percentComplete
        Get-MSCloudIdAssessmentSingleReport -FunctionName $functionName -OutputDirectory $OutputDirectory -OutputCSVFileName $outputFileName
        $processedReports++
    }

    $percentComplete = 100 * $processedReports / $totalReports
    Write-Progress -Activity "Reading Azure AD Configuration" -CurrentOperation "Running Report Get-AADAssessCAPolicyReports" -PercentComplete $percentComplete
    
    Connect-AADAssessment
    Get-AADAssessCAPolicyReports -OutputDirectory $OutputDirectory
}
