<#
.SYNOPSIS
    Installs or updates the MS Teams client and enables Teams WVD Optimization mode.

.DESCRIPTION
    This script performs the following actions:
    1. Sets a registry value to enable MS Teams to operate in WVD Mode.
    2. Uninstalls existing MS Teams, Teams Outlook Add-in, and WebRTC programs, both per-user and machine-wide installations.
    3. Downloads and installs the latest version of MS Teams with a machine-wide installation and the Teams Meeting Add-in for Outlook.
    4. Downloads and installs the latest version of the WebRTC component.
    5. Disables automatic Teams updates
    5. Logs all actions to a specified log directory.
    6. Set the $MarchwebRTC variable to $true to install the March 2024 version of WebRTC.

.EXECUTION MODE NMM
    IndividualWithRestart

.TAGS
    Nerdio, Apps install, MS Teams, WVD Optimization

.NOTES
    - Logs are saved to: $env:TEMP\NerdioManagerLogs\Install-Teams.txt
    - Ensure that the script is run with appropriate privileges for registry modifications and software installation.

#>
# Define script variables
$DLink = "https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409"
$MarchwebRTC = $false
$ErrorActionPreference = 'Stop'

# Minimal binary validation: ensure file starts with EXE 'MZ' or MSI CFBF header
function Test-Binary([string]$Path) {
    if (-not (Test-Path $Path)) { return $false }
    $fs = [IO.File]::OpenRead($Path)
    try {
        $b0 = $fs.ReadByte(); $b1 = $fs.ReadByte()
    } finally {
        $fs.Close()
    }
    return ( ($b0 -eq 0xD0 -and $b1 -eq 0xCF) -or ($b0 -eq 0x4D -and $b1 -eq 0x5A) )
}

# --- Helper: wait for MSTeams package or MSI and return the MSI path ---
function Find-TMAInstallerPath {
    param([int]$TimeoutSec = 300)
    try {
        $sw = [Diagnostics.Stopwatch]::StartNew()
        $winApps = Join-Path $env:ProgramFiles 'WindowsApps'

        while ($sw.Elapsed.TotalSeconds -lt $TimeoutSec) {
            # 1) Try via MSTeams package registration
            $pkg = Get-AppxPackage -Name MSTeams -AllUsers -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($pkg) {
                $candidate = ('{0}\WindowsApps\MSTeams_{1}_x64__8wekyb3d8bbwe\MicrosoftTeamsMeetingAddinInstaller.msi' -f $env:ProgramFiles, $pkg.Version)
                if (Test-Path $candidate) { return $candidate }
            }

            # 2) Fallback: direct search for the MSI inside WindowsApps
            $msi = Get-ChildItem $winApps -Filter 'MicrosoftTeamsMeetingAddinInstaller.msi' -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($msi) { return $msi.FullName }

            Start-Sleep -Seconds 5
        }
    } catch {
        try { NMMLogOutput -Level 'Warning' -Message ("Find-TMAInstallerPath exception: " + $_.Exception.Message) -return $true } catch {}
    }
    return $null
}

