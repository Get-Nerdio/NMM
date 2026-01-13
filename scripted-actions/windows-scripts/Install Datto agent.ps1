#description: Install the Datto agent.
#execution mode: Individual
#tags: Nerdio, Datto

<#
Notes:
The installation script requires an Datto agent download URL.
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    DattoDownloadURL
#>

##### Required Variables #####

$DattoDownloadURL = $SecureVars.DattoDownloadURL

##### Script Logic #####

if($DattoDownloadURL -eq $null) {
    Write-Output "ERROR: The secure variable DattoDownloadURL are not provided"
}

else {    
    $InstallerName = "DattoAgentInstall.exe"
    $InstallerPath = Join-Path $Env:TMP $InstallerName

    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DattoDownloadURL, $InstallerPath)

    Start-Process $InstallerPath -Wait
} 