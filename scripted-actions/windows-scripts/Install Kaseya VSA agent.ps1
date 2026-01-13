#description: Install the Kaseya VSA agent.
#execution mode: Individual
#tags: Nerdio, Kaseya

<#
Notes:
The installation script requires the KcsSetup download URL. You can get it from the customer's unique URL under the link "Click here if Agent doesn't begin downloading automatically".
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    KaseyaDownloadURL
#>

##### Required Variables #####

$DownloadURL = $SecureVars.KaseyaDownloadURL

##### Script Logic #####
if($DownloadURL -eq $null) {
    Write-Output "ERROR: The secure variable DownloadURL are not provided"
}
else {
    $InstallerName   = "KcsSetup.exe"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)
    Start-Process $InstallerPath
}