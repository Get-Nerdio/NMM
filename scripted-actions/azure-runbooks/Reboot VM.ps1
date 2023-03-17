#description: Reboot an Azure VM
#tags: Nerdio

<# Notes:

This Scripted Action will reboot the VM it is run against. It can be used to reboot a server, 
AVD host, Desktop Image, etc.

#>


Restart-AzVM -resourceGroupName $AzureResourceGroupName -Name $AzureVMName