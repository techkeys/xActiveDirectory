# Localized messages
data LocalisedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        RoleNotFoundError              = Please ensure that the PowerShell module for role '{0}' is installed
        RetrievingSite             = Retrieving Site '{0}'.
        UpdatingSite               = Updating Site '{0}'
        DeletingSite               = Deleting Site '{0}'
        CreatingSite               = Creating Site '{0}'
        SiteInDesiredState         = Site '{0}' exists and is in the desired state
        SiteNotInDesiredState      = Site '{0}' exists but is not in the desired state
        SiteExistsButShouldNot     = Site '{0}' exists when it should not exist
        SiteDoesNotExistButShould  = Site '{0}' does not exist when it should exist
        SitesIncludedRemoveError       = You cannot remove all sites from the Site '{0}'
        MultipleSitesError         = IP and SMTP Sites both found with the name '{0}'. Rename one of the sites or include the InterSiteTransportProtocol parameter
        ChangeNotificationValueError   = Invalid setting of '{0}' provided for ChangeNotification. Valid values are 0, 1 and 5
        ReplicationScheduleValueError  = Invalid setting of provided for ReplicationSchedule
        UnsupportedOperatingSystem     = Unsupported operating system. xADSite resource requires Microsoft Windows Server 2012 or later
'@
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter()]
        [System.String]
        $Description,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $ReplicationSchedule
    )
    
    $operatingSystem = (Get-CimInstance -Class win32_operatingsystem).Caption

    # The cmdlets used by this resource are not part of the ActiveDirectory module on 2008 R2

    if ($operatingSystem -like "*Windows Server 2008*"){
        throw ($LocalisedData.UnsupportedOperatingSystem)
    }
    
    Assert-Module -ModuleName 'ActiveDirectory'
    Import-Module -Name 'ActiveDirectory' -Verbose:$false

    Write-Verbose ($LocalisedData.RetrievingSite -f $SiteName)
    $getADReplicationSiteParams = @{
        Filter = "Name -eq '$SiteName'"
        Credential = $EnterpriseAdministratorCredential
    }

    if ($PSBoundParameters.ContainsKey('DomainController'))
    {
        $getADReplicationSiteParams['Server'] = $DomainController
    }

    
    $properties = @('Description')
    
    if ($PSBoundParameters.ContainsKey('ReplicationSchedule'))
    {
        $properties += 'ReplicationSchedule'
    }

    $getADReplicationSiteParams['Properties'] = $properties
    $Site = Get-ADReplicationSite @getADReplicationSiteParams
    

    if ($null -eq $Site)
    {
        $targetResourceStatus = 'Absent'
    }

    elseif ($Site.IsArray)
    {
        <# 
            If $Site is an array then more than one matching site link has been found, which would only happen if someone named
            an IP site link the same as an SMTP site link
        #>
        throw ($LocalisedData.MultipleSitesError -f $SiteName)
    }

    else
    {
        $targetResourceStatus = 'Present'
    }

    $targetResource = @{
        SiteName = $SiteName
        Ensure = $targetResourceStatus
        #SitesIncluded = $sitesIncludedFriendlyName
        Description = $Site.Description
        EnterpriseAdministratorCredential = $EnterpriseAdministratorCredential
        DomainController = $DomainController
    }

    if ($PSBoundParameters.ContainsKey('ReplicationSchedule'))
    {
        if ($null -eq $Site.ReplicationSchedule)
        {
            <# 
                If no ReplicationSchedule is found, then the site link is using the default 24x7 schedule.
                Create an AD Schedule object that represents this to enable comparison with desired state
            #>
            $defaultSchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
            $defaultSchedule.SetDailySchedule('Zero','Zero','TwentyThree','FortyFive')
            $defaultRawSchedule = $defaultSchedule.RawSchedule
            $targetResource['ReplicationSchedule'] = ConvertFrom-3dBoolArray $defaultRawSchedule
        }

        else
        {
            $SiteRawSchedule = $Site.ReplicationSchedule.RawSchedule
            $targetResource['ReplicationSchedule'] = ConvertFrom-3dBoolArray $SiteRawSchedule
        }
    }

    return $targetResource
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Description,


        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $ReplicationSchedule
    )

    $operatingSystem = (Get-CimInstance -Class win32_operatingsystem).Caption

    # The cmdlets used by this resource are not part of the ActiveDirectory module on 2008 R2

    if ($operatingSystem -like "*Windows Server 2008*"){
        throw ($LocalisedData.UnsupportedOperatingSystem)
    }

    $isCompliant = $true

    $targetResourceParams = @{
        SiteName = $SiteName
        EnterpriseAdministratorCredential = $EnterpriseAdministratorCredential
    }

    if ($PSBoundParameters.ContainsKey('DomainController'))
    {
        $targetResourceParams['DomainController'] = $DomainController
    }

    if ($PSBoundParameters.ContainsKey('ReplicationSchedule'))
    {
        $daysOfWeek = @('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
        $hoursOfDay = @('Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen','Twenty','TwentyOne','TwentyTwo','TwentyThree')
        [System.DayOfWeek] $day = 'Monday'
        [System.DirectoryServices.ActiveDirectory.HourOfDay] $fromHour = 'Zero'
        [System.DirectoryServices.ActiveDirectory.MinuteOfHour] $fromMinute = 'Zero'
        [System.DirectoryServices.ActiveDirectory.HourOfDay] $toHour = 'TwentyThree'
        [System.DirectoryServices.ActiveDirectory.MinuteOfHour] $toMinute = 'FortyFive'

        $activeDirectorySchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
        
        if ($ReplicationSchedule[0] -eq '24x7')
        {
            $activeDirectorySchedule.SetDailySchedule($fromHour,$fromMinute,$toHour,$toMinute)
            
        }

        elseif ($ReplicationSchedule[0] -in $daysOfWeek)
        {
            $scheduleLength = $ReplicationSchedule.Length
            $scheduleCounter = 0

            Do
            {
                $day = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $activeDirectorySchedule.SetSchedule($day,$fromHour,$fromMinute,$toHour,$toMinute)
            } Until ($scheduleCounter -eq $scheduleLength)
        }

        elseif ($ReplicationSchedule[0] -in $hoursOfDay)
        {
            $scheduleLength = $ReplicationSchedule.Length
            $scheduleCounter = 0

            Do
            {
                $fromHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $activeDirectorySchedule.SetDailySchedule($fromHour,$fromMinute,$toHour,$toMinute)
            } Until ($scheduleCounter -eq $scheduleLength)
        }

        else
        {
            throw ($LocalisedData.ReplicationScheduleValueError -f $ChangeNotification)
        }

        # The value of this parameter when passed to Get-TargetResource just needs to be a string
        $targetResourceParams['ReplicationSchedule'] = @('Required')
    }

    $targetResource = Get-TargetResource @targetResourceParams

    if ($targetResource.Ensure -eq 'Present')
    {
        # Site link exists
        if ($Ensure -eq 'Present')
        {
            # Site link exists and should
            foreach ($parameter in $PSBoundParameters.Keys)
            {
                if ($parameter -eq 'ReplicationSchedule')
                {
                    
                    $scheduleComparison = Compare-Object -ReferenceObject ($activeDirectorySchedule.RawSchedule) -DifferenceObject ($targetResource.ReplicationSchedule)
                    if($null -ne $scheduleComparison)
                    {
                        Write-Verbose ($LocalisedData.SiteNotInDesiredState -f $targetResource.SiteName)
                        $isCompliant = $false
                    }
                }
                
                elseif ($targetResource.ContainsKey($parameter))
                {
                    # This check is required to be able to explicitly remove values with an empty string, if required
                    if (([System.String]::IsNullOrEmpty($PSBoundParameters.$parameter)) -and ([System.String]::IsNullOrEmpty($targetResource.$parameter)))
                    {
                        # Both values are null/empty and therefore compliant
                        Write-Verbose ($LocalisedData.SiteInDesiredState -f $parameter, $PSBoundParameters.$parameter, $targetResource.$parameter)
                    }

                    elseif ($PSBoundParameters.$parameter -ne $targetResource.$parameter)
                    {
                        Write-Verbose ($LocalisedData.SiteNotInDesiredState -f $targetResource.SiteName)
                        $isCompliant = $false
                    }
                }
            }

            if ($isCompliant -eq $true)
            {
                # All values on targetResource match the desired state
                Write-Verbose ($LocalisedData.SiteInDesiredState -f $targetResource.SiteName)
            }
        }

        else
        {
            # Site link exists but should not
            $isCompliant = $false
            Write-Verbose ($LocalisedData.SiteExistsButShouldNot -f $targetResource.SiteName)
        }
    }

    else
    {
        # Site link does not exist
        if ($Ensure -eq 'Present')
        {
            $isCompliant = $false
            Write-Verbose ($LocalisedData.SiteDoesNotExistButShould -f $targetResource.SiteName)
        }

        else
        {
            Write-Verbose ($LocalisedData.SiteInDesiredState -f $targetResource.SiteName)
        }
    }

    return $isCompliant
}

