#description: Uninstall the NinjaRMM agent.
#execution mode: Individual
#tags: Nerdio, NinjaRMM
<#
Notes:
This script uninstall NinjaRMM agent
#>

##### Script Logic #####

$UninstallString = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*).UninstallString

if($UninstallString -eq $null) {
    $UninstallString = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*).UninstallString
}

if($UninstallString -eq $null) {
    Write-Output "ERROR: NinjaRMM agent not found"
}

else {
    Start-Process -FilePath "$UninstallString" -ArgumentList "--mode unattended"
}