function Install-Firefox {
    [CmdletBinding()]
    param()

    try {
        $firefoxPaths = @(
            "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
            "$env:ProgramFiles(x86)\Mozilla Firefox\firefox.exe"
        )

        foreach ($path in $firefoxPaths) {
            if (Test-Path $path) {
                Write-ColorOutput "Firefox is already installed" "Status"
                Save-InstallationState -Component "Firefox" | Out-Null
                return $true
            }
        }

        if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "Winget is required to install Firefox" "Error"
            return $false
        }

        Write-ColorOutput "Installing Firefox via Winget..." "Status"
        & winget install --id Mozilla.Firefox -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Winget install failed with exit code $LASTEXITCODE"
        }

        Save-InstallationState -Component "Firefox" | Out-Null
        return $true
    }
    catch {
        Resolve-Error -ErrorRecord $_ -ComponentName "Firefox" -Operation "Installation"
        return $false
    }
}
