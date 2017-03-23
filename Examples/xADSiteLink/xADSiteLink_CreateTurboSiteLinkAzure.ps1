<#
    .EXAMPLE
    This example is similar to the xADSiteLink_CreateTurboSiteLink example, but it creates a DSC node configuration in Azure for the node named
    MYSERVER. 

    This assumes you have created an Azure Automation Account named 'DscProdAutoAcct' in the 'DscAutomationProdRg' resource group and
    already configured the VM to onboard with Azure Automation DSC and look for this DSC node configuration. You should add the DSC configuration
    (i.e. this file) to the Azure Automation Account before running the compilation job detailed in the sample usage.  
    
    It also assumes that the automation account has a credential named 'CorpDomainCreds' in its credential store. The actual user account 
    corresponding to the credential store must have the necessary permissions. Without additional delegation; this would mean an account with 
    Enterprise Admins, or Domain Admins in the forest root domain. Azure Automation DSC will retrieve the username and password from the 
    credential store when compiling the node configuration.
#>

configuration xADSiteLink_CreateTurboSiteLinkAzure
{
    param
    (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        $DomainCreds
    )
     
    
    Import-DscResource -Name MSFT_xADSiteLink -ModuleName xActiveDirectory
 
    
    Node $AllNodes.where{$PSItem.Role -eq “AdditionalDomainController”}.NodeName
    {
        xADSiteLink CreateTurboSiteLinkAzure
        {
            Ensure = 'Present'
            DomainAdministratorCredential = $DomainCreds
            SiteLinkName = $node.SiteLinkName
            SitesIncluded = $node.SiteLinkSitesIncluded
            Description = $node.SiteLinkDescription
            Cost = $node.SiteLinkCost
            ReplicationFrequencyInMinutes = $node.SiteLinkReplicationFrequency
            ChangeNotification = $node.SiteLinkChangeNotification
            ReplicationSchedule = $node.SiteLinkReplicationSchedule
        }
    }
}

<#
    Sample use:

    $configData = @{
        AllNodes = 
        @(
            @{
                NodeName = "*"
                PSDscAllowPlainTextPassword = $True
            }
    
            @{
                NodeName = "MYSERVER"
                Role = “AdditionalDomainController”
                SiteLinkName = 'HubSite1-HubSite2'
                SiteLinkDescription = 'Site link between HubSite1 and HubSite2. (DSC)'
                SiteLinkCost = 100
                SiteLinkReplicationFrequency = 15
                SiteLinkSitesIncluded = @('HubSite1','HubSite2')
                SiteLinkChangeNotification = 5
                SiteLinkReplicationSchedule = @('24x7')
            }
        )
    } 

    $parameters = @{
        "DomainCreds" = "CorpDomainCreds"
    }

    $resourceGroup = "DscAutomationProdRg"
    $accountName = "DscProdAutoAcct"
    $configurationName = "xADSiteLink_CreateTurboSiteLinkAzure"

    Login-AzureRmAccount
    Start-AzureRmAutomationDscCompilationJob -ResourceGroupName $resourceGroup -AutomationAccountName $accountName -ConfigurationName $configurationName -ConfigurationData $configData -Parameters $parameters
#>