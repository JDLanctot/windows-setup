function Install-GitHubCli {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "GitHubCli" }
    if (-not $toolConfig) {
        Write-ColorOutput "GitHubCli configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
