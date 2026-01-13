#description: Install the ConnectWise AUTOMATE RMM agent.
#execution mode: Individual
#tags: Nerdio, ConnectWise

<#
Notes:
This script will install the CONNECTWISE AUTOMATE AGENT. 
The script will first qualify if another Automate agent is already
installed on the computer. If the existing agent belongs to different 
Automate server, it will automatically uninstall the existing 
agent. This comparison is based on the server's FQDN. 

You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    AutomateServerUrl
    AutomateServerToken or SystemPassword
#>

##### Secure Variables #####

$Server = $SecureVars.AutomateServerUrl
$Token = $SecureVars.AutomateServerToken
$Password = $SecureVars.SystemPassword 

##### Variables #####

#Set LocationID to install the Automate Agent directly to the appropieate client's location / site.
$LocationId = 1

##### Script Logic #####

if(($Token -eq $null) -and  ($Password -eq $null)) {
Write-Output "ERROR: The secure variables AutomateServerToken or SystemPassword are not provided"
}

elseif ($Password) {
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072); Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Get-Nerdio/NMM/main/scripted-actions/modules/CMSP_Automate-Module.psm1'); Install-Automate -Server $Server -LocationID $LocationId -SystemPassword $Password -Transcript
}

elseif ($Token) {
[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072); Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Get-Nerdio/NMM/main/scripted-actions/modules/CMSP_Automate-Module.psm1'); Install-Automate -Server $Server -LocationID $LocationId -Token $Token -Transcript
}