#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Downloads the Microsoft Teams bootstrapper and provisions new Teams
    (including the Outlook meeting add-in) for all users on the machine.

.DESCRIPTION
    1. Downloads teamsbootstrapper.exe from Microsoft (with retries)
    2. Verifies the file is validly signed by Microsoft
    3. Optionally removes the existing provisioned version (-x)
    4. Provisions the latest Teams (-p), plus the Teams Meeting Add-in (--installTMA)
    5. Cleans up the installer and writes a transcript log

    Ref: https://learn.microsoft.com/en-us/microsoftteams/new-teams-vdi-requirements-deploy#new-teams-and-outlook-integration

.NOTES
    Written to run unmodified under Nerdio Manager / Azure Custom Script Extension.
    There is deliberately NO param() block: Nerdio prepends its own variable assignments
    to the script, and param() must be the first statement or PowerShell throws parse errors.
    Edit the CONFIG section below instead.
#>

#region CONFIG - edit these values
$DownloadUrl      = 'https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409'
$WorkingDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { $env:TEMP }
$LogPath          = Join-Path $env:TEMP 'Install-NewTeams.log'
$MaxRetries       = 3
$RemoveExisting   = $false   # $true = run "teamsbootstrapper.exe -x" before provisioning
$SkipTMA          = $false   # $true = do not pass --installTMA (skips Outlook meeting add-in)
$KeepInstaller    = $false   # $true = leave teamsbootstrapper.exe on disk after the run
#endregion CONFIG

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'   # Invoke-WebRequest is dramatically faster in PS 5.1 without the progress bar

# PS 5.1 defaults to older TLS versions; Microsoft endpoints require TLS 1.2+
[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

$InstallerPath = Join-Path $WorkingDirectory 'teamsbootstrapper.exe'
$ReturnCode = 0

#region Helpers
function Write-Log {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'OK', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $color = switch ($Level) {
        'INFO'  { 'Cyan' }
        'OK'    { 'Green' }
        'WARN'  { 'Yellow' }
        'ERROR' { 'Red' }
    }
    $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    Write-Host "[$stamp] [$Level] $Message" -ForegroundColor $color
}

function Get-Bootstrapper {
    param([string]$Uri, [string]$Destination, [int]$Retries)

    for ($attempt = 1; $attempt -le $Retries; $attempt++) {
        try {
            Write-Log "Downloading bootstrapper (attempt $attempt of $Retries)..."
            Invoke-WebRequest -Uri $Uri -OutFile $Destination -UseBasicParsing -TimeoutSec 120

            if (-not (Test-Path -LiteralPath $Destination) -or (Get-Item -LiteralPath $Destination).Length -eq 0) {
                throw 'Download completed but the file is missing or empty.'
            }

            $sizeMB = [math]::Round((Get-Item -LiteralPath $Destination).Length / 1MB, 2)
            Write-Log "Download complete ($sizeMB MB): $Destination" 'OK'
            return
        }
        catch {
            Write-Log "Download failed: $($_.Exception.Message)" 'WARN'
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Force -ErrorAction SilentlyContinue
            }
            if ($attempt -eq $Retries) { throw "Unable to download bootstrapper after $Retries attempts." }

            $delay = 5 * $attempt
            Write-Log "Retrying in $delay seconds..." 'WARN'
            Start-Sleep -Seconds $delay
        }
    }
}

function Test-MicrosoftSignature {
    param([string]$Path)

    $sig = Get-AuthenticodeSignature -FilePath $Path
    if ($sig.Status -ne 'Valid') {
        throw "Signature check failed. Status: $($sig.Status). The file may be corrupt or tampered with."
    }
    if ($sig.SignerCertificate.Subject -notmatch 'O=Microsoft Corporation') {
        throw "Unexpected signer: $($sig.SignerCertificate.Subject)"
    }
    Write-Log "Signature valid. Signer: $($sig.SignerCertificate.Subject)" 'OK'
}

function Invoke-Bootstrapper {
    param(
        [string]$Path,
        [string[]]$Arguments,
        [string]$Description
    )

    Write-Log "$Description  >  teamsbootstrapper.exe $($Arguments -join ' ')"
    $proc = Start-Process -FilePath $Path -ArgumentList $Arguments -NoNewWindow -Wait -PassThru

    if ($proc.ExitCode -ne 0) {
        throw "$Description failed with return code $($proc.ExitCode)."
    }
    Write-Log "$Description completed (return code 0)." 'OK'
}

function Set-WvdRegistryKey {
    $keyPath = 'HKLM:\SOFTWARE\Microsoft\Teams'
    Write-Log 'Configuring Teams registry key for WVD...'
    try {
        New-Item -Path $keyPath -Force | Out-Null
        New-ItemProperty -Path $keyPath -Name 'IsWVDEnvironment' -PropertyType DWord -Value 1 -Force | Out-Null
        Write-Log 'Registry key set: HKLM\SOFTWARE\Microsoft\Teams\IsWVDEnvironment = 1' 'OK'
    }
    catch {
        # Non-fatal: continue with the install, but make the failure visible
        Write-Log "Failed to set Teams registry key. Error: $($_.Exception.Message)" 'WARN'
    }
}
#endregion Helpers

try {
    Start-Transcript -Path $LogPath -Append | Out-Null
    Write-Log "Starting new Teams provisioning on $env:COMPUTERNAME"
    Write-Log "Log file: $LogPath"

    if (-not (Test-Path -LiteralPath $WorkingDirectory)) {
        New-Item -ItemType Directory -Path $WorkingDirectory -Force | Out-Null
    }

    # 1. Download + verify
    Get-Bootstrapper -Uri $DownloadUrl -Destination $InstallerPath -Retries $MaxRetries
    Test-MicrosoftSignature -Path $InstallerPath

    # 2. Set WVD environment flag (before provisioning so Teams picks it up)
    Set-WvdRegistryKey

    # 3. Optional removal of previous version
    if ($RemoveExisting) {
        Invoke-Bootstrapper -Path $InstallerPath -Arguments @('-x') -Description 'Removing existing Teams'
    }

    # 4. Install latest (July 2025+: Outlook meeting add-in is installed via --installTMA)
    $installArgs = @('-p')
    if (-not $SkipTMA) { $installArgs += '--installTMA' }
    Invoke-Bootstrapper -Path $InstallerPath -Arguments $installArgs -Description 'Provisioning new Teams'

    Write-Log 'All steps completed successfully.' 'OK'
}
catch {
    $ReturnCode = 1
    Write-Log "FAILED: $($_.Exception.Message)" 'ERROR'
    Write-Log "At: $($_.InvocationInfo.ScriptName):$($_.InvocationInfo.ScriptLineNumber)" 'ERROR'
}
finally {
    if (-not $KeepInstaller -and (Test-Path -LiteralPath $InstallerPath)) {
        Remove-Item -LiteralPath $InstallerPath -Force -ErrorAction SilentlyContinue
        Write-Log 'Removed downloaded installer.'
    }
    try { Stop-Transcript | Out-Null } catch { }
}

# Return code: 0 = success, 1 = failure (see log above / transcript).
# Printed explicitly so it is visible in Nerdio's "Script output", then returned to the caller.
$resultText = if ($ReturnCode -eq 0) { 'success' } else { 'failure - review the log above' }
Write-Log "RETURN CODE: $ReturnCode ($resultText)" $(if ($ReturnCode -eq 0) { 'OK' } else { 'ERROR' })
return $ReturnCode
