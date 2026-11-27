function Invoke-ChocolateyInstall {
    param([Parameter(Mandatory)][string[]]$InstallArgs)

    # Chocolatey uses nonzero native exit codes for successful installs needing a restart.
    $PSNativeCommandUseErrorActionPreference = $false
    $output = & choco install @InstallArgs 2>&1
    $code = $LASTEXITCODE
    Write-Log "Chocolatey output: $($output -join [Environment]::NewLine)" -Level DEBUG
    Assert-NoInstallerRestart -Manager Chocolatey -Code $code
    if ($code -ne 0) {
        throw "Chocolatey installation failed with exit code: $code`nOutput: $($output -join [Environment]::NewLine)"
    }
}
