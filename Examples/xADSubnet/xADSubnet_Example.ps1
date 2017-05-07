configuration xADSite_Example {
    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Subnet,
        [parameter()]
        [String]
        $Site,
        [parameter()]
        [String]
        $Location,
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Import-DscResource -Name xADSubnet

    xADSubnet NewSubnet
    {
        Subnet = $Subnet
        Site = $Site
        Location = $Location
        Ensure = 'Present'
        EnterpriseAdministratorCredential = $Credential
    }
}

$xADSubnetParams = @{
    Subnet = "192.168.100.0/24"
    SiteName = "Washington"
    Location = "Washington - Building A - Workstations"
    Credential = (Get-Credential -UserName "CORP\Administartor" -Message "Please enter Enterprise Administrator Credentials") 
}

xADSubnet_Example @xADSubnetParams