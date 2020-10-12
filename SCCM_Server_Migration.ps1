# Map a new PSDrive

New-PSDrive -Name "Z" -Root "\\venable.com\data\Departments\IT\Department Data\Service Operations\Scripts" -Persist -PSProvider FileSystem
<#

####################################################################################################################################################
Add Servers to SCCM Server Group. Update should happen every 5 minutes. Wait until devices are discoverable before proceeding to the final steps
####################################################################################################################################################
#>

$Prodservers = import-csv z:\SCCM_Migration\ProdGroup4_MANUAL.csv | Select-Object name -ExpandProperty name

    foreach ($Computername in $Prodservers) {
    
    Add-ADGroupMember -Identity "SCCM - Windows Servers" -Members (Get-ADComputer $ComputerName)
    
    }

<#
###################################################################################################################################################
Add Appropriate Servers to Group A
###################################################################################################################################################
#>

$GroupAServers = import-csv z:\SCCM_Migration\GroupA_Lab_Servers.csv | Select-Object name -ExpandProperty name

    foreach ($Computername in $GroupAServers) {
    
    Add-ADGroupMember -Identity "Software Updates - Group A" -Members (Get-ADComputer $ComputerName)
    
    }


<#
###################################################################################################################################################
Add Appropriate Servers to Manual Group
###################################################################################################################################################
#>

$ManualServers = import-csv z:\SCCM_Migration\ProdGroup4_MANUAL.csv | Select-Object name -ExpandProperty name

    foreach ($Computername in $ManualServers) {
    
    Add-ADGroupMember -Identity "Software Updates - Manual" -Members (Get-ADComputer $ComputerName)
    
    }



<#
###################################################################################################################################################
Check that devices are discoverable in SCCM 
###################################################################################################################################################
#>

$Prodservers = import-csv z:\SCCM_Migration\Group3_Exchange.csv | Select-Object name -ExpandProperty name
$SiteCode = "Enter Site Code"
$SiteServer = "Enter Site Server"

$CurrentLocation = Get-Location

# Import ConfigurationManager module
$ConfigurationManager = "C:\Program Files (x86)\Microsoft Configuration Manager\bin\ConfigurationManager.psd1"
Import-Module $ConfigurationManager

If (-Not (Test-Path -Path "$($SiteCode):\")) {
	New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}

    foreach ($Computername in $Prodservers) {
    
    Set-Location -Path "$($SiteCode):"
    Get-CMDevice -Name $ComputerName | select name
    
    }

<#
#####################################################################################################################################################
Complete Final Steps once machines are discoverable to install SCCM Client
#####################################################################################################################################################

#>


$Prodservers = import-csv z:\SCCM_Migration\ProdGroup3_MANUAL.csv | Select-Object name -ExpandProperty name
$SiteCode = "Enter Site Code"
$SiteServer = "Enter Site Server"

$CurrentLocation = Get-Location

# Import ConfigurationManager module
$ConfigurationManager = "C:\Program Files (x86)\Microsoft Configuration Manager\bin\ConfigurationManager.psd1"
Import-Module $ConfigurationManager

If (-Not (Test-Path -Path "$($SiteCode):\")) {
	New-PSDrive -Name $SiteCode -PSProvider "AdminUI.PS.Provider\CMSite" -Root $SiteServer
}

foreach ($ComputerName in $Prodservers) {


Set-Location -Path "$($SiteCode):"
While (-Not (Get-CMDevice -Name $ComputerName)) { Start-Sleep -seconds 5 }

Invoke-Command -Computer $ComputerName -Command { klist -lh 0 -li 0x3e7 purge }
Invoke-GPUpdate -Computer $ComputerName -Target Computer
Invoke-Command -Computer $ComputerName -Command { certutil -pulse }

Set-Location -Path "$($SiteCode):"
Install-CMClient -DeviceName $ComputerName -SiteCode $SiteCode

}
