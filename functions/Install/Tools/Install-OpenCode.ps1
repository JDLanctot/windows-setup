function Install-OpenCode {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "OpenCode" }
    if (-not $toolConfig) {
        Write-ColorOutput "OpenCode configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
