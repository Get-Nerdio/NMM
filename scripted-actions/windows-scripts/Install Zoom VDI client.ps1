#description: Downloads and installs Zoom VDI client for WVD. Reference https://support.zoom.us/hc/en-us/articles/360052984292 (under "Windows Virtual Desktop") for more information
#execution mode: IndividualWithRestart
#tags: Nerdio, Apps install
<# 
Notes:
This script installs the Zoom VDI client for use on WVD Session hosts.

To install specific versions, update the URL variables below with links to the .msi installers.
#>

$ZoomClientUrl= "https://zoom.us/download/vdi/6.2.11.25670/ZoomInstallerVDI.msi?archType=x64"

# Start powershell logging
function Write-Log {
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Message
    )
    try {
        Write-Host $Message
        $tempFolder = [environment]::GetEnvironmentVariable('TEMP', 'Machine')
        $logsFolderName = "NerdioManagerLogs\ScriptedActions\zoom_sa"
        $logsPath = "$tempFolder\$logsFolderName"
  
        if (-not (Test-Path -Path $logsPath)) {
            New-Item -Path $tempFolder -Name $logsFolderName -ItemType Directory -Force | Out-Null
        }
  
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
        if ($Message) {
            Add-Content -Value "$DateTime - $Message" -Path "$logsPath\ps_log.txt"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$VMTime = Get-Date
$LogTime = $VMTime.ToUniversalTime()

Write-Log "################# New Script Run #################"
Write-Log "Current time (UTC-0): $LogTime"

# Make directory to hold install files
mkdir "$env:temp\zoom_sa\install" -Force

Invoke-WebRequest -Uri $ZoomClientUrl -OutFile "$env:temp\zoom_sa\install\ZoomInstallerVDI.msi" -UseBasicParsing

# Install Zoom. Edit the argument list as desired for customized installs: https://support.zoom.us/hc/en-us/articles/201362163
Write-Log "INFO: Installing Zoom client. . ."
Start-Process C:\Windows\System32\msiexec.exe `
-ArgumentList "/i $env:temp\zoom_sa\install\ZoomInstallerVDI.msi /l*v $env:temp\NerdioManagerLogs\ScriptedActions\zoom_sa\zoom_install_log.txt /qn /norestart" -Wait
Write-Log "INFO: Zoom client install finished."

$VerbosePreference=$SaveVerbosePreference
