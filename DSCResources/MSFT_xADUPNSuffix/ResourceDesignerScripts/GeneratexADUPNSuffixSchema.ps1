New-xDscResource -Name MSFT_xADUPNSuffix -FriendlyName xADUPNSuffix -ModuleName xActiveDirectory -Path . -Force -Property @(
    New-xDscResourceProperty -Name UPNSuffix -Type String -Attribute Key
    New-xDscResourceProperty -Name EnterpriseAdministratorCredential -Type PSCredential -Attribute Required
    #New-xDscResourceProperty -Name RecycleBinEnabled -Type Boolean -Attribute Read
)
