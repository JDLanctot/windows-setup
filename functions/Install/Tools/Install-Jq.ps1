function Install-Jq {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Jq" }
    if (-not $toolConfig) {
        Write-ColorOutput "Jq configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
