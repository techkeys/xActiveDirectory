<#
    .EXAMPLE
    This example will delete a site link.

    The account credentials must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain.
#>

configuration xADSiteLink_DeleteSiteLink
{
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $DomainCreds,

        [Parameter(Mandatory)]
        [System.String]
        $SiteLinkName
    )
     
    
    Import-DscResource -Name MSFT_xADSiteLink -ModuleName xActiveDirectory
 
    
    Node $nodeName
    {
        xADSiteLink DeleteSiteLink
        {
            Ensure = 'Absent'
            DomainAdministratorCredential = $DomainCreds
            SiteLinkName = $SiteLinkName
        }
    }
}

<#
    Sample use:

    $credential = Get-Credential
    xADSiteLink_DeleteSiteLink -DomainAdministratorCredential $credential -SiteLinkName 'MyOldSiteLink'
#>