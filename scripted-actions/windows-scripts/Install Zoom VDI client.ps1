#description: Downloads and installs Zoom VDI client for AVD. Reference https://support.zoom.com/hc/en/article?id=zm_kb&sysparm_article=KB0063810 (under "Azure Virtual Desktop") for more information
#execution mode: IndividualWithRestart
#tags: Nerdio, Apps install
<# 
Notes:
This script installs the Zoom VDI client for use on AVD Session hosts.

To install specific versions, update the URL in the $zoomClientUrl variable with links to the .msi installers.
#>

$zoomClientUrl = "https://zoom.us/download/vdi/latest/ZoomInstallerVDI.msi?archType=x64"
$logPath = "$env:temp\NerdioManagerLogs\ScriptedActions\zoom_sa"
$installPath = "$env:temp\zoom_sa\install"
$installerPath = "$installPath\ZoomInstallerVDI.msi"

# Start powershell logging
$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$logTime = (Get-Date).ToUniversalTime()

try {
    # Create log directory
    New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    Start-Transcript -Path "$logPath\ps_log.txt" -Append
    Write-Output "################# New Script Run #################"
    Write-Output "Current time (UTC-0): $logTime"

    # Create and prepare install directory
    New-Item -Path $installPath -ItemType Directory -Force | Out-Null

    # Download Zoom VDI Client
    Write-Output "INFO: Downloading Zoom VDI Client..."
    Invoke-WebRequest -Uri $zoomClientUrl -OutFile $installerPath -UseBasicParsing

    # Install Zoom
    Write-Output "INFO: Installing Zoom client..."
    $processArgs = @(
        "/i"
        $installerPath
        "/l*v"
        "$logPath\zoom_install_log.txt"
        "/qn"
        "/norestart"
    )
    
    $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $processArgs -Wait -PassThru
    
    if ($process.ExitCode -ne 0) {
        throw "Zoom installation failed with exit code: $($process.ExitCode)"
    }
    
    Write-Output "INFO: Zoom client install finished successfully."
}
catch {
    Write-Output "ERROR: An error occurred during installation: $_"
    throw
}
finally {
    # Cleanup
    if (Test-Path -Path $installPath) {
        Remove-Item -Path $installPath -Recurse -Force
        Write-Output "INFO: Install directory cleaned up."
    }
    
    # End Logging
    Stop-Transcript
    $VerbosePreference = $SaveVerbosePreference
}