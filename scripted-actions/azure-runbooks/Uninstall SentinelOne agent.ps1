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

# Get status of vm
$vm = Get-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName -Status

# if vm is stopped, start it
if ($vm.statuses[1].displaystatus -eq "VM deallocated") {
    Write-Output "Starting VM $AzureVMName"
    Start-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName
}

Remove-AzVMExtension -ResourceGroupName $AzureResourceGroupName -Name "SentinelOne.WindowsExtension" -VMName $AzureVMName -Force

# if VM was stopped, stop it again
if ($vm.statuses[1].displaystatus -eq "VM deallocated") {
    Write-Output "Stopping VM $AzureVMName"
    Stop-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName -Force
}