function Install-Ruff {
    [CmdletBinding()]
    param()

    if (-not (Get-Command -Name uv -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "uv is required before installing ruff" "Error"
        return $false
    }

    if (Get-Command -Name ruff -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Ruff is already installed" "Status"
        return $true
    }

    try {
        Write-ColorOutput "Installing ruff via uv tool..." "Status"
        & uv tool install ruff
        if ($LASTEXITCODE -ne 0) {
            throw "uv tool install ruff failed with exit code $LASTEXITCODE"
        }

        RefreshPath
        return $null -ne (Get-Command -Name ruff -ErrorAction SilentlyContinue)
    }
    catch {
        Write-ColorOutput "Failed to install ruff: $_" "Error"
        return $false
    }
}
