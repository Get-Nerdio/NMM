#description: Uninstall the BlackPoint agent.
#execution mode: Individual
#tags: Nerdio, BlackPoint
<#
Notes:
This script uninstall BlackPoint agent

Requirements
- PowerShell 5.1 or later
- Administrator privileges
- Windows operating system
#>

Install-Module -Name Remove-SnapAgent

# Import the module
Import-Module Remove-SnapAgent

# Run the cleanup
Remove-SnapAgent
