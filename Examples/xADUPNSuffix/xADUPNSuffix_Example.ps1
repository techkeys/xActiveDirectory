configuration xADUPNSuffix_Example {
    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $UPNSuffix,
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Import-DscResource -Name xADUPNSuffix

    xADUPNSuffix NewUPNSuffix 
    {
        UPNSuffix = $UPNSuffix
        EnterpriseAdministratorCredential = $Credential
        Ensure = 'Present'
    }
}

$xADUPNSuffixParams = @{
    UPNSuffix = "dscrocks.com"
    Credential = (Get-Credential -UserName "CORP\Administartor" -Message "Please enter Enterprise Administrator Credentials") 
}

xADUPNSuffix_Example @xADUPNSuffixParams