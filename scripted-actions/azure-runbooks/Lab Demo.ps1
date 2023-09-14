#description: Do something awesome
#execution mode: Individual
#tags: Nerdio, LabDemo

<#
Notes:
This script does something awesome.

#>


<# Variables:
{
  "GiveMeAParameter": {
    "Description": "Parameter description.",
    "IsRequired": false
  }
}
#>

##### Setting Variables #####

$HardCodedVariable = 10
$SecureVariable = $SecureVars.DemoSecureVariable

##### Script Logic #####

Write-Output "ParameterName = $GiveMeAParameter"
Write-Output "HardCodedVariable = $HardCodedVariable"
Write-Output "SecureVariable = $SecureVariable"
Write-Output "AzureSubscriptionId = $AzureSubscriptionId"

