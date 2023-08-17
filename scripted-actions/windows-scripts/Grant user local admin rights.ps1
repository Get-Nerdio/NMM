#description: Adds user assigned to personal desktop to local Administrators group on session host VM. Use only with personal host pools.
#execution mode: Combined
#tags: Nerdio
<#
Notes: 
This script adds the user assigned the personal desktop to the local admin group
#>
if($DesktopUser){
    if ((Get-WmiObject -Namespace root\cimv2 -Class Win32_ComputerSystem).domain -eq 'WORKGROUP') {
        Write-Output "No domain found. Assuming AzureAD joined."
        Add-LocalGroupMember -Group "Administrators" -Member "AzureAD\$DesktopUser"
    }
    else {
        Add-LocalGroupMember -Group "Administrators" -Member "$DesktopUser"
    }
}
else{
    Write-Error -Message 'ERROR: No Desktop User Specified. This VM may not be a personal Desktop.'
    exit
}