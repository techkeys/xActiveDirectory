# Localized messages
data LocalizedData
{
    # culture="en-US"
    ConvertFrom-StringData @'
        RetrievingUPNSuffix                = Retrieving UPN Suffix '{0}'.
        AddingUPNSuffix                    = Adding UPN Suffix '{0}'
        RemovingUPNSuffix                  = Removing UPN Suffix '{0}'

        UPNSuffixNotFound                  = UPN Suffix '{0}' was not found
        NotDesiredPropertyState            = UPN Suffix '{0}' is not correct. Expected '{1}', actual '{2}'
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
        $UPNSuffix,

        [parameter()]
        [System.String]
        $Forest,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter()]
        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure
    )

    if([System.String]::IsNullOrEmpty($Forest))
    {
        $Forest = (Get-ADForest -Current LocalComputer).RootDomain
    }

    Write-Verbose -Message ($LocalizedData.RetrievingUPNSuffix -f $UPNSuffix);

    if($UPNSuffix -in (Get-ADForest -Identity $Forest).UPNSuffixes)
    {
        $targetResourceState = 'Present'
    }
    else 
    {
        Write-Verbose -Message ($LocalizedData.UPNSuffixNotFound -f $UPNSuffix);
        $targetResourceState = 'Absent'
    }
    
    $returnValue = @{
        UPNSuffix = $UPNSuffix
        Forest = $Forest
        EnterpriseAdministratorCredential = $EnterpriseAdministratorCredential
        Ensure = $targetResourceState
    }

    $returnValue
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UPNSuffix,

        [parameter()]
        [System.String]
        $Forest,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter(Mandatory = $true)]
        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure
    )

    $targetResource = Get-TargetResource @PSBoundParameters

    if($targetResource.Ensure -eq 'Absent' -and $Ensure -eq 'Present')
    {
        Write-Verbose -Message ($LocalizedData.AddingUPNSuffix -f $UPNSuffix);
        Set-ADForest -Identity $targetResource.Forest -UPNSuffixes @{add=$UPNSuffix}
    }
    elseif($targetResource.Ensure -eq 'Present' -and $Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.RemovingUPNSuffix -f $UPNSuffix);
        Set-ADForest -Identity $targetResource.Forest -UPNSuffixes @{remove=$UPNSuffix}
    }
}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $UPNSuffix,

        [parameter()]
        [System.String]
        $Forest,

        [parameter(Mandatory = $true)]
        [System.Management.Automation.PSCredential]
        $EnterpriseAdministratorCredential,

        [parameter(Mandatory = $true)]
        [ValidateSet("Absent","Present")]
        [System.String]
        $Ensure
    )

    $targetResource = Get-TargetResource @PSBoundParameters

    if(($targetResource.Ensure -eq 'Present' -and $Ensure -eq 'Present') `
        -or `
        ($targetResource.Ensure -eq 'Absent' -and $Ensure -eq 'Absent'))
    {
        $result = $true
    }
    else
    {
        $result = $false
        Write-Verbose -Message ($LocalizedData.NotDesiredPropertyState -f $UPNSuffix, $Ensure, $targetResource.Ensure);
    }
    
    $result
}

Export-ModuleMember -Function *-TargetResource