function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $SiteName,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter()]
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure = 'Present',

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $Description,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $DomainController,

        [parameter()]
        [ValidateNotNullOrEmpty()]
        [System.String[]]
        $ReplicationSchedule
    )

    $operatingSystem = (Get-CimInstance -Class win32_operatingsystem).Caption

    # The cmdlets used by this resource are not part of the ActiveDirectory module on 2008 R2

    if ($operatingSystem -like "*Windows Server 2008*"){
        throw ($LocalisedData.UnsupportedOperatingSystem)
    }
    
    Assert-Module -ModuleName 'ActiveDirectory'
    Import-Module -Name 'ActiveDirectory' -Verbose:$false

    $targetResourceParams = @{
        SiteName = $SiteName
        EnterpriseAdministratorCredential = $EnterpriseAdministratorCredential
    }

    if ($PSBoundParameters.ContainsKey('DomainController'))
    {
        $targetResourceParams['DomainController'] = $DomainController
    }

    if ($PSBoundParameters.ContainsKey('ReplicationSchedule'))
    {
        $daysOfWeek = @('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')
        $hoursOfDay = @('Zero','One','Two','Three','Four','Five','Six','Seven','Eight','Nine','Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen','Twenty','TwentyOne','TwentyTwo','TwentyThree')
        [System.DayOfWeek] $day = 'Monday'
        [System.DirectoryServices.ActiveDirectory.HourOfDay] $fromHour = 'Zero'
        [System.DirectoryServices.ActiveDirectory.MinuteOfHour] $fromMinute = 'Zero'
        [System.DirectoryServices.ActiveDirectory.HourOfDay] $toHour = 'TwentyThree'
        [System.DirectoryServices.ActiveDirectory.MinuteOfHour] $toMinute = 'FortyFive'
        $activeDirectorySchedule = New-Object -TypeName System.DirectoryServices.ActiveDirectory.ActiveDirectorySchedule
        
        if ($ReplicationSchedule[0] -eq '24x7')
        {
            $activeDirectorySchedule.SetDailySchedule($fromHour,$fromMinute,$toHour,$toMinute)
        }

        elseif ($ReplicationSchedule[0] -in $daysOfWeek)
        {
            $scheduleLength = $ReplicationSchedule.Length
            $scheduleCounter = 0

            Do
            {
                $day = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $activeDirectorySchedule.SetSchedule($day,$fromHour,$fromMinute,$toHour,$toMinute)
            } Until ($scheduleCounter -eq $scheduleLength)
        }

        elseif ($ReplicationSchedule[0] -in $hoursOfDay)
        {
            $scheduleLength = $ReplicationSchedule.Length
            $scheduleCounter = 0

            Do
            {
                $fromHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $fromMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toHour = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $toMinute = $ReplicationSchedule[$scheduleCounter]
                $scheduleCounter++
                $activeDirectorySchedule.SetDailySchedule($fromHour,$fromMinute,$toHour,$toMinute)
            } Until ($scheduleCounter -eq $scheduleLength)
        }

        else
        {
            throw ($LocalisedData.ReplicationScheduleValueError -f $ChangeNotification)
        }

        # The value of this parameter when passed to Get-TargetResource just needs to be a string
        $targetResourceParams['ReplicationSchedule'] = 'Required'
    }

    $targetResource = Get-TargetResource @targetResourceParams

    if ($targetResource.Ensure -eq 'Present')
    {
        # Site link exists
        if ($Ensure -eq 'Present')
        {
            <#
                Site link exists and should, but some properties do not match.
                Find the relevant properties and update the site link accordingly
            #>
            $setADReplicationSiteParams = @{
                Identity = $SiteName
                Credential = $EnterpriseAdministratorCredential
            }

            if ($PSBoundParameters.ContainsKey('DomainController'))
            {
                $setADReplicationSiteParams['Server'] = $DomainController
            }

            foreach ($parameter in $PSBoundParameters.Keys)
            {
               if ($parameter -eq 'ReplicationSchedule')
                {
                    
                    $scheduleComparison = Compare-Object -ReferenceObject ($activeDirectorySchedule.RawSchedule) -DifferenceObject ($targetResource.ReplicationSchedule)
                    if($null -ne $scheduleComparison)
                    {
                        $setADReplicationSiteParams['ReplicationSchedule'] = $activeDirectorySchedule
                    }
                }
                
                elseif ($targetResource.ContainsKey($parameter))
                {
                    # This check is required to be able to explicitly remove values with an empty string, if required
                    if (($parameter -ne 'EnterpriseAdministratorCredential') -and ($parameter -ne 'SiteName') -and ($parameter -ne 'DomainController'))
                    {
                        if ($PSBoundParameters.$parameter -ne $targetResource.$parameter)
                        {
                            $setADReplicationSiteParams["$parameter"] = $PSBoundParameters.$parameter
                        }
                    }
                }
            }

            # When all the params are set, run Set-ADReplicationSite

            Write-Verbose ($LocalisedData.UpdatingSite -f $targetResource.SiteName)
            Set-ADReplicationSite @setADReplicationSiteParams
        }

        else
        {
            # Site link should not exist but does. Delete the site link
            $removeADReplicationSiteParams = @{
                Identity = $SiteName
                Credential = $EnterpriseAdministratorCredential
            }

            if ($PSBoundParameters.ContainsKey('DomainController'))
            {
                $targetResourceParams['Server'] = $DomainController
            }

            Write-Verbose ($LocalisedData.DeletingSite -f $targetResource.SiteName)
            Remove-ADReplicationSite @removeADReplicationSiteParams
        }
    }

    else
    {
        # Site does not exist
        if ($Ensure -eq 'Present')
        {
            # Site link should exist but does not. Create site link
            $newADReplicationSiteParams = @{
                Name = $SiteName
                Credential = $EnterpriseAdministratorCredential
            }

            foreach ($parameter in $PSBoundParameters.Keys)
            {
                if ($parameter -eq 'DomainController')
                {
                    $newADReplicationSiteParams['Server'] = $DomainController
                }

                elseif ($parameter -eq 'ReplicationSchedule')
                {
                    $newADReplicationSiteParams['ReplicationSchedule'] = $activeDirectorySchedule
                }

                elseif (($parameter -ne 'SiteName') -and ($parameter -ne 'EnterpriseAdministratorCredential') -and ($parameter -ne 'Ensure'))
                {
                    $newADReplicationSiteParams[$parameter] = $PSBoundParameters.$parameter
                }
            }

            Write-Verbose ($LocalisedData.CreatingSite -f $SiteName)
            New-ADReplicationSite @newADReplicationSiteParams
        }
    }
}

function ConvertFrom-3dBoolArray{
    param(
        [System.Boolean[,,]]
        $threeDimensionalArray
    )

    $dimensionOne = New-Object bool[][][] 7
    for($i=0; $i -lt 7; $i++)
    {
        $dimensionTwo = New-Object bool[][] 24
        for($j=0; $j -lt 24; $j++)
        {
            $dimensionThree = New-Object bool[] 4
            for($k=0; $k -lt 4; $k++)
            {
                if($threeDimensionalArray[$i, $j, $k] -eq $true)
                {
                    $dimensionThree[$k] = $true
                }
            }
            $dimensionTwo[$j] = $dimensionThree
        }
        $dimensionOne[$i] = $dimensionTwo
    }

    return $dimensionOne
}


# Import the common AD functions
$adCommonFunctions = Join-Path -Path (Split-Path -Path $PSScriptRoot -Parent) -ChildPath '\MSFT_xADCommon\MSFT_xADCommon.ps1'
. $adCommonFunctions


