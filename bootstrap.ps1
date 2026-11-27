[CmdletBinding()]
param(
    [AllowNull()]
    [AllowEmptyString()]
    [string]$InstallationType
)

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

function Resolve-InstallationType {
    param(
        [string]$RequestedInstallationType,
        [bool]$WasExplicitlyProvided
    )

    $validInstallationTypes = @('Minimal', 'Standard', 'Full', 'DataScience', 'WebDevelopment', 'JuliaDevelopment', 'Custom')

    $resolvedInstallationType = $RequestedInstallationType
    if ([string]::IsNullOrWhiteSpace($resolvedInstallationType) -and [string]::IsNullOrWhiteSpace($env:WINDOWS_SETUP_PROFILE) -eq $false) {
        $resolvedInstallationType = $env:WINDOWS_SETUP_PROFILE
    }

    if ([string]::IsNullOrWhiteSpace($resolvedInstallationType)) {
        $resolvedInstallationType = 'Standard'
    }

    if ($resolvedInstallationType -notin $validInstallationTypes) {
        throw "Invalid installation type '$resolvedInstallationType'. Valid values: $($validInstallationTypes -join ', ')"
    }

    return $resolvedInstallationType
}

$resolvedInstallationType = Resolve-InstallationType -RequestedInstallationType $InstallationType -WasExplicitlyProvided:$PSBoundParameters.ContainsKey('InstallationType')

# Keep downloads separate from existing checkouts and simultaneous setup runs.
$setupDir = Join-Path $env:TEMP ("windows-setup-" + [guid]::NewGuid())
$null = New-Item -ItemType Directory -Path $setupDir -ErrorAction Stop
try {
    $zipFile = Join-Path $setupDir 'windows-setup.zip'
    Invoke-WebRequest -Uri 'https://github.com/JDLanctot/windows-setup/archive/refs/heads/main.zip' -OutFile $zipFile -ErrorAction Stop
    Expand-Archive -LiteralPath $zipFile -DestinationPath $setupDir -ErrorAction Stop
    $entry = Join-Path $setupDir 'windows-setup-main/install.ps1'
    if ($resolvedInstallationType -eq 'Custom') {
        & $entry -InstallationType Custom -Interactive
    }
    else {
        & $entry -InstallationType $resolvedInstallationType
    }
}
finally {
    Remove-Item -LiteralPath $setupDir -Recurse -Force
}
