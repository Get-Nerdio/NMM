#description: Downloads and installs OneDrive for all users
#tags: Nerdio
#Requires -RunAsAdministrator

<#
Notes:
This script will download the OneDriveSetup.exe file from the Microsoft link and install it for all users.
#>

# Define the URL of the OneDriveSetup.exe file
$OneDriveSetupUrl = "https://go.microsoft.com/fwlink/p/?LinkID=2182910"

#Temporary directory path
$tempDir=$env:temp
if ([string]::IsNullOrWhiteSpace($tempDir)) {
    $tempDir = "C:\Temp"
}
if (!(Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

# Define the path where the OneDriveSetup.exe file will be downloaded
$DownloadPath = "${env:temp}\OneDriveSetup.exe"

# Download the OneDriveSetup.exe file
Invoke-WebRequest -Uri $OneDriveSetupUrl -OutFile $DownloadPath

#Kill running OneDrive process to remove possible installation lock
If ((Get-Process).ProcessName -Like "OneDrive") {
    taskkill /f /im OneDrive.exe
}
Write-Host uninstalling
#Uninstall current version (if exists) to avoid "newer version is installed" modal
Start-Process -FilePath $DownloadPath -ArgumentList "/uninstall" -Wait
Write-Host installing
# Execute the OneDriveSetup.exe file with the /allusers flag
Start-Process -FilePath $DownloadPath -ArgumentList "/allusers" -Wait
Write-Host removing
Remove-Item $DownloadPath -Force

Write-Host installed

### End Script ###
