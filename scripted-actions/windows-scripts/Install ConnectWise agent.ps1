#description: Install the ConnectWise Automate agent.
#execution mode: Individual
#tags: Nerdio, ConnectWise

<#
Notes:
This script will qualify if another Autoamte agent is already
installed on the computer. If the existing agent belongs to different 
Automate server, it will automatically uninstall the existing 
agent. This comparison is based on the server's FQDN. 

You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in NMW under Settings->Nerdio Integrations. The variables to create are:
    AutomateServerUrl
    AutomateServerToken   
#>

##### Required Variables #####

$Server = $SecureVars.AutomateServerUrl
$Token = $SecureVars.AutomateServerToken

##### Script Logic #####

[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072); Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Get-Nerdio/NMM/main/scripted-actions/modules/CMSP_Automate-Module.psm1'); Install-Automate -Server $Server -LocationID  -Token $Token -Transcript