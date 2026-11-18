#description: Install the BlackPoint agent.
#execution mode: Individual
#tags: Nerdio, BlackPoint

<#
Notes:
This one-time provisioning script installs the Blackpoint unified Windows agent.
Configure these secure variables in Nerdio Manager under Settings->Integrations:
    BPCustomerID - the customer-specific Blackpoint customer ID.
    BPAuthToken - the environment-wide authentication token shared across customers.
Replace the legacy BPCustomerUID and BPCompanyEXE configuration with these two
variables, using the unified-agent customer ID and token supplied by Blackpoint.
Do not put credentials in this script.
Only exit code 0 is treated as success; other codes fail without an automatic reboot.
#>

##### Required Variables #####

$CustomerID = [string]$SecureVars.BPCustomerID
$AuthToken = [string]$SecureVars.BPAuthToken

##### Script Logic #####

foreach ($VariableName in @('BPCustomerID', 'BPAuthToken')) {
    $Value = if ($VariableName -eq 'BPCustomerID') { $CustomerID } else { $AuthToken }
    if ([string]::IsNullOrWhiteSpace($Value)) {
        Write-Output "ERROR: Secure variable $VariableName is missing, empty, or whitespace-only."
        exit 1
    }
    if ($Value -match '["\p{Cc}\u2028\u2029]') {
        Write-Output "ERROR: Secure variable $VariableName must not contain double quotes, newlines, or control characters."
        exit 1
    }
}

$ExitCode = 1
$TemporaryDirectory = $null
$OriginalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
$Stage = 'preparing the installer'

try {
    $EncodedCustomerID = [Uri]::EscapeDataString($CustomerID)
    $DownloadURL = "https://agent-sega-production-snap.bpcyber.net/v1/installers?customerId=$EncodedCustomerID&installer=exe&operatingSystem=windows"
    $TemporaryDirectory = Join-Path ([IO.Path]::GetTempPath()) ("Blackpoint-" + [Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $TemporaryDirectory -ErrorAction Stop | Out-Null
    $InstallerPath = Join-Path $TemporaryDirectory 'blackpoint-agent.exe'

    $Stage = 'downloading the installer; check network access and BPCustomerID configuration'
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $DownloadURL -OutFile $InstallerPath -UseBasicParsing -ErrorAction Stop | Out-Null

    # Double trailing backslashes so they cannot escape the closing command-line quote.
    $QuotedCustomerID = $CustomerID -replace '(\\+)$', '$1$1'
    $QuotedAuthToken = $AuthToken -replace '(\\+)$', '$1$1'
    $InstallerArguments = 'CUSTOMER_ID="{0}" AUTH_TOKEN="{1}" /passive' -f $QuotedCustomerID, $QuotedAuthToken
    $Stage = 'running the installer; verify BPCustomerID and BPAuthToken configuration and installation permissions'
    $InstallerProcess = Start-Process -NoNewWindow -FilePath $InstallerPath -ArgumentList $InstallerArguments -Wait -PassThru -ErrorAction Stop
    if ($InstallerProcess.ExitCode -eq 0) {
        $ExitCode = 0
    }
    else {
        Write-Output "ERROR: Blackpoint installer returned exit code $($InstallerProcess.ExitCode). Check Blackpoint installation diagnostics; no reboot was initiated."
    }
}
catch {
    Write-Output "ERROR: Blackpoint installation failed while $Stage. Exception details are suppressed to protect credentials."
}
finally {
    [Net.ServicePointManager]::SecurityProtocol = $OriginalSecurityProtocol
    if ($TemporaryDirectory) {
        try {
            if (Test-Path -LiteralPath $TemporaryDirectory -ErrorAction Stop) {
                Remove-Item -LiteralPath $TemporaryDirectory -Recurse -Force -ErrorAction Stop
            }
        }
        catch {
            Write-Output 'ERROR: Could not remove the temporary Blackpoint installer directory. Remove leftover Blackpoint-* directories from the system temporary directory.'
            $ExitCode = 1
        }
    }
}

if ($ExitCode -eq 0) {
    Write-Output 'Blackpoint unified agent installation completed successfully.'
}
exit $ExitCode
