#description: Uninstall the SentinelOne agent.
#execution mode: Individual
#tags: Nerdio, SentinelOne
<#
Notes:
This script uninstall SentinelOne agent.

Select the "Restart VM after script execution" checkbox before executing scripted action.
#>

##### Script Logic #####

$sub = get-azsubscription -SubscriptionId $AzureSubscriptionId

set-azcontext -subscription $sub 

Remove-AzVMExtension -ResourceGroupName $AzureResourceGroupName -Name "SentinelOne.WindowsExtension" -VMName $AzureVMName -Force