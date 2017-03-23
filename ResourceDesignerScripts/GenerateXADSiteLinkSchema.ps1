# Define DSC resource properties 
 
$Ensure = New-xDscResourceProperty -Name Ensure -Type String -Attribute Write -ValidateSet "Present", "Absent" -Description 'Specifies whether the site link should be present or absent'
 
$Description = New-xDscResourceProperty -Name Description -Type String -Attribute Write -Description 'Specifies a description of the site link'

$DomainController = New-xDscResourceProperty -Name DomainController -Type String -Attribute Write -Description 'Specifies the Active Directory Domain Services instance to connect to perform the task'

$DomainAdministratorCredential = New-xDscResourceProperty -Name DomainAdministratorCredential -Type PSCredential -Attribute Required -Description 'Specifies the user account credentials to use to perform the task'

$SiteLinkName = New-xDscResourceProperty -Name SiteLinkName -Type String -Attribute Key -Description 'Specifies the name of the site link to manage'

$Cost = New-xDscResourceProperty -Name Cost -Type Uint32 -Attribute Write -Description 'Specifies the cost to be placed on the site link'

$InterSiteTransportProtocol = New-xDscResourceProperty -Name InterSiteTransportProtocol -Type String -Attribute Write -ValidateSet "IP", "SMTP" -Description 'Specifies a valid intersite transport protocol option'

$ReplicationFrequencyInMinutes = New-xDscResourceProperty -Name ReplicationFrequencyInMinutes -Type Uint32 -Attribute Write -Description 'Species the frequency, in minutes, for which replication will occur where this site link is in use between sites'

$SitesIncluded = New-xDscResourceProperty -Name SitesIncluded -Type String[] -Attribute Write -Description 'Specifies the list of sites included in the site link'

$ChangeNotification = New-xDscResourceProperty -Name ChangeNotification -Type Uint32 -Attribute Write -Description 'Specifies if change notificaton is enabled on the site link or not'

$ReplicationSchedule = New-xDscResourceProperty -Name ReplicationSchedule -Type String[] -Attribute Write -Description 'Specifies the default replication schedule for any connections within this site link'

# Create the DSC resource

New-xDscResource -Name MSFT_xADSiteLink -Property $SiteLinkName,$Cost,$Ensure,$Description,$InterSiteTransportProtocol,$ReplicationFrequencyInMinutes,`
$SitesIncluded,$DomainController,$DomainAdministratorCredential,$ChangeNotification,$ReplicationSchedule `
-ClassVersion 1.0 -FriendlyName xADSiteLink –Force


