<#
    .EXAMPLE
    This example will create a new site link with a replication schedule that allows replication at different times each day.

    The ReplicationSchedule for the xADSiteLink resource can handle 3 different types of schedule:

    - where replication is needed 24x7. For this scenario, specify a single string in an array as '24x7'
    - where replication is needed at specific times throughout the day, but every day has the same schedule. This is covered in the 
      xADSiteLink_CreateDailyScheduleSiteLink example
      
      
    - where replication is needed at specific times throughout the day, but each day needs a different schedule. For this scenario
      ReplicationSchedule needs to be an array of strings in the format:

      @('<day of week>','<from hour>','<from minute>','<to hour>','<to minute>')

      'Day of week' needs to be specified as a value between 'Monday' to 'Sunday'. 'From' and 'to' hours need to be specified as a value 
      between 'Zero' and 'TwentyThree'. 'From' and 'to' minutes need to be specified as one of 'Zero', 'Fifteen', 'Thirty' or 'FortyFive'.

      Please be aware that the 'to' values need to be for the block prior to when you want it to stop. If you wanted to allow replication 
      on a Monday between 22h00 and 23h59 it would be:

      @('Monday','TwentyTwo','Zero','TwentyThree','FortyFive')

      Where you need to enable multiple blocks of replication throughout the day, or replication on different days, you can specify 
      additional sets of from & to hours & minutes. This is shown in the sample usage section below

    The account credentials must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain.
#>

configuration xADSiteLink_CreateComplexScheduleSiteLink
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
            EnterpriseAdministratorCredential = $DomainCreds
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
    xADSiteLink_CreateComplexScheduleSiteLink -DomainAdministratorCredential $credential -SiteLinkName 'MyNewSiteLink' -SitesIncluded @('HubSite1','HubSite2') `
    -Description 'Site link between HubSite1 and HubSite2 (DSC)' -Cost 100 -ReplicationFrequencyInMinutes 15 `
    -ReplicationSchedule @('Monday','Zero','Zero','Three','FortyFive','Monday','Five','Zero','Five','FortyFive','Monday','Seven','Zero','Seven','FortyFive','Monday','Nine','Zero','Fifteen','FortyFive','Monday','Seventeen','Zero','TwentyThree','FortyFive',
    'Tuesday','Zero','Zero','Three','FortyFive','Tuesday','Seven','Zero','Nine','FortyFive','Tuesday','Thirteen','Zero','Thirteen','FortyFive','Tuesday','Seventeen','Zero','Seventeen','FortyFive','Tuesday','Nineteen','Zero','Nineteen','FortyFive','Tuesday','TwentyOne','Zero','TwentyThree','FortyFive',
    'Wednesday','Zero','Zero','Three','FortyFive','Wednesday','Five','Zero','Five','FortyFive','Wednesday','Seven','Zero','Seven','FortyFive','Wednesday','Nine','Zero','Nine','FortyFive','Wednesday','Eleven','Zero','Eleven','FortyFive','Wednesday','Thirteen','Zero','Thirteen','FortyFive','Wednesday','Fifteen','Zero','Fifteen','FortyFive','Wednesday','Seventeen','Zero','Seventeen','FortyFive','Wednesday','Nineteen','Zero','Nineteen','FortyFive','Wednesday','TwentyOne','Zero','TwentyThree','FortyFive',
    'Thursday','Zero','Zero','Three','FortyFive','Thursday','Five','Zero','Five','FortyFive','Thursday','Seven','Zero','Seven','FortyFive','Thursday','Nine','Zero','Nine','FortyFive','Thursday','Eleven','Zero','Eleven','FortyFive','Thursday','Thirteen','Zero','Thirteen','FortyFive','Thursday','Seventeen','Zero','Seventeen','FortyFive','Thursday','TwentyOne','Zero','TwentyThree','FortyFive',
    'Friday','Zero','Zero','Nineteen','FortyFive','Friday','TwentyOne','Zero','TwentyThree','FortyFive',
    'Saturday','Zero','Zero','Seventeen','FortyFive','Saturday','TwentyOne','Zero','TwentyThree','FortyFive',
    'Sunday','Zero','Zero','Three','FortyFive','Sunday','Five','Zero','Five','FortyFive','Sunday','Seven','Zero','Fifteen','FortyFive','Sunday','Seventeen','Zero','TwentyThree','FortyFive')
#>