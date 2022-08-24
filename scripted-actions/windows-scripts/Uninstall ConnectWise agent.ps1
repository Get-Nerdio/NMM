#description: Uninstall the ConnectWise Automate agent.
#execution mode: Individual
#tags: Nerdio, ConnectWise
<#
Notes:
This script uninstall ConnectWise Automate agent
#>

##### Script Logic #####

[Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072); Invoke-Expression(New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Get-Nerdio/NMM/main/scripted-actions/modules/CMSP_Automate-Module.psm1'); Uninstall-Automate