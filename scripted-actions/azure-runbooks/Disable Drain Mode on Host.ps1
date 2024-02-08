#description: Activates a host, meaning users will be able to connect to it
#tags: Nerdio

<#

Notes:
This script must be run against an AVD host. Running it from the Scripted Actions screen will not work, as
there will be no AzureVMName variable available. Running this script on a Host Pool will activate all hosts in
the pool.

#>

$SessionHost = Get-AzWvdSessionHost -ResourceGroupName $AzureResourceGroupName -HostPoolName $HostPoolName | Where-Object Name -Match "$HostPoolName\/$AzureVMName\."
$SessionHostName = ($SessionHost.name -split '\/')[1]
Update-AzWvdSessionHost -ResourceGroupName $AzureResourceGroupName -HostPoolName $HostPoolName -Name $SessionHostName -AllowNewSession:$True