function Install-Biome {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Biome" }
    if (-not $toolConfig) {
        Write-ColorOutput "Biome configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
