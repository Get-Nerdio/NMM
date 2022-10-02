#description: Uninstall the NinjaRMM agent.
#execution mode: Individual
#tags: Nerdio, NinjaRMM
<#
Notes:
This script uninstall NinjaRMM agent
#>

##### Script Logic #####

$UninstallString = (Get-ItemProperty HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*).UninstallString

if($UninstallString -eq $null) {
    $UninstallString = (Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\NinjaRMMAgent*).UninstallString
}

if($UninstallString -eq $null) {
    Write-Output "ERROR: NinjaRMM agent not found"
}

else {
    $service=Get-Service "NinjaRMMAgent" 
    if($service)
    {
        Stop-Service $service -Force
    }
    $UninstallProcess = Start-Process -FilePath "$UninstallString" -ArgumentList "--mode unattended" -PassThru
    $UninstallProcess.WaitForExit()
    Start-Sleep -Seconds 60
    $NinjaRmmFolder = $UninstallString.Replace('\uninstall.exe', "")
    $NinjaRmmFolder = $NinjaRmmFolder.Replace('"', "")
    if(Test-Path $NinjaRmmFolder) {
        Remove-Item -LiteralPath  $NinjaRmmFolder -Force -Recurse
    }
}