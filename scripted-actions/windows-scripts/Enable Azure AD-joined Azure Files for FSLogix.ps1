#description: Enables the use of Azure AD-joined Azure Files shares for fslogix without requiring blob storage and cloud cache
#tags: Nerdio, Preview

<# Notes:

This scripted action requires the following Secure Variables in Nerdio:

AADProfileStorageAccountUser - the name of the storage account
AADProfileStorageAccountKey - the storage account key (available in Azure portal)
AADProfileStorageFQDN - e.g. mystorageaccount.file.core.windows.net (do not include the /share directory)

WARNING: If using Windows 11 22H2 or later, this configuration will disable Windows Defender Credential Guard.

Regardless of windows version, local administrators on the VM will be able to access all user profiles stored on the share

This script is based on work by Marcel Meurer 

#>

$SecureVars.AADProfileStorageAccountUser
$SecureVars.AADProfileStorageAccountKey
$SecureVars.AADProfileStorageFQDN


cmdkey.exe /add:$SecureVars.AADProfileStorageFQDN /user:localhost\$SecureVars.AADProfileStorageAccountUser /pass:$SecureVars.AADProfileStorageAccountKey


$WinVersion = Get-ComputerInfo 
if ($winversion.OsBuildNumber -ge 22621) {
    New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LsaCfgFlags" -Value 0 -force
}