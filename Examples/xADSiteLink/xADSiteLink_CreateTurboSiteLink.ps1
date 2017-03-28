<#
    .EXAMPLE
    This example will create a new site link based on best practices for organisations with modern network topology and available bandwidth
    who want to reduce AD replication latency. You can read more about some of these settings at:
    https://blogs.technet.microsoft.com/ashleymcglone/2011/06/29/report-and-edit-ad-site-links-from-powershell-turbo-your-ad-replication/

    As sites have a 24x7 replication schedule by default, it is not strictly necessary to include the ReplicationSchedule item. However,
    this is DSC and it will ensure that the site link's schedule does not drift from the 24x7 schedule due to unauthorised manual changes.

    ChangeNotification is set to 5, which will enable change notification between the sites in the link and also disable compression. This
    will reduce CPU overhead on the bridgehead servers at the expense of network bandwidth. You can also enable change notification by setting this
    to 1, which will leave compression enabled. Setting ChangeNotification to 0 would disable change notification.

    As a best practice, a site link should contain only two sites. 

    The account credentials must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain.
#>

configuration xADSiteLink_CreateTurboSiteLink
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
        [System.String]
        $Description,

        [parameter()]
        [System.UInt32]
        $Cost,

        [parameter()]
        [System.UInt32]
        $ReplicationFrequencyInMinutes,

        [parameter()]
        [System.String[]]
        $SitesIncluded,

        [parameter()]
        [System.UInt32]
        $ChangeNotification,

        [parameter()]
        [System.String[]]
        $ReplicationSchedule
    )
     
    
    Import-DscResource -Name MSFT_xADSiteLink -ModuleName xActiveDirectory
 
    
    Node $nodeName
    {
        xADSiteLink CreateTurboSiteLink
        {
            Ensure = 'Present'
            DomainAdministratorCredential = $DomainCreds
            SiteLinkName = $SiteLinkName
            SitesIncluded = $SitesIncluded
            Description = $Description
            Cost = $Cost
            ReplicationFrequencyInMinutes = $ReplicationFrequencyInMinutes
            ChangeNotification = $ChangeNotification
            ReplicationSchedule = $ReplicationSchedule
        }
    }
}

<#
    Sample use:

    $credential = Get-Credential
    xADSiteLink_CreateTurboSiteLink -DomainAdministratorCredential $credential -SiteLinkName 'MyNewSiteLink' -SitesIncluded @('HubSite1','HubSite2') `
    -Description 'Site link between HubSite1 and HubSite2 (DSC)' -Cost 100 -ReplicationFrequencyInMinutes 15 -ChangeNotification 5 -ReplicationSchedule @('24x7')
#>