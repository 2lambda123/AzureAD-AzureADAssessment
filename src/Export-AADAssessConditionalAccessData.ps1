<#
 .Synopsis
  Produces the Azure AD Conditional Access reports required by the Azure AD assesment
 .Description
  This cmdlet reads the conditional access from the target Azure AD Tenant and produces the output files
  in a target directory

 .PARAMETER OutputDirectory
    Full path of the directory where the output files will be generated.

.EXAMPLE
   .\Export-AADAssessConditionalAccessData -OutputDirectory "c:\temp\contoso"

#>
function Export-AADAssessConditionalAccessData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]
        $OutputDirectory
    )

    Start-AppInsightsRequest $MyInvocation.MyCommand.Name
    try {

        [int] $Id = 0
        if (!(Get-Variable stackProgressId -ErrorAction SilentlyContinue)) { New-Variable -Name stackProgressId -Scope Script -Value (New-Object System.Collections.Generic.Stack[int]) }
        while ($stackProgressId.Contains($Id)) { $Id += 1 }

        [hashtable] $paramWriteProgress = @{
            Id = $Id
        }
        if ($stackProgressId.Count -gt 0) { $paramWriteProgress['ParentId'] = $stackProgressId.Peek() }
        $stackProgressId.Push($Id)

        Write-Progress -Activity "Reading Azure AD Conditional Access Policies" -CurrentOperation "Reading policies and named locations" @paramWriteProgress
        [array]$policies = Get-MsGraphResults "identity/conditionalAccess/policies"
        [array]$namedLocations = Get-MsGraphResults "identity/conditionalAccess/namedLocations"

        Write-Progress -Activity "Reading Azure AD Conditional Access Policies" -CurrentOperation "Consolidating object references" @paramWriteProgress
        $userIds = [array](Get-ObjectPropertyValue $policies 'conditions' 'users' 'includeUsers') + (Get-ObjectPropertyValue $policies 'conditions' 'users' 'excludeUsers') | Sort-Object | Get-Unique | Where-Object { $_ -notin 'All', 'GuestsOrExternalUsers' }
        $groupIds = [array](Get-ObjectPropertyValue $policies 'conditions' 'users' 'includeGroups') + (Get-ObjectPropertyValue $policies 'conditions' 'users' 'excludeGroups') | Sort-Object | Get-Unique
        $appIds = [array](Get-ObjectPropertyValue $policies 'conditions' 'applications' 'includeApplications') + (Get-ObjectPropertyValue $policies 'conditions' 'applications' 'excludeApplications') | Sort-Object | Get-Unique | Where-Object { $_ -notin 'All', 'None', 'Office365' }

        Write-Progress -Activity "Reading Azure AD Conditional Access Policies" -CurrentOperation "Querying referenced objects" @paramWriteProgress
        $referencedUsers = Get-MsGraphResults 'users?$select=id,userPrincipalName,displayName' -UniqueId $userIds
        $referencedGroups = Get-MsGraphResults 'groups?$select=id,displayName' -UniqueId $groupIds
        $referencedApps = Get-MsGraphResults 'servicePrincipals?$select=id,appId,displayName' -Filter "appId eq '{0}'" -UniqueId $appIds

        Write-Progress -Activity "Reading Azure AD Conditional Access Policies" -CurrentOperation "Saving Reports" @paramWriteProgress
        ConvertTo-Json $policies -Depth 10 | Out-File "$OutputDirectory\CAPolicies.json" -Force
        ConvertTo-Json $namedLocations -Depth 10 | Out-File "$OutputDirectory\NamedLocations.json" -Force

        $referencedUsers | Sort-Object id | ConvertTo-Json -Depth 10 | Out-File "$OutputDirectory\CARefUsers.json" -Force
        $referencedGroups | Sort-Object id | ConvertTo-Json -Depth 10 | Out-File "$OutputDirectory\CARefGroups.json" -Force
        $referencedApps | Sort-Object appId | ConvertTo-Json -Depth 10 | Out-File "$OutputDirectory\CARefApps.json" -Force

        [void] $script:stackProgressId.Pop()

    }
    catch { if ($MyInvocation.CommandOrigin -eq 'Runspace') { Write-AppInsightsException $_.Exception }; throw }
    finally { Complete-AppInsightsRequest $MyInvocation.MyCommand.Name -Success $? }
}