# Get-WebView2InstallerX64:
# 1) Try evergreen Bootstrapper (fwlink) with redirects + desktop UA;
# 2) if HTML/non-binary returned, scrape developer page to find Standalone x64 installer;
# 3) validate binary and return the local path.
function Get-WebView2InstallerX64 {
    param([string]$OutPath = "$env:TEMP\MicrosoftEdgeWebView2RuntimeInstallerX64.exe")

    $ua = @{ 'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)' }
    $bootstrapperUrl = 'https://go.microsoft.com/fwlink/?linkid=2124703'

    try {
        Invoke-WebRequest -Uri $bootstrapperUrl -OutFile $OutPath -MaximumRedirection 10 `
      -Headers $ua -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
        if (-not (Test-Binary $OutPath)) { throw "Bootstrapper returned non-binary content" }
        return $OutPath
    } catch {
        try {
            $page = Invoke-WebRequest -Uri 'https://developer.microsoft.com/en-us/microsoft-edge/webview2/' `
        -Headers $ua -UseBasicParsing -TimeoutSec 120 -ErrorAction Stop
            $rx = 'https[^"\\'']+WebView2RuntimeInstallerX64\.exe'
            $m  = [regex]::Match($page.Content, $rx)
            if (-not $m.Success) {
                NMMLogOutput -Level 'Warning' -Message "Cannot locate the Standalone x64 WebView2 installer link." -throw $true 
            }
            $standaloneUrl = $m.Value
            Invoke-WebRequest -Uri $standaloneUrl -OutFile $OutPath -MaximumRedirection 10 `
        -Headers $ua -UseBasicParsing -TimeoutSec 300 -ErrorAction Stop
            if (-not (Test-Binary $OutPath)) {
                NMMLogOutput -Level 'Warning' -Message "Downloaded WebView2 file is not a valid EXE/MSI: $OutPath" -throw $true 
            }
            return $OutPath
        } catch {
            NMMLogOutput -Level 'Warning' -Message "WebView2 download failed: $($_.Exception.Message)" -throw $true
        }
    }
}

function NMMLogOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet('Information', 'Warning', 'Error')]
        [string]$Level,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [string]$LogFilePath = "$Env:WinDir\Temp\NerdioManagerLogs",

        [string]$LogName = 'Install-Teams.txt',

        [bool]$throw = $false,

        [bool]$return = $false,

        [bool]$exit = $false,

        [bool]$FirstLogInnput = $false
    )

    if (-not (Test-Path $LogFilePath)) {
        New-Item -ItemType Directory -Path $LogFilePath -Force
        Write-Output "$LogFilePath has been created."
    }
    else {
        if ($FirstLogInnput -eq $true) {
            Add-Content -Path "$($LogFilePath)\$($LogName)" -Value "################# New Script Run #################"
        }
    }

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "$timestamp [$Level]: $Message"

    try {
        Add-Content -Path "$($LogFilePath)\$($LogName)" -Value $logEntry
    }
    catch {
        Write-Error $_.Exception.Message
        if ($throw) {
            throw $_.Exception.Message
        }
    }
    
    if ($throw) {
        Write-Error $Message
        throw $Message
    }

    if ($return) {
        return $Message
    }

    if ($exit) {
        Write-Output $Message
        exit
    }
}

try {
    if (!(Test-Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\') -and !(Test-Path 'HKCU:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}\')) {

        NMMLogOutput -Level 'Information' -Message 'Installing WebView2' -return $true -FirstLogInnput $true

        $wv2 = Get-WebView2InstallerX64 -OutPath "$env:TEMP\NerdioManagerLogs\MicrosoftEdgeWebView2RuntimeInstallerX64.exe"
        $proc = Start-Process -FilePath $wv2 -ArgumentList '/silent /install' -Wait -PassThru

    }
}
catch {
    NMMLogOutput -Level 'Warning' -Message "WebView2 installation failed with exception $($_.exception.message)" -throw $true
}

# Uninstall any previous versions of MS Teams or Web RTC
# Per-user teams uninstall logic

try {
    $TeamsPath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams')
    $TeamsUpdateExePath = [System.IO.Path]::Combine($env:LOCALAPPDATA, 'Microsoft', 'Teams', 'Update.exe')

    if ([System.IO.File]::Exists($TeamsUpdateExePath)) {
        NMMLogOutput -Level 'Information' -Message 'Uninstalling Teams process (per-user installation)' -return $true

        # Uninstall app
        $proc = Start-Process $TeamsUpdateExePath '-uninstall -s' -PassThru
        $proc.WaitForExit()
    }
    else {
        NMMLogOutput -Level 'Information' -Message 'No per-user Teams install found.' -return $true
    }

    NMMLogOutput -Level 'Information' -Message 'Deleting any possible Teams directories (per user installation).' -return $true

    Remove-Item -Path $TeamsPath -Recurse -ErrorAction SilentlyContinue
}
catch {
    NMMLogOutput -Level 'Warning' -Message "Uninstall failed with exception $($_.exception.message)" -throw $true
}

# Per-Machine teams uninstall logic
$GetTeams = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "Teams Machine-Wide*" -and $_.Vendor -eq "Microsoft Corporation" }

if ($null -ne $GetTeams.IdentifyingNumber) {
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/x $($GetTeams.IdentifyingNumber) /qn /norestart" -Wait 2>&1

    NMMLogOutput -Level 'Information' -Message 'Teams per-machine Install Found, uninstalling teams' -return $true
}
# Per-Machine Teams Meeting Add-in uninstall logic
$GetTeamsAddin = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*Teams Meeting Add-in*" -and $_.Vendor -eq "Microsoft" }

if ($null -ne $GetTeamsAddin.IdentifyingNumber) {
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/x $($GetTeamsAddin.IdentifyingNumber) /qn /norestart" -Wait 2>&1

    NMMLogOutput -Level 'Information' -Message 'Teams Meeting Add-in Found, uninstalling Teams Meeting Add-in' -return $true

}

#Check for New Teams being Installed
$Apps = Get-AppxPackage -AllUsers | Where-Object { $_.Name -like "*Teams*" -and $_.Publisher -like "*Microsoft Corporation*" }
foreach ($App in $Apps) {
    Remove-AppxPackage -Package $App.PackageFullName -AllUsers
}

try {
    # WebRTC uninstall logic
    $GetWebRTC = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "Remote Desktop WebRTC*" -and $_.Vendor -eq "Microsoft Corporation" }

    if ($null -ne $GetWebRTC.IdentifyingNumber) {
        Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/x $($GetWebRTC.IdentifyingNumber) /qn /norestart" -Wait 2>&1

        NMMLogOutput -Level 'Information' -Message 'WebRTC Install Found, uninstalling Current version of WebRTC' -return $true
    }
}
catch {
    NMMLogOutput -Level 'Warning' -Message "WebRTC uninstall failed with exception $($_.exception.message)" -throw $true
}

try {
    # Make directories to hold new install
    New-Item -ItemType Directory -Path 'C:\Windows\Temp\msteams_sa\install' -Force | Out-Null

    # Grab MSI installer for MSTeams
    Invoke-WebRequest -Uri $DLink -OutFile 'C:\Windows\Temp\msteams_sa\install\teamsbootstrapper.exe' -UseBasicParsing

    NMMLogOutput -Level 'Information' -Message 'Installing MS Teams' -return $true

    # Installing MS Teams
    $proc = Start-Process 'C:\Windows\Temp\msteams_sa\install\teamsbootstrapper.exe' -ArgumentList '-p' -Wait -PassThru 2>&1
    if ($proc.ExitCode -ne 0) {
        NMMLogOutput -Level 'Warning' -Message "Teams bootstrapper failed with exit code: $($proc.ExitCode)" -throw $true
    }
    
    # Set registry values for Teams to use VDI optimization
    NMMLogOutput -Level 'Information' -Message 'Setting Teams to WVD Environment mode' -return $true

    New-Item -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name IsWVDEnvironment -PropertyType DWORD -Value 1 -Force
    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Teams" -Name "disableAutoUpdate" -Value 1 -PropertyType DWord -Force


}
catch {
    NMMLogOutput -Level 'Warning' -Message "Teams installation failed with exception $($_.exception.message)" -throw $true
}

# Installing MS Teams Meeting Add-in for Outlook (machine-wide)
try {
    # Ensure we are elevated (SYSTEM in Scripted Action is admin)
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator') ){
        NMMLogOutput -Level 'Warning' -Message "Add-in install skipped: not running as administrator." -return $true
    } else {
        # Path to embedded MSI inside WindowsApps (x64)
        $TMAPath = Find-TMAInstallerPath -TimeoutSec 600
        if (-not $TMAPath) {
            NMMLogOutput -Level 'Warning' -Message "Add-in install skipped: TMAInstaller (MSTeams) not found." -return $true
        } else {
            # Get new Teams package version (AllUsers)
            $NewTeamsPackage = Get-AppxPackage -Name MSTeams -AllUsers | Select-Object -First 1
            if ($NewTeamsPackage)
            {
                $NewTeamsPackageVersion = $NewTeamsPackage.Version
                NMMLogOutput -Level 'Information' -Message ("Detected new Teams package version: " + $NewTeamsPackageVersion) -return $true
            } else {
                NMMLogOutput -Level 'Warning' -Message "New Teams package version does not detected." -throw $true
            }

            if (-not (Test-Path $TMAPath)) {
                NMMLogOutput -Level 'Warning' -Message ("Add-in MSI not found at " + $TMAPath) -return $true
            } else {
                # Get add-in binary version from MSI (used for TARGETDIR)
                $publisher = Get-AppLockerFileInformation -Path $TMAPath | Select-Object -ExpandProperty Publisher -ErrorAction SilentlyContinue
                $TMAVersion = $null
                if ($publisher -and $publisher.BinaryVersion) {
                    $TMAVersion = $publisher.BinaryVersion
                } else {
                    # Fallback: read ProductVersion via registry later; install to default path without version subfolder
                    NMMLogOutput -Level 'Warning' -Message "Could not resolve add-in BinaryVersion; will install to default path without version subfolder." -return $true
                }

                # Microsoft updated recommended path from TeamsMeetingAddin -> TeamsMeetingAdd-in (with hyphen)
                if ($TMAVersion) {
                    $TargetDir = ("{0}\Microsoft\TeamsMeetingAdd-in\{1}\" -f ${env:ProgramFiles(x86)}, $TMAVersion)
                } else {
                    $TargetDir = ("{0}\Microsoft\TeamsMeetingAdd-in\" -f ${env:ProgramFiles(x86)})
                }

                # Build msiexec parameters
                $params = '/i "{0}" TARGETDIR="{1}" ALLUSERS=1 /qn /norestart' -f $TMAPath, $TargetDir
                NMMLogOutput -Level 'Information' -Message ("Executing msiexec.exe " + $params) -return $true

                $proc = Start-Process -FilePath msiexec.exe -ArgumentList $params -Wait -PassThru
                if ($proc.ExitCode -ne 0) {
                    NMMLogOutput -Level 'Warning' -Message "Teams Meeting Add-in MSI failed with exit code: $($proc.ExitCode)" -throw $true
                } else {
                    NMMLogOutput -Level 'Information' -Message "Teams Meeting Add-in installed successfully (machine-wide)." -return $true
                }
            }
        }
    }
}
catch {
    NMMLogOutput -Level 'Warning' -Message ("Teams Meeting Add-in install exception: " + $_.Exception.Message) -return $true
}

<#
#Use MS shortcut to WebRTC install
Temporarily adding a fixed version of WebRTC with the March 2024 release.
To roll-back to the latest, set $MarchwebRTC to $false in the script parameters.
#>
try {

    switch ($MarchwebRTC) {
        $true {
            $dlink2 = 'https://aka.ms/msrdcwebrtcsvc/msi'
        }
        $false {
            $dlink2 = 'https://aka.ms/msrdcwebrtcsvc/msi'
        }
    }

    # Grab MSI installer for WebRTC
    Invoke-WebRequest -Uri $DLink2 -OutFile 'C:\Windows\Temp\msteams_sa\install\MsRdcWebRTCSvc_x64.msi' -UseBasicParsing

    # Install Teams WebRTC Websocket Service
    NMMLogOutput -Level 'Information' -Message 'Installing WebRTC component' -return $true

    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/i C:\Windows\Temp\msteams_sa\install\MsRdcWebRTCSvc_x64.msi /log C:\Windows\temp\NerdioManagerLogs\WebRTC_install_log.txt /quiet /norestart" -Wait 2>&1

    NMMLogOutput -Level 'Information' -Message 'Finished running installers. Check C:\Windows\Temp\NerdioManagerLogs for logs on the MSI installations.' -return $true
    NMMLogOutput -Level 'Information' -Message 'All Commands Executed; script is now finished. Allow 5 minutes for teams to appear' -return $true
}
catch {
    NMMLogOutput -Level 'Warning' -Message "WebRTC installation failed with exception $($_.exception.message)" -throw $true
}
