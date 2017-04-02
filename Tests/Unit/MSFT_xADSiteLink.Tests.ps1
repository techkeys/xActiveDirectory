$script:DSCModuleName      = 'xActiveDirectory'
$script:DSCResourceName = 'MSFT_xADSiteLink'

# region HEADER

# Unit Test Template Version: 1.2.0
$script:moduleRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
if ( (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests'))) -or `
     (-not (Test-Path -Path (Join-Path -Path $script:moduleRoot -ChildPath 'DSCResource.Tests\TestHelper.psm1'))) )
{
    & git @('clone','https://github.com/PowerShell/DscResource.Tests.git',(Join-Path -Path $script:moduleRoot -ChildPath '\DSCResource.Tests\'))
}

Import-Module -Name (Join-Path -Path $script:moduleRoot -ChildPath (Join-Path -Path 'DSCResource.Tests' -ChildPath 'TestHelper.psm1')) -Force

$TestEnvironment = Initialize-TestEnvironment `
    -DSCModuleName $script:DSCModuleName `
    -DSCResourceName $script:DSCResourceName `
    -TestType Unit

# endregion HEADER

# Begin Testing
try
{
    # region Pester Tests


    InModuleScope $script:DSCResourceName {

        $test2008R2Params = @{
            Caption = 'Microsoft Windows Server 2008 R2'
        }

        $test2016Params = @{
            Caption = 'Microsoft Windows Server 2016'
        }
        
        $credential = New-Object System.Management.Automation.PSCredential 'DummyUser', (ConvertTo-SecureString 'DummyPassword' -AsPlainText -Force)

        $fakeADSiteLink = @{
            Cost = 100
            DistinguishedName = 'CN=TestSiteLink,CN=IP,CN=Inter-Site Transports,CN=Sites,CN=Configuration,DC=phit,DC=solutions'
            Name = 'TestSiteLink'
            ReplicationFrequencyInMinutes = 15
            SitesIncluded = @('CN=FakeSite1,CN=Sites,CN=Configuration,DC=contoso,DC=com','CN=FakeSite2,CN=Sites,CN=Configuration,DC=contoso,DC=com')
            Description = 'Fake description'
            InterSiteTransportProtocol = 'IP'
        }

        # region Function Get-TargetResource
        Describe 'MSFT_xADSiteLink\Get-TargetResource' {
            $testPresentParams = @{
                SiteLinkName = 'TestSiteLink'
                DomainAdministratorCredential = $credential
                Ensure = 'Present'
            }

            $testAbsentParams = $testPresentParams.Clone()
            $testAbsentParams['Ensure'] = 'Absent'
            
            Context 'Testing with supported and unsupported OS' {
                
                Mock Assert-Module -MockWith { }
                Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }

                $errorMessage = $($LocalisedData.UnsupportedOperatingSystem)
                
                It "Throws an unsupported OS error if OS is Windows Server 2008 R2" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2008R2Params }

                    { $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential } | Should Throw $errorMessage
                }

                It "Does not throw an unsupported OS error if OS is Windows Server 2016" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2016Params }
                    
                    { $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential } | Should Not Throw $errorMessage
                }
            }
            
            Context 'Testing without optional parameters' {
                Mock Get-CimInstance { return [PSCustomObject] $test2016Params }
                Mock Assert-Module -MockWith { }

                It "Returns a 'System.Collections.Hashtable' object type" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource -is [System.Collections.Hashtable] | Should Be $true
                }

                It "Returns 'Ensure' is 'Present' when site link exists" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.Ensure | Should Be 'Present'
                }

                It "Returns 'Ensure' is 'Absent' when site link does not exist" {
                    Mock Get-ADReplicationSiteLink { return $null }
                    $targetResource = Get-TargetResource -SiteLinkName 'NonExistantSiteLink' -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.Ensure | Should Be 'Absent'
                }

                It "Returns correct site names from 'SitesIncluded'" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.SitesIncluded[0] | Should Be 'FakeSite1'
                    $targetResource.SitesIncluded[1] | Should Be 'FakeSite2'
                }

                It "Returns correct value for 'Description'" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.Description | Should Be 'Fake description'
                }

                It "Returns correct value for 'Cost'" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.Cost | Should Be 100
                }

                It "Returns correct value for 'ReplicationFrequencyInMinutes'" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentParams.SiteLinkName -DomainAdministratorCredential $testPresentParams.DomainAdministratorCredential
                    $targetResource.ReplicationFrequencyInMinutes | Should Be 15
                }
            }

            Context 'Testing with optional parameters' {
                Mock Get-CimInstance { return [PSCustomObject] $test2016Params }
                Mock Assert-Module -MockWith { }

                It "Returns correct value for 'DomainController' when valid domain or domain controller specified" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['DomainController'] = 'FakeDC.contoso.com'
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -DomainController $testPresentOptionalParams.DomainController
                    $targetResource.DomainController | Should Be 'FakeDC.contoso.com'
                }

                It "Returns 'Ensure' is 'Present' when site link exists for the specified InterSiteTransportProtocol" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['InterSiteTransportProtocol'] = 'IP'
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -InterSiteTransportProtocol $testPresentOptionalParams.InterSiteTransportProtocol
                    $targetResource.InterSiteTransportProtocol | Should Be 'IP'
                    $targetResource.Ensure | Should Be 'Present'
                }

                It "Returns 'Ensure' is 'Absent' when site link does not exist for the specified InterSiteTransportProtocol" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['InterSiteTransportProtocol'] = 'SMTP'
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -InterSiteTransportProtocol $testPresentOptionalParams.InterSiteTransportProtocol
                    $targetResource.Ensure | Should Be 'Absent'
                }

                It "Returns 'ChangeNotification' is 0 when change notification has not been enabled on a site link" {
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['ChangeNotification'] = 5
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -ChangeNotification $testPresentOptionalParams.ChangeNotification
                    $targetResource.ChangeNotification | Should Be 0
                }

                It "Returns correct value for 'ChangeNotification' when change notification has been enabled on a site link" {
                    $fakeChangeNotificationADSiteLink = $fakeADSiteLink.Clone()
                    $fakeChangeNotificationADSiteLink['Options'] = 1
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeChangeNotificationADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['ChangeNotification'] = 5
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -ChangeNotification $testPresentOptionalParams.ChangeNotification
                    $targetResource.ChangeNotification | Should Be 1
                }

                It "Returns a 24x7 schedule when site link is using default 24x7 schedule" {
                    $24x7Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $24x7Schedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
                    $24x7RawSchedule = $24x7Schedule.RawSchedule
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLink }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['ReplicationSchedule'] = 'Required'
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -ReplicationSchedule $testPresentOptionalParams.ReplicationSchedule
                    $compareSchedules = Compare-Object $24x7RawSchedule $targetResource.ReplicationSchedule
                    $compareSchedules | Should BeNullOrEmpty
                }

                It "Returns correct value for 'ReplicationSchedule' when site link is using a non-default schedule" {
                    $9to5DailySchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $9to5DailySchedule.SetDailySchedule('Nine','Zero','Sixteen','FortyFive')
                    $9to5DailyRawSchedule = $9to5DailySchedule.RawSchedule
                    $fakeADSiteLinkWithSchedule = $fakeADSiteLink.Clone()
                    $fakeADSiteLinkWithSchedule['ReplicationSchedule'] = $9to5DailySchedule
                    Mock Get-ADReplicationSiteLink { return [PSCustomObject] $fakeADSiteLinkWithSchedule }
                    $testPresentOptionalParams = $testPresentParams.Clone()
                    $testPresentOptionalParams['ReplicationSchedule'] = 'Required'
                    $targetResource = Get-TargetResource -SiteLinkName $testPresentOptionalParams.SiteLinkName -DomainAdministratorCredential $testPresentOptionalParams.DomainAdministratorCredential -ReplicationSchedule $testPresentOptionalParams.ReplicationSchedule
                    $compareSchedules = Compare-Object $9to5DailyRawSchedule $targetResource.ReplicationSchedule
                    $compareSchedules | Should BeNullOrEmpty
                }
            }
        }
        # endregion

        # region Function Test-TargetResource
        Describe 'MSFT_xADSiteLink\Test-TargetResource' {
            
            $testTargetResourceParams = @{
                SiteLinkName = 'TestSiteLink'
                DomainAdministratorCredential = $credential
            }

            $fakeTargetResource = @{
                SiteLinkName = 'TestSiteLink'
                Ensure = 'Present'
                SitesIncluded = @('FakeSite1','FakeSite2')
                Description = 'Fake description'
                DomainAdministratorCredential = $credential
                DomainController = 'FakeDC.contoso.com'
                Cost = 100
                ReplicationFrequencyInMinutes = 15
            }

            $nonExistantTargetResource = @{
                SiteLinkName = 'TestSiteLink'
                Ensure = 'Absent'
                SitesIncluded = @()
                Description = ''
                DomainAdministratorCredential = $credential
                DomainController = 'FakeDC.contoso.com'
                Cost = $null
                ReplicationFrequencyInMinutes = $null
            }
            
            Context 'Testing with supported and unsupported OS' {
                Mock Get-TargetResource { return [PSCustomObject] $fakeTargetResource }

                $errorMessage = $($LocalisedData.UnsupportedOperatingSystem)
                
                It "Throws an unsupported OS error if OS is Windows Server 2008 R2" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2008R2Params }

                    { $targetResource = Test-TargetResource @testTargetResourceParams } | Should Throw $errorMessage
                }

                It "Does not throw an unsupported OS error if OS is Windows Server 2016" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2016Params }
                    
                    { $targetResource = Test-TargetResource @testTargetResourceParams } | Should Not Throw $errorMessage
                }
            }

            Context 'Testing without optional parameters' {
                It "Returns a 'System.Boolean' object type" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $isCompliant = Test-TargetResource @testTargetResourceParams
                    $isCompliant | Should BeOfType System.Boolean
                }
                
                It "Returns 'isCompliant' is 'True' when site link exists, should exist and is in desired state" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $isCompliant = Test-TargetResource @testTargetResourceParams
                    $isCompliant | Should Be $true
                }
                
                It "Returns 'isCompliant' is 'True' when site link does not exist and should not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    $testAbsentTargetResourceParams = $testTargetResourceParams.Clone()
                    $testAbsentTargetResourceParams['Ensure'] = 'Absent'
                    $isCompliant = Test-TargetResource @testAbsentTargetResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and should not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testAbsentTargetResourceParams = $testTargetResourceParams.Clone()
                    $testAbsentTargetResourceParams['Ensure'] = 'Absent'
                    $isCompliant = Test-TargetResource @testAbsentTargetResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'False' when site link does not exist and should exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    $isCompliant = Test-TargetResource @testTargetResourceParams
                    $isCompliant | Should Be $false
                }
            }

            Context 'Testing with optional parameters' {
                It "Returns 'isCompliant' is 'True' when site link using matching transport protocol exists" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['InterSiteTransportProtocol'] = 'IP'
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['InterSiteTransportProtocol'] = 'IP'
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link using matching transport protocol does not exist" {
                    $nonExistantTargetResourceWithOptions = $nonExistantTargetResource.Clone()
                    $nonExistantTargetResourceWithOptions['InterSiteTransportProtocol'] = 'IP'
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['InterSiteTransportProtocol'] = 'IP'
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'Description' matches desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['Description'] = 'Fake description'
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'Description' does not match desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['Description'] = 'Different desired fake description'
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'Cost' matches desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['Cost'] = 100
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'Cost' does not match desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['Cost'] = 50
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'SitesIncluded' matches desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['SitesIncluded'] = @('FakeSite1','FakeSite2')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'SitesIncluded' does not match desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['SitesIncluded'] = @('WrongSite1','FakeSite2')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'ReplicationFrequencyInMinutes' matches desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationFrequencyInMinutes'] = 15
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'ReplicationFrequencyInMinutes' does not match desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationFrequencyInMinutes'] = 30
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'DomainController' matches desired value" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['DomainController'] = 'FakeDC.contoso.com'
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'ChangeNotification' matches desired value" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ChangeNotification'] = 5
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ChangeNotification'] = 5
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'ChangeNotification' does not match desired value" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ChangeNotification'] = 0
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ChangeNotification'] = 5
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'ReplicationSchedule' matches when 24x7 is desired" {
                    $24x7Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $24x7Schedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
                    $24x7RawSchedule = $24x7Schedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$24x7RawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('24x7')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'ReplicationSchedule' does not match when 24x7 is desired" {
                    $9to5DailySchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $9to5DailySchedule.SetDailySchedule('Nine','Zero','Sixteen','FortyFive')
                    $9to5DailyRawSchedule = $9to5DailySchedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$9to5DailyRawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('24x7')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'ReplicationSchedule' matches when 9am to 5pm daily is desired" {
                    $9to5DailySchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $9to5DailySchedule.SetDailySchedule('Nine','Zero','Sixteen','FortyFive')
                    $9to5DailyRawSchedule = $9to5DailySchedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$9to5DailyRawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('Nine','Zero','Sixteen','FortyFive')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'ReplicationSchedule' does not match when 9am to 5pm daily is desired" {
                    $24x7Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $24x7Schedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
                    $24x7RawSchedule = $24x7Schedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$24x7RawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('Nine','Zero','Sixteen','FortyFive')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }

                It "Returns 'isCompliant' is 'True' when site link exists and value for 'ReplicationSchedule' matches when 9am to 5pm Saturday & Sunday is desired" {
                    $9to5SatSunSchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $9to5SatSunSchedule.SetSchedule('Saturday','Nine','Zero','Sixteen','FortyFive')
                    $9to5SatSunSchedule.SetSchedule('Sunday','Nine','Zero','Sixteen','FortyFive')
                    $9to5SatSunRawSchedule = $9to5SatSunSchedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$9to5SatSunRawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('Saturday','Nine','Zero','Sixteen','FortyFive','Sunday','Nine','Zero','Sixteen','FortyFive')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $true
                }

                It "Returns 'isCompliant' is 'False' when site link exists and value for 'ReplicationSchedule' does not match when 9am to 5pm Saturday & Sunday is desired" {
                    $24x7Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $24x7Schedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
                    $24x7RawSchedule = $24x7Schedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions.Add('ReplicationSchedule',$24x7RawSchedule)
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    $testOptionalResourceParams = $testTargetResourceParams.Clone()
                    $testOptionalResourceParams['ReplicationSchedule'] = @('Saturday','Nine','Zero','Sixteen','FortyFive','Sunday','Nine','Zero','Sixteen','FortyFive')
                    $isCompliant = Test-TargetResource @testOptionalResourceParams
                    $isCompliant | Should Be $false
                }
            }
        }
        # endregion

        # region Function Set-TargetResource
        Describe 'MSFT_xADSiteLink\Set-TargetResource' {
            
            $setTargetResourceParams = @{
                SiteLinkName = 'TestSiteLink'
                DomainAdministratorCredential = $credential
            }

            $fakeTargetResource = @{
                SiteLinkName = 'TestSiteLink'
                Ensure = 'Present'
                SitesIncluded = @('FakeSite1','FakeSite2')
                Description = 'Fake description'
                DomainAdministratorCredential = $credential
                DomainController = 'FakeDC.contoso.com'
                Cost = 100
                ReplicationFrequencyInMinutes = 15
            }

            $nonExistantTargetResource = @{
                SiteLinkName = 'TestSiteLink'
                Ensure = 'Absent'
                SitesIncluded = @()
                Description = ''
                DomainAdministratorCredential = $credential
                DomainController = 'FakeDC.contoso.com'
                Cost = $null
                ReplicationFrequencyInMinutes = $null
            }

            Context 'Testing with supported and unsupported OS' {
                
                Mock Assert-Module -MockWith { }
                Mock Get-TargetResource { return [PSCustomObject] $fakeTargetResource }

                $errorMessage = $($LocalisedData.UnsupportedOperatingSystem)
                
                It "Throws an unsupported OS error if OS is Windows Server 2008 R2" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2008R2Params }

                    { $targetResource = Set-TargetResource @setTargetResourceParams } | Should Throw $errorMessage
                }

                It "Does not throw an unsupported OS error if OS is Windows Server 2016" {
                    Mock Get-CimInstance { return [PSCustomObject] $test2016Params }
                    
                    { $targetResource = Set-TargetResource @setTargetResourceParams } | Should Not Throw $errorMessage
                }
            }

            Context 'Testing without optional parameters' {
                It "Calls 'Set-ADReplicationSiteLink' when 'Ensure' is 'Present' and the site link exists" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    Mock Set-ADReplicationSiteLink -MockWith { }
                    Set-TargetResource @setTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -Scope It
                }

                It "Calls 'New-ADeplicationSiteLink' when 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -MockWith { }
                    Set-TargetResource @setTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -Scope It
                }

                It "Calls 'Remove-ADeplicationSiteLink' when 'Ensure' is 'Absent' and the site link exists" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    Mock Remove-ADReplicationSiteLink -MockWith { }
                    $setAbsentTargetResourceParams = $setTargetResourceParams.Clone()
                    $setAbsentTargetResourceParams['Ensure'] = 'Absent'
                    Set-TargetResource @setAbsentTargetResourceParams
                    Assert-MockCalled Remove-ADReplicationSiteLink -Scope It
                }

                It "Does not call 'New-ADeplicationSiteLink', 'Set-ADeplicationSiteLink' or 'Remove-ADeplicationSiteLink' when 'Ensure' is 'Absent' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    $setAbsentTargetResourceParams = $setTargetResourceParams.Clone()
                    $setAbsentTargetResourceParams['Ensure'] = 'Absent'
                    Set-TargetResource @setAbsentTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -Scope It -Exactly 0
                    Assert-MockCalled Set-ADReplicationSiteLink -Scope It -Exactly 0
                    Assert-MockCalled Remove-ADReplicationSiteLink -Scope It -Exactly 0
                }
            }

            Context 'Testing with optional parameters' {
                It "Calls 'Set-ADReplicationSiteLink' with 'Description' when 'Description' is specified, 'Ensure' is 'Present' and the site link exists but 'Description' does not match" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $Description -eq 'Desired fake description' } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['Description'] = 'Desired fake description'
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $Description -eq 'Desired fake description' } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'Description' when 'Description' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $Description -eq 'Desired fake description' } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['Description'] = 'Desired fake description'
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $Description -eq 'Desired fake description' } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'Cost' when 'Cost' is specified, 'Ensure' is 'Present' and the site link exists but 'Cost' does not match" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['Cost'] = 50
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $Cost -eq 100 } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['Cost'] = 100
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $Cost -eq 100 } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'Cost' when 'Cost' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $Cost -eq 100 } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['Cost'] = 100
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $Cost -eq 100 } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'ReplicationFrequencyInMinutes' when 'ReplicationFrequencyInMinutes' is specified, 'Ensure' is 'Present' and the site link exists but 'ReplicationFrequencyInMinutes' does not match" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ReplicationFrequencyInMinutes'] = 30
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $ReplicationFrequencyInMinutes -eq 15} -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ReplicationFrequencyInMinutes'] = 15
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $ReplicationFrequencyInMinutes -eq 15 } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'ReplicationFrequencyInMinutes' when 'ReplicationFrequencyInMinutes' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $ReplicationFrequencyInMinutes -eq 15 } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ReplicationFrequencyInMinutes'] = 15
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $ReplicationFrequencyInMinutes -eq 15 } -Scope It
                }
                
                It "Calls 'Set-ADReplicationSiteLink' with 'Add' and 'Remove' when 'SitesIncluded' is specified, 'Ensure' is 'Present', the site link exists, a site needs to be added to 'SitesIncluded' and a site needs to be removed from 'SitesIncluded'" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['SitesIncluded'] = @('FakeSiteToKeep','FakeSiteToRemove')
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Add') -and $SitesIncluded.ContainsKey('Remove') } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['SitesIncluded'] = @('FakeSiteToKeep','FakeSiteToAdd')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Add') -and $SitesIncluded.ContainsKey('Remove') } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'Add' when 'SitesIncluded' is specified, 'Ensure' is 'Present', the site link exists and a site needs to be added to 'SitesIncluded'" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['SitesIncluded'] = @('FakeSiteToKeep','FakeSite2ToKeep')
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Add') } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['SitesIncluded'] = @('FakeSiteToKeep','FakeSite2ToKeep','FakeSiteToAdd')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Add') } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'Remove' when 'SitesIncluded' is specified, 'Ensure' is 'Present', the site link exists and a site needs to be removed to 'SitesIncluded'" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['SitesIncluded'] = @('FakeSiteToKeep','FakeSiteToRemove','FakeSite2ToKeep')
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Remove') } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['SitesIncluded'] = @('FakeSiteToKeep','FakeSite2ToKeep')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $SitesIncluded.ContainsKey('Remove') } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'SitesIncluded' when 'SitesIncluded' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $SitesIncluded } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['SitesIncluded'] = @('FakeSite1','FakeSite2')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $SitesIncluded } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'Server' when 'DomainController' is specified, 'Ensure' is 'Present' and the site link exists" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResource }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $Server -eq 'fakedc.contoso.com' } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['DomainController'] = 'fakedc.contoso.com'
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $Server -eq 'fakedc.contoso.com' } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'Server' when 'DomainController' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $Server -eq 'fakedc.contoso.com' } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['DomainController'] = 'fakedc.contoso.com'
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $Server -eq 'fakedc.contoso.com' } -Scope It
                }


                It "Calls 'Set-ADReplicationSiteLink' with 'Replace' when 'ChangeNotification' is '1' or '5', 'Ensure' is 'Present' and the site link exists but 'ChangeNotification' does not match" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ChangeNotification'] = 1
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $Replace } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ChangeNotification'] = 5
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $Replace } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'Clear' when 'ChangeNotification' is '0', 'Ensure' is 'Present' and the site link exists but 'ChangeNotification' does not match" {
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ChangeNotification'] = 1
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $Clear } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ChangeNotification'] = 0
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $Clear } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'OtherAttributes' when 'ChangeNotification' is '1' or '5', 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $OtherAttributes } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ChangeNotification'] = 5
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $OtherAttributes } -Scope It
                }

                It "Calls 'Set-ADReplicationSiteLink' with 'ReplicationSchedule' when 'ReplicationSchedule' is specified, 'Ensure' is 'Present' and the site link exists but 'ReplicationSchedule' does not match" {
                    $24x7Schedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
                    $24x7Schedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
                    $24x7RawSchedule = $24x7Schedule.RawSchedule
                    $fakeTargetResourceWithOptions = $fakeTargetResource.Clone()
                    $fakeTargetResourceWithOptions['ReplicationSchedule'] = $24x7RawSchedule
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $fakeTargetResourceWithOptions }
                    Mock Set-ADReplicationSiteLink -ParameterFilter { $ReplicationSchedule } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ReplicationSchedule'] = @('Nine','Zero','Sixteen','FortyFive')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled Set-ADReplicationSiteLink -ParameterFilter { $ReplicationSchedule } -Scope It
                }

                It "Calls 'New-ADReplicationSiteLink' with 'ReplicationSchedule' when 'ReplicationSchedule' is specified, 'Ensure' is 'Present' and the site link does not exist" {
                    Mock Get-TargetResource { return [System.Collections.Hashtable] $nonExistantTargetResource }
                    Mock New-ADReplicationSiteLink -ParameterFilter { $ReplicationSchedule } -MockWith { }
                    $setOptionalTargetResourceParams = $setTargetResourceParams.Clone()
                    $setOptionalTargetResourceParams['ReplicationSchedule'] = @('24x7')
                    Set-TargetResource @setOptionalTargetResourceParams
                    Assert-MockCalled New-ADReplicationSiteLink -ParameterFilter { $ReplicationSchedule } -Scope It
                }
            }
        }
        # endregion
    }
    # endregion
}

finally
{
    # region FOOTER
    Restore-TestEnvironment -TestEnvironment $TestEnvironment
    # endregion
}
