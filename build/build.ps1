$buildVersion = $env:BUILDVER

$manifestPath = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath "_AzureAD_AzureADAssessment\MSCloudIdAssessment.psd1"

## Update build version in manifest
$manifestContent = Get-Content -Path $manifestPath -Raw
$manifestContent = $manifestContent -replace '<moduleversion>', $buildVersion
