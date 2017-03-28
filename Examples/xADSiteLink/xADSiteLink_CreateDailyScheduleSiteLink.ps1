<#
    .EXAMPLE
    This example will create a new site link with a daily replication schedule that only allows replication outside of the hours of
    08h30 to 18h00.

    The ReplicationSchedule for the xADSiteLink resource can handle 3 different types of schedule:

    - where replication is needed 24x7. For this scenario, specify a single string in an array as '24x7'
    - where replication is needed at specific times throughout the day, but every day has the same schedule. For this scenario
      ReplicationSchedule needs to be an array of strings in the format:

      @('<from hour>','<from minute>','<to hour>','<to minute>')

      'From' and 'to' hours need to be specified as a value between 'Zero' and 'TwentyThree'. 'From' and 'to' minutes need to be specified 
      as one of 'Zero', 'Fifteen', 'Thirty' or 'FortyFive'.

      Where you need to enable multiple blocks of replication throughout the day, you can specify additional sets of from & to hours & minutes.
      This is shown in the sample usage section below
    - where replication is needed at specific times throughout the day, but each day needs a different schedule. This is covered in the 
      xADSiteLink_CreateComplexScheduleSiteLink example

    The account credentials must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain.
#>

configuration xADSiteLink_CreateDailyScheduleSiteLink
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
            ReplicationSchedule = $ReplicationSchedule
        }
    }
}

<#
    Sample use:

    $credential = Get-Credential
    xADSiteLink_CreateDailyScheduleSiteLink -DomainAdministratorCredential $credential -SiteLinkName 'MyNewSiteLink' -SitesIncluded @('HubSite1','HubSite2') `
    -Description 'Site link between HubSite1 and HubSite2 (DSC)' -Cost 100 -ReplicationFrequencyInMinutes 15 `
    -ReplicationSchedule @('Zero','Zero','Eight','Thirty','Eighteen','Zero','TwentyThree','FortyFive')
#>