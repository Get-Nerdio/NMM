#description: Enables OneDrive signin to persist
#tags: Nerdio, Preview

<# Notes:

For Marketplace images, OneDrive does not stay signed in. This script will enable OneDrive to remain signed in.

#>

New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "EnableADAL" -Value 2 -PropertyType DWord -Force
New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -Value 1 -PropertyType DWord -Force
New-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\OneDrive" -Name "SilentBusinessConfigCompleted" -Value 1 -PropertyType DWord -Force
