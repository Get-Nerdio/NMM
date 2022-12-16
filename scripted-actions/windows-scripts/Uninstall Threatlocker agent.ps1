#description: Uninstall the Threatlocker agent.
#execution mode: Individual
#tags: Nerdio, Threatlocker

<#
Notes:
This script uninstall Threatlocker agent

Disable tamper protection on portal before running uninstall script https://threatlocker.kb.help/disable-tamper-protection/
#>

##### Script Logic #####

if ([Environment]::Is64BitOperatingSystem) {
    $DownloadURL = "https://api.threatlocker.com/installers/threatlockerstubx64.exe";
    $InstallerName = "uninstallthreatlockerstubx64.exe"
}
else {
    $DownloadURL = "https://api.threatlocker.com/installers/threatlockerstubx86.exe";
    $InstallerName = "uninstallthreatlockerstubx86.exe"
}
$InstallerPath = Join-Path $Env:TMP $InstallerName
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallerPath;

Start-Process $InstallerPath "uninstall" -Wait