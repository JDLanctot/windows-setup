function Install-Fzf {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Fzf" }
    if (-not $toolConfig) {
        Write-ColorOutput "Fzf configuration not found" "Error"
        return $false
    }

    $installResult = Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec

    if (-not (Get-Module -ListAvailable -Name PSFzf)) {
        Write-ColorOutput "Installing PSFzf module..." "Status"
        try {
            Install-Module -Name PSFzf -Scope CurrentUser -Force -AllowClobber -ErrorAction Stop
        }
        catch {
            Write-ColorOutput "Failed to install PSFzf module: $_" "Error"
            return $false
        }
    }

    return $installResult -or (Get-Command -Name fzf -ErrorAction SilentlyContinue)
}
