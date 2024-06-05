#description: Install the Webex VDI.
#execution mode: Individual
#tags: Nerdio, Webex

<#
Notes:
The script install Webex VDI App Version 44.4 with disabled auto upgrade.

You can provide secure variables to this script as seen in the Secure Variables section to customize installation process. 
You can get download URLs for different version of Webex VDI App on this page. https://help.webex.com/en-us/article/ntp1us7/Webex-App-%7C-VDI-release-notes#reference-template_45cde40a-b8c7-472e-a5d1-b8f6220811d2

A value of 0 for WebexAllowAutoUpgrade secure variable prevents Webex App from downloading updates in a VDI environment.
Use this option if you prefer to manually maintain upgrades.
A value of 1 allows automatic upgrades for Webex App on the HVD. If using this option, ensure that your organization is configured for gold channel.

Set these up in Nerdio Manager under Settings->Portal. The variables to create are:
    WebexDownloadURL
    WebexAllowAutoUpgrade
#>

##### Secure Variables #####

$CustomDownloadURL = $SecureVars.WebexDownloadURL
$CustomAllowAutoUpgrade = $SecureVars.WebexAllowAutoUpgrade

##### Default settings #####

$DownloadURL = "https://binaries.webex.com/Webex-Desktop-Windows-x64-Combined-VDI-Gold/20240516060931/WebexBundle.msi"
$AllowAutoUpgrade = 0


##### Script Logic #####
    
    if($CustomDownloadURL -ne $null) {
        $DownloadURL = $CustomDownloadURL
    }

    if($CustomAllowAutoUpgrade -ne $null) {
        $AllowAutoUpgrade = $CustomAllowAutoUpgrade
    }
 
    $InstallerName = "WebexBundle.msi"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    
    Write-Output "Downloading Webex VDI installer from URL: $DownloadURL"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)

    Write-Output "Installing Webex VDI"
    Start-Process msiexec.exe -ArgumentList "/Quiet /i $InstallerPath ALLUSERS=1 ENABLEVDI=1 AUTOUPGRADEENABLED=$AllowAutoUpgrade" -Wait -NoNewWindow

    Write-Output "Removing installer"   
    Remove-Item $InstallerPath -Force