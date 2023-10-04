#description: Enables OneDrive signin to persist
#tags: Nerdio, Preview

<# Notes:

For Marketplace images, OneDrive does not stay signed in. This script will enable OneDrive to remain signed in.

#>

REG ADD "HKCU\SOFTWARE\Microsoft\OneDrive" /v EnableADAL /t REG_DWORD /d 2 /f
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\OneDrive" /v SilentAccountConfig /t REG_DWORD /d 0x1 /f
REG ADD "HKCU\SOFTWARE\Microsoft\OneDrive" /v SilentBusinessConfigCompleted /t REG_DWORD /d 1 /f