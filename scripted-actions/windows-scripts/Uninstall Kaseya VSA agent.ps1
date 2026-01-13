#description: Uninstall the Kaseya VSA agent.
#execution mode: Individual
#tags: Nerdio, Kaseya

<#
Notes:
The uninstall script requires a Kaseya VSA agent group ID.
You must provide secure variables to this script as seen in the Required Variables section. 
Set these up in Nerdio Manager under Settings->Integrations. The variables to create are:
    KaseyaGroupId
#>

##### Required Variables #####

$GroupId = $SecureVars.KaseyaGroupId

##### Script Logic #####

$LogPath = Join-Path $Env:TMP "kasetup.log"
$UninstallerName = "KASetup.exe"
$Path32 = "C:\Program Files (x86)\Kaseya"
$Path64 = "C:\Program Files\Kaseya"

if (test-path $Path32) {
    $ExitCode = (Start-Process "$Path32\$GroupId\$UninstallerName" "/s /r /g $GroupId /l $LogPath" -Wait -PassThru).ExitCode

    if ($ExitCode -eq 0) {
        Write-Output "Uninstalled successfully"
    }
    else {
        Write-Output "Uninstall completed with exit code $ExitCode."
    }
}

elseif (test-path $Path64) {
    $ExitCode = (Start-Process "$Path64\$GroupId\$UninstallerName" "/s /r /g $GroupId /l $LogPath" -Wait -PassThru).ExitCode

     if ($ExitCode -eq 0) {
        Write-Output "Uninstalled successfully"
    }
    else {
        Write-Output "Uninstall completed with exit code $ExitCode."
    }
}

else {
    Write-Output "ERROR: KASetup.exe not found"
}