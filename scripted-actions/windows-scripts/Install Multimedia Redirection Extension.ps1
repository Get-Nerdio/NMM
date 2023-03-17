#description: Install multimedia redirection extension for AVD
#tags: Nerdio

<# Notes:

This Scripted Action will install the multimedia redirection extension for virtual desktop, along 
with the browser extension.

See https://learn.microsoft.com/en-us/azure/virtual-desktop/multimedia-redirection
for more information

#>

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

Write-Output "Downloading C++ redistributables"
Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile "$env:TEMP\vc_redist.x64.exe"
Write-Output "Installing C++ redistributables"
Start-Process -NoNewWindow -FilePath "$env:TEMP\vc_redist.x64.exe" -ArgumentList "/q /norestart" -Wait

Write-Output "Downloading multimedia redirection msi"
Invoke-WebRequest -Uri 'https://aka.ms/avdmmr/msi' -OutFile "$env:TEMP\MsMMRHostInstaller.msi"
Write-Output "Installing multimedia redirection"
Start-Process msiexec.exe -Wait -ArgumentList "/I $env:TEMP\MsMMRHostInstaller.msi /quiet"