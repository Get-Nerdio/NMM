#description: Install the Huntress agent.
#execution mode: Individual
#tags: Nerdio, Huntress, Preview

<#
Notes:
The installation script requires an account key and an organization key, 
which are used to associate the agent with a specific organization 
within the Huntress partner account. 
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    HuntressAccountKey
    HuntressOrgKey
#>

##### Required Variables #####

$AccountKey = $SecureVars.HuntressAccountKey
$OrganizationKey =  $SecureVars.HuntressOrgKey

##### Script Logic #####

if(($AccountKey -eq $null) -or ($OrganizationKey -eq $null)) {
    Write-Output "ERROR: The secure variables HuntressAccountKey and HuntressOrgKey are not provided"
}

else {    
    $InstallerName   = "HuntressInstaller.exe"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    $DownloadURL     = "https://update.huntress.io/download/" + $AccountKey + "/" + $InstallerName

    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)
    Start-Process $InstallerPath "/ACCT_KEY=$AccountKey /ORG_KEY=$OrganizationKey /S" -PassThru
} 