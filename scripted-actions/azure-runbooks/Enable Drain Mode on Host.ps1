#description: Puts a host into drain mode, meaning no users will connect to it
#tags: Nerdio

<#

Notes:
This script must be run against an AVD host. Running it from the Scripted Actions screen will not work, as
there will be no AzureVMName variable available. Running this script on a Host Pool will put all hosts in
the pool into drain mode.

#>

$SessionHost = Get-AzWvdSessionHost -ResourceGroupName $AzureResourceGroupName -HostPoolName $HostPoolName | Where-Object Name -Match "$HostPoolName\/$AzureVMName\."
$SessionHostName = ($SessionHost.name -split '\/')[1]
Update-AzWvdSessionHost -ResourceGroupName $AzureResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$False