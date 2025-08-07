#description: Install Axcient x360 Agent. TokenID needs to be a Inherited Variable 'x360RecoverTokenID'.
#tags: Nerdio, Apps install

<#
This script downloads and installs the latest version of Axcient x360 Agent
#>

# WARNING: This script logs actions to a temporary file. Ensure no sensitive data is manually logged.
# Log file location: $logFile

### variables
$msiUrl = "https://s3.us-west-2.amazonaws.com/pkgmgrrepo.replibit.net/agentInstaller.msi"
$destinationFolder = Join-Path $env:TEMP "Axcient\x360Recover"
$destinationPath = Join-Path $destinationFolder "AgentInstaller.msi"
$logFile = Join-Path $destinationFolder "Installation-script.log"
$logMSIFile = Join-Path $destinationFolder "Installation-script.msi.log"
$tokenID = $InheritedVars.x360RecoverTokenID
if (-not $tokenID) {
    $tokenID = $SecureVars.x360RecoverTokenID
}

if (-not (Test-Path $destinationFolder)) {
    New-Item -ItemType Directory -Path $destinationFolder | Out-Null
}

function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] $Message"
    Add-Content -Path $logFile -Value $logMessage
}

Write-Log "`n------------------------------Installation of Axcient x360 Agent`n"

if (!$tokenID) {
    Write-log "Token ID MUST be specified in the secure variable x360RecoverTokenID"
    Write-log "Installation interrupted"
    return
}

try {
    Write-Log "Downloading MSI from $msiUrl to $destinationPath"
    Invoke-WebRequest -Uri $msiUrl -OutFile $destinationPath
} catch {
    Write-Log "Downloading failed with exception message:"
    Write-Log "     $_.exception.message"
    return
}

Write-Log "Installing MSI"
Start-Process msiexec -ArgumentList "/i $destinationPath /quiet TOKENID=$tokenID /l* $logMSIFile" -Wait

Write-Log "Installation completed."
Write-Log "See $logMSIFile"