#description: Uninstall the BlackPoint agent.
#execution mode: Individual
#tags: Nerdio, BlackPoint
<#
Notes:
This script uninstall BlackPoint agent
#>

##### Script Logic #####
$Path32 = "C:\Program Files (x86)\Blackpoint"
$Path64 = "C:\Program Files\Blackpoint"

$UninstallString = (Get-ChildItem -path HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall | Get-ItemProperty |Where-Object {$_.DisplayName -match "SnapAgent" }).UninstallString 

if($UninstallString -eq $null) {
    $UninstallString = (Get-ChildItem -path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Uninstall | Get-ItemProperty |Where-Object {$_.DisplayName -match "SnapAgent" }).UninstallString 
}

if($UninstallString -eq $null) {
    Write-Output "ERROR: Datto agent not found"
}

else {

    $SnapAgentProcess = Get-Process -Name "SnapAgent" -ErrorAction SilentlyContinue 
    $SnapWProcess = Get-Process -Name "snapw" -ErrorAction SilentlyContinue 

    if($SnapAgentProcess -ne $null) {
        $SnapAgentProcess | Stop-Process -Force
        Start-Sleep -Seconds 10 
    }

    if($SnapWProcess -ne $null) {
        $SnapWProcess | Stop-Process -Force
        Start-Sleep -Seconds 10 
    }

    $UninstallOption = $UninstallString -Replace "msiexec.exe","" -Replace "/I","" -Replace "/X",""

    Start-Process "msiexec.exe" -arg "/X $UninstallOption /quiet" -Wait
    
    Start-Sleep -Seconds 60

    if (Test-Path $Path32) {
        Remove-Item -LiteralPath $Path32 -Force -Recurse 
    }

    if (Test-Path $Path64) {
        Remove-Item -LiteralPath $Path64 -Force -Recurse 
    }
}