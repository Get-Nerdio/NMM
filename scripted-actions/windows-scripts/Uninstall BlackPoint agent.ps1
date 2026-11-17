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

#region Helper Functions

function Write-Log
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Message,
        [Parameter(Mandatory=$false)]
        [string]$ErrorMessage
    )

    try
    {
        $tempFolder     = [Environment]::GetEnvironmentVariable('TEMP', 'Machine')
        $logsFolderName = "NMMLogs"
        $logsPath       = "$tempFolder\$logsFolderName"

        if (-not (Test-Path -Path $logsPath)) {
            New-Item -Path $tempFolder -Name $logsFolderName -ItemType Directory -Force | Out-Null
        }

        $DateTime    = Get-Date -Format "MM-dd-yy HH:mm:ss"
        $Invocation  = "$($MyInvocation.MyCommand.Source):$($MyInvocation.ScriptLineNumber)"

        if ($Message) {
            Add-Content -Value "$DateTime - $Invocation - $Message" -Path "$logsPath\UninstallBlackPointAgent.log"
            Write-Host $Message
        } else {
            Add-Content -Value "$DateTime - $Invocation - $ErrorMessage" -Path "$logsPath\UninstallBlackPointAgent.log"
            Write-Host $ErrorMessage
        }
    }
    catch
    {
        Write-Error $_.Exception.Message
    }
}

#endregion

Write-Log "Installing NuGet package provider"
try {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -ErrorAction Stop | Out-Null
    Write-Log "NuGet package provider installed successfully"
} catch {
    Write-Log -Error "Failed to install NuGet: $_"
    throw
}

Write-Log "Ensure Remove-SnapAgent is installed"
$module = Get-Module -ListAvailable -Name Remove-SnapAgent
if (-not $module) {
    Write-Log "Installing Remove-SnapAgent module..."
    Install-Module -Name Remove-SnapAgent -Force
    Write-Log "Remove-SnapAgent module installed successfully"
} else {
    Write-Log "Remove-SnapAgent module is already installed"
}

# Import the module
Import-Module Remove-SnapAgent

# Run the cleanup
Remove-SnapAgent
