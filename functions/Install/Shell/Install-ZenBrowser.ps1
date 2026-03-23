function Install-ZenBrowser {
    [CmdletBinding()]
    param()

    try {
        $zenPaths = @(
            "$env:ProgramFiles\Zen Browser\zen.exe",
            "$env:LOCALAPPDATA\Programs\Zen Browser\zen.exe"
        )

        foreach ($path in $zenPaths) {
            if (Test-Path $path) {
                Write-ColorOutput "Zen Browser is already installed" "Status"
                Save-InstallationState -Component "ZenBrowser" | Out-Null
                return $true
            }
        }

        if (-not (Get-Command -Name winget -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "Winget is required to install Zen Browser" "Error"
            return $false
        }

        Write-ColorOutput "Installing Zen Browser via Winget..." "Status"
        & winget install --id Zen-Team.Zen-Browser -e --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Winget install failed with exit code $LASTEXITCODE"
        }

        foreach ($path in $zenPaths) {
            if (Test-Path $path) {
                Save-InstallationState -Component "ZenBrowser" | Out-Null
                return $true
            }
        }

        Write-ColorOutput "Zen Browser install finished, but executable was not found in expected paths." "Warning"
        return $true
    }
    catch {
        Resolve-Error -ErrorRecord $_ -ComponentName "Zen Browser" -Operation "Installation"
        return $false
    }
}
