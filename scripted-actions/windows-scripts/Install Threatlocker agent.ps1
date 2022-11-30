#description: Install the Threatlocker agent.
#execution mode: Individual
#tags: Nerdio, Threatlocker

<#
Notes:
The installation script requires an organization name and ThreatLocker Unique Identifier.

Unique Identifier can be found in Deployment Center under the RMM and Script Deployment section. 
https://threatlocker.kb.help/getting-your-unique-identifier-from-threatlocker/

You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Portal. The variables to create are:
    ThreatlockerOrgName
    ThreatlockerUniqueId
#>

##### Required Variables #####

$ThreatlockerOrgName = $SecureVars.ThreatlockerOrgName;
$ThreatlockerIdentifier = $SecureVars.ThreatlockerUniqueId;

##### Variables #####

#Set Group Name 
$ThreatlockerGroupName = "Workstations";

##### Script Logic #####

if(($ThreatlockerOrgName -eq $null) -and  ($ThreatlockerIdentifier -eq $null))  {
    Write-Output "ERROR: The secure variables ThreatlockerOrgName or ThreatlockerIdentifier are not provided"
}

try {
    $Url = 'https://api.threatlocker.com/getgroupkey.ashx'; 
    $Headers = @{'Authorization'=$ThreatlockerIdentifier;'OrganizationName'=$ThreatlockerOrgName;'GroupName'=$ThreatlockerGroupName}; 
    
    [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject([Net.SecurityProtocolType], 3072)
    $Response = (Invoke-RestMethod -Method 'Post' -uri $Url -Headers $Headers -Body ''); 
    $GroupId = $response.split([Environment]::NewLine)[0].split(':')[1].trim();
}
catch {
    Write-Output "Failed to get GroupId";
    Exit 1;
}

if ([Environment]::Is64BitOperatingSystem) {
    $DownloadURL = "https://api.threatlocker.com/installers/threatlockerstubx64.exe";
    $InstallerName = "threatlockerstubx64.exe"
}
else {
    $DownloadURL = "https://api.threatlocker.com/installers/threatlockerstubx86.exe";
    $InstallerName = "threatlockerstubx86.exe"
}
$InstallerPath = Join-Path $Env:TMP $InstallerName
Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallerPath;

Start-Process $InstallerPath "InstallKey=$GroupId" -Wait