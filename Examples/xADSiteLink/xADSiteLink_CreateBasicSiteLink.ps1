<#
    .EXAMPLE
    This example will create a site link containing the requested list of sites. The cost and replication frequency will also be set.
    The requested sites must already exist. As other optional settings are not specified for the resource, the site link will be created 
    with some default settings. Specifically:

    - Inter Site Transport Protocol will be IP
    - Replication Schedule will be 24 x 7
    
    Note that while SitesIncluded, Cost and ReplicationFrequencyInMinutes are optional as they are not required to create a site 
    link using this DSC Resource; failing to specify them will essentially result in a non-functioning site link.

    The account credentials must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain.
#>

configuration xADSiteLink_CreateBasicSiteLink
{
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $DomainCreds,

        [Parameter(Mandatory)]
        [System.String]
        $SiteLinkName,

        [parameter()]
        [System.UInt32]
        $Cost,

        [parameter()]
        [System.UInt32]
        $ReplicationFrequencyInMinutes,

        [parameter()]
        [System.String[]]
        $SitesIncluded
    )
     
    
    Import-DscResource -Name MSFT_xADSiteLink -ModuleName xActiveDirectory
 
    
    Node $nodeName
    {
        xADSiteLink CreateSiteLink
        {
            Ensure = 'Present'
            DomainAdministratorCredential = $DomainCreds
            SiteLinkName = $SiteLinkName
            SitesIncluded = $SitesIncluded
            Cost = $Cost
            ReplicationFrequencyInMinutes = $ReplicationFrequency
        }
    }
}

<#
    Sample use:

    $credential = Get-Credential
    xADSiteLink_DeleteSiteLink -DomainAdministratorCredential $credential -SiteLinkName 'MyNewSiteLink' -SitesIncluded @('HubSite1','HubSite2') `
    -Cost 100 -ReplicationFrequencyInMinutes 15
#>