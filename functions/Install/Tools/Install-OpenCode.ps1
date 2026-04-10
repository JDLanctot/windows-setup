function Install-OpenCode {
    [CmdletBinding()]
    param()

    if (Get-Command -Name opencode -ErrorAction SilentlyContinue) {
        return $true
    }

    $nativeInstalled = $false

    if (Get-Command -Name winget -ErrorAction SilentlyContinue) {
        $wingetIds = @("OpenCode.OpenCode", "opencode.opencode")
        foreach ($wingetId in $wingetIds) {
            try {
                Write-ColorOutput "Trying native winget package $wingetId..." "Status"
                & winget install --id $wingetId -e --accept-source-agreements --accept-package-agreements
                if ($LASTEXITCODE -eq 0 -and (Get-Command -Name opencode -ErrorAction SilentlyContinue)) {
                    $nativeInstalled = $true
                    break
                }
            }
            catch {
            }
        }
    }

    if (-not $nativeInstalled -and (Get-Command -Name choco -ErrorAction SilentlyContinue)) {
        $chocoPackages = @("opencode")
        foreach ($chocoPackage in $chocoPackages) {
            try {
                Write-ColorOutput "Trying native Chocolatey package $chocoPackage..." "Status"
                & choco install $chocoPackage --yes --no-progress
                if ($LASTEXITCODE -eq 0 -and (Get-Command -Name opencode -ErrorAction SilentlyContinue)) {
                    $nativeInstalled = $true
                    break
                }
            }
            catch {
            }
        }
    }

    if ($nativeInstalled) {
        return $true
    }

    if (-not (Get-Command -Name npm -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "NPM is required for OpenCode fallback, installing Node.js..." "Status"
        if (-not (Install-Node)) {
            return $false
        }
    }

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "OpenCode" }
    if (-not $toolConfig) {
        Write-ColorOutput "OpenCode configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
