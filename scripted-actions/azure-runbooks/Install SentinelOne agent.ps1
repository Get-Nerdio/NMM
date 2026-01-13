#description: Install the SentinelOne agent.
#execution mode: Individual
#tags: Nerdio, SentinelOne, Preview

<#
Notes:
The installation script requires an Agent version, Site token and API token.

    Agent version: In the Management Console, click Sentinels > Packages. Copy the
version number of the Agent to deploy. This is the full version number (aka the "Build
number" e.g. 21.7.5.1080)

    Site token: In Sentinels > Packages, click Copy token.

    API token: Click Settings > Users > My User. Click Generate or Options > Regenerate
API Token.

You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    S1AgentVersion
    S1SiteToken
    S1APItoken
#>

##### Required Variables #####

$SiteToken = $SecureVars.S1SiteToken
$AgentVersion = $SecureVars.S1AgentVersion
$APItoken = $SecureVars.S1APItoken

##### Script Logic #####

$sub = get-azsubscription -SubscriptionId $AzureSubscriptionId

set-azcontext -subscription $sub 

$Settings = @{"WindowsAgentVersion" = $AgentVersion; "SiteToken" = $SiteToken}

$ProtectedSettings = @{"SentinelOneConsoleAPIKey" = $APItoken};

# Get status of vm
$vm = Get-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName -Status

# if vm is stopped, start it
if ($vm.statuses[1].displaystatus -eq "VM deallocated") {
    Write-Output "Starting VM $AzureVMName"
    Start-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName
}

# Install SentinelOne agent
Set-AzVMExtension -ResourceGroupName $AzureResourceGroupName -Location $AzureRegionName -VMName $AzureVMName -Name "SentinelOne.WindowsExtension" -Publisher "SentinelOne.WindowsExtension" -Type "WindowsExtension" -TypeHandlerVersion "1.0" -Settings $Settings -ProtectedSettings $ProtectedSettings

# if VM was stopped, stop it again
if ($vm.statuses[1].displaystatus -eq "VM deallocated") {
    Write-Output "Stopping VM $AzureVMName"
    Stop-AzVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVMName -Force
}
