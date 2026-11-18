#description: Uninstall the BlackPoint agent.
#execution mode: Individual
#tags: Nerdio, BlackPoint
<#
Notes:
This script uninstalls the Blackpoint agent. A system reboot is recommended after execution to complete removal of services or files that may be locked.

Requirements
- PowerShell 5.1 or later
- Administrator privileges
- Windows operating system
#>

Write-Output "Installing NuGet package provider"
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction Stop | Out-Null
    Write-Output "NuGet package provider installed successfully"
} catch {
    Write-Output -Error "Failed to install NuGet: $_"
    throw
}

Write-Output "Ensure Remove-SnapAgent is installed"
$module = Get-Module -ListAvailable -Name Remove-SnapAgent
if (-not $module) {
    Write-Output "Installing Remove-SnapAgent module..."
    Install-Module -Name Remove-SnapAgent -Force
    Write-Output "Remove-SnapAgent module installed successfully"
} else {
    Write-Output "Remove-SnapAgent module is already installed"
}

# Import the module
Import-Module Remove-SnapAgent

try {
    Write-Output "Run the cleanup..."
    Remove-SnapAgent
} catch {
    Write-Output "ERROR: Failed to complete the cleanup: $_"
}

Write-Output "Uninstalling Remove-SnapAgent module..."
Uninstall-Module Remove-SnapAgent
