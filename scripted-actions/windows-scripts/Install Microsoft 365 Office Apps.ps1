#description: Installs/Updates Office 365 Apps to newest version and disables Auto-Update. Recommended to run on desktop images.
#execution mode: IndividualWithRestart
#tags: Nerdio, Apps install
<# 
Notes:
This script will update Microsoft 365 apps on an Image VM without turning on automatic updates.
It downloads automatically downloads the latest version of ODT and uses it to update M35 Apps.

Please edit $ODTConfig if you use a non-standard deployment of Office 365 (i.e. leaving out powerpoint)
$ODTConfig is what ODT will use for configuration. 
see https://docs.microsoft.com/en-us/deployoffice/overview-office-deployment-tool 
and https://docs.microsoft.com/en-us/deployoffice/office-deployment-tool-configuration-options
for details on ODT configuration XML documentation.

To learn more about the process this script does, 
See https://docs.microsoft.com/en-us/azure/virtual-desktop/install-office-on-wvd-master-image 
#>

# Configure powershell logging
$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
  param
  (
      [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
      [string]$Message
  )
  try {
      Write-Host $Message
      $tempFolder = [environment]::GetEnvironmentVariable('TEMP', 'Machine')
      $logsFolderName = "NerdioManagerLogs\ScriptedActions\msoffice_sa"
      $logsPath = "$tempFolder\$logsFolderName"

      if (-not (Test-Path -Path $logsPath)) {
          New-Item -Path $tempFolder -Name $logsFolderName -ItemType Directory -Force | Out-Null
      }

      $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
      if ($Message) {
          Add-Content -Value "$DateTime - $Message" -Path "$logsPath\ps_log.txt"
      }
  }
  catch {
      Write-Error $_.Exception.Message
  }
}

$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$VMTime = Get-Date
$LogTime = $VMTime.ToUniversalTime()
Write-Log "################# New Script Run #################"
Write-Log "Current time (UTC-0): $LogTime"

# create directory to store ODT and setup files
Write-Log "Create directory to store ODT and setup files"
mkdir "$env:windir\Temp\odt_sa\raw" -Force

# parse through the MS Download Center page to get the most up-to-date download link
Write-Log "Parse through the MS Download Center page to get the most up-to-date download link"
if ($PSVersionTable.PSVersion.major -ge 7) {$MSDlSite2 = Invoke-WebRequest "https://www.microsoft.com/en-us/download/details.aspx?id=49117" -UseBasicParsing -SkipHttpErrorCheck}
else {$MSDlSite2 = Invoke-WebRequest "https://www.microsoft.com/en-us/download/details.aspx?id=49117" -UseBasicParsing }
if ($MSDlSite2.StatusCode -ne 200) {
    Write-Host "Failed to download the page. Status code: $($MSDlSite2.StatusCode)"
    exit
}
ForEach ($Href in $MSDlSite2.Links.Href)
{
    if ($Href -match "officedeploymenttool" ){
        $DLink = $href
    }
}

# Download office deployment tool using up-to-date link grabed eariler
Write-Log "Download office deployment tool using up-to-date link grabed eariler"
Invoke-WebRequest -Uri $DLink -OutFile "$env:windir\Temp\odt_sadata.exe" -UseBasicParsing

# unpack the ODT executable to get the setup.exe
Write-Log "Unpack the ODT executable to get the setup.exe"
Start-Process -filepath "$env:windir\Temp\odt_sadata.exe" -ArgumentList "/extract:$env:windir\Temp\odt_sa\raw /quiet" -Wait

# create a base config XML for ODT to use, this one has auto-update disabled
Write-Log "Create a base config XML for ODT to use, this one has auto-update disabled"
$ODTConfig = @"
<Configuration>
  <Add OfficeClientEdition="64" Channel="MonthlyEnterprise">
    <Product ID="O365ProPlusRetail">
      <Language ID="en-US" />
      <Language ID="MatchOS" />
      <ExcludeApp ID="Groove" />
      <ExcludeApp ID="Lync" />
      <ExcludeApp ID="OneDrive" />
      <ExcludeApp ID="Teams" />
    </Product>
  </Add>
  <RemoveMSI/>
  <Updates Enabled="FALSE"/>
  <Display Level="None" AcceptEULA="TRUE" />
  <Logging Level="Standard" Path="%temp%\WVDOfficeInstall" />
  <Property Name="FORCEAPPSHUTDOWN" Value="TRUE"/>
  <Property Name="SharedComputerLicensing" Value="1"/>
</Configuration>
"@ 
$ODTConfig | Out-File "$env:windir\Temp\odt_sa\raw\odtconfig.xml"

# execute odt.exe using the newly created odtconfig.xml. This updates/installs office (takes a while)
Write-Log "Execute odt.exe using the newly created odtconfig.xml. This updates/installs office (takes a while)"
Start-Process -filepath "$env:windir\Temp\odt_sa\raw\setup.exe" -ArgumentList "/configure $env:windir\Temp\odt_sa\raw\odtconfig.xml" -Wait

$VerbosePreference=$SaveVerbosePreference
