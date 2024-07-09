#description: Unregisters endpoint agent from Sophos Central using API.
#tags: Nerdio, Sophos
<#
Notes:
IMPORTANT: Refer to the Sophos Integration Article for instructions on how to use this script!
https://help.nerdio.net
This script uses the Sophos API to delete the associated VM from Sophos Central.
Please refer to sophos documentation for more information:
https://developer.sophos.com/intro
https://developer.sophos.com/docs/endpoint-v1/1/overview
#>

# Enable Logging
function Write-Log {
    param
    (
        [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
        [string]$Message
    )
    try {
        Write-Host $Message
        $tempFolder = [environment]::GetEnvironmentVariable('TEMP', 'Machine')
        $logsFolderName = "NerdioManagerLogs\ScriptedActions\sophosunregister"
        $logsPath = "$tempFolder\$logsFolderName"
  
        if (-not (Test-Path -Path $logsPath)) {
            New-Item -Path $tempFolder -Name $logsFolderName -ItemType Directory -Force | Out-Null
        }
  
        $DateTime = Get-Date -Format "MM-dd-yy HH:mm:ss"
        if ($Message) {
            Add-Content -Value "$DateTime - $Message" -Path "$logsPath\ps_log.txt"
        }
    }
    catch {
        Write-Error $_.Exception.Message
    }
}

$SaveVerbosePreference = $VerbosePreference
$VerbosePreference = 'continue'
$VMTime = Get-Date
$LogTime = $VMTime.ToUniversalTime()

Write-Log "################# New Script Run #################"
Write-Log "Current time (UTC-0): $LogTime"

# Pass in secure variables from Nerdio Manager
$ClientID     = $SecureVars.sophosclientid
$ClientSecret = $SecureVars.sophosclientsecret
$TenantID     = $SecureVars.sophostenantid
$APIHost      = $SecureVars.sophosapihost

# Error out if required secure variables are not passed
if(!$ClientID -or !$ClientSecret){
    Write-Error "ERROR: Required variables sophosclientiD and/or sophosclientSecret are not being passed from Nerdio Manager. Please add these secure variables" -ErrorAction Stop

}

# Authenticate and get Bearer Token
$AuthBody = @{
    grant_type = "client_credentials"
    client_id = $ClientID
    client_secret = $ClientSecret
    scope = "token"
}
Write-Log "INFO: Retrieving Auth Info using Client Secrets"
$AuthResponse = (Invoke-RestMethod -Method 'post' -Uri 'https://id.sophos.com/api/v2/oauth2/token' -Body $AuthBody)
$AuthToken = $AuthResponse.access_token
$AuthHeaders = @{Authorization = "Bearer $AuthToken"}

$WhoAmIResponse = (Invoke-RestMethod -Method 'get' -headers $AuthHeaders -Uri 'https://api.central.sophos.com/whoami/v1' -UseBasicParsing)

if($WhoAmIResponse.idtype -eq "tenant"){
    $APIHost = $WhoAmIResponse.apihosts.dataRegion
    $TenantID = $WhoAmIResponse.id
    $Header = @{
        'Authorization' = "Bearer $AuthToken"
        'X-Tenant-ID' = $TenantID
    }
}
elseif($WhoAmIResponse.idtype -eq "partner"){
    $SophosTenantId = $SecureVars.SophosTenantId
    if ([string]::IsNullOrEmpty($SophosTenantId)) {
        throw "SophosTenantId secure variable not specified in Nerdio account"
    }
    $SophosId = $WhoAmIResponse.id
    $Header = @{
        'Authorization' = "Bearer $AuthToken"
        'X-Partner-ID' = $SophosId
    }
    $tenant = Invoke-RestMethod   "https://api.central.sophos.com/partner/v1/tenants/$SophosTenantId" -Method get -UseBasicParsing -Headers $Header
    $APIHost = $tenant.APIHost
    $Header = @{Authorization = "Bearer $AuthToken"
                    'X-Tenant-ID' = $SophosTenantId
                    Accept = 'application/json'}
}

# Query for endpoint with hostname that matches Azure VM name, get endpoint ID
Write-Log "INFO: APIHost is $APIHost"
Write-Log "INFO: Searching registered endpoints for matching VM hostname"
$EndpointResponse = (Invoke-RestMethod -Method 'get' -Headers $Header -uri "$APIHost/endpoint/v1/endpoints?hostnameContains=$AzureVMName" -UseBasicParsing)
if(!$EndpointResponse.items){
    Write-Log "ERROR: No endpoints found in sophos central that match the hostname. Ending script"
    exit
}
# Sophos API can return multiple endpoints, the hostname search is not strict. Go through results and get exact match
foreach($Endpoint in ($EndpointResponse.items)){ 
    if($Endpoint.Hostname -match "$AzureVMName"){
        $EndpointID = $Endpoint.id
        Write-Log "INFO: Found Endpoint ID: $EndpoindID"
    }
}

# Send DELETE request to Sophos API and provide endpoint ID
Write-Log "INFO: Attempting to Delete $AzureVMName from Sophos Central"
$DeleteResponse = (Invoke-RestMethod -Method 'delete' -Headers $Header -uri "$APIHost/endpoint/v1/endpoints/$EndpointID" -UseBasicParsing)

# Check if request was successful
Write-Log "INFO: Checking response to confirm deletion"
Start-Sleep -Seconds 15
if($DeleteResponse.deleted = "true"){
    Write-Log "INFO: Successfully deleted $AzureVMName from Sophos Central"
}
else {
    Write-Log "Error: Unable to delete endpoint from Sophos Central"
}

$VerbosePreference=$SaveVerbosePreference
