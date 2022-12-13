#description: Install the BlackPoint agent.
#execution mode: Individual
#tags: Nerdio, BlackPoint

<#
Notes:
The installation script requires an customer UID and an company name.
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Portal. The variables to create are:
    BPCustomerUID
    BPCompanyName
#>

##### Required Variables #####

$CustomerUID = $SecureVars.BPCustomerUID
$CompanyName =  $SecureVars.BPCompanyName


##### Script Logic #####

if(($CustomerUID -eq $null) -or ($CompanyName -eq $null)) {
    Write-Output "ERROR: The secure variables BPCustomerUID and BPCompanyName are not provided"
}

else {
    If (! (Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").Release -gt 394254)
    { 
        Write-Output "BlackPoint agent needs 4.6.1+ of .NET" 
        exit 0
    }

    $CompanyEXE = $CompanyName + "_installer.exe"

    $InstallerName = "snap_installer.exe"
    $InstallerPath = Join-Path $Env:TMP $InstallerName
    $$DownloadURL = "https://portal.blackpointcyber.com/installer/$CustomerUID/$CompanyEXE"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $WebClient = New-Object System.Net.WebClient
    $WebClient.DownloadFile($DownloadURL, $InstallerPath)
    Start-Process -NoNewWindow -FilePath $InstallerPath -ArgumentList "-y" -Wait
} 