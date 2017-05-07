configuration xADSite_Example {
    param(
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $SiteName,
        [parameter()]
        [String[]]
        $ReplicationSchedule,
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Import-DscResource -Name xADSite

    xADSite NewSite 
    {
        SiteName = $SiteName
        Ensure = 'Present'
        EnterpriseAdministratorCredential = $Credential
        ReplicationSchedule = $ReplicationSchedule
    }

}

$xADSiteParams = @{
    SiteName = "Washington"
    Credential = (Get-Credential -UserName "CORP\Administrator" -Message "Please enter Enterprise Administrator Credentials") 
    ReplicationSchedule = @('Zero','Zero','Eight','Thirty','Eighteen','Zero','TwentyThree','FortyFive')
}

xADSite_Example @xADSiteParams