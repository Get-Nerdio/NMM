#description: Installs Egnyte and maps a drive for all users
#tags: Nerdio, Preview

<# Notes:

This Scripted Action will install Egnyte and prompt users to map a drive. If the egnyte domain and label are 
provided, this scripted action will map a drive without user input. Modify the below variables to provide
values for the Egnyte domain and drive label

#>

$EgnyteDriveDomain = '' # change to egnyte domain, without ".egnyte.com"
$EgnyteDriveLabel = '' # change to desired drive lable
$EgnyteDriveLetter = 'Z' # change to desired drive letter
$EgnyteDriveSSO = '1' # change to 0 to disable SSO

$MsiUrl = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/latest/EgnyteConnectWin.msi"

Write-Output "Downloading Engyte installer"
Invoke-WebRequest -Uri $MsiUrl -OutFile $env:TEMP\EgnyteConnectWin.msi

if (![string]::IsNullOrEmpty($EgnyteDriveDomain) -and ![string]::IsNullOrEmpty($EgnyteDriveLabel)) {
    Write-Output "Installing Egnyte and mapping drive"
    msiexec /i $env:TEMP\EgnyteConnectWin.msi ED_DRIVE_DOMAIN=$EgnyteDriveDomain ED_DRIVE_LABEL=$EgnyteDriveLabel  ED_DRIVE_SSO=$EgnyteDriveSSO ED_DRIVE_LETTER=$EgnyteDriveLetter ED_SILENT=1 /passive
}

else {
    Write-Output "No domain provided; users will be prompted to map a drive after installation"
    Write-Output "Installing Egnyte"
    msiexec /i $env:TEMP\EgnyteConnectWin.msi /passive
}
