function Install-Sst {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Sst" }
    if (-not $toolConfig) {
        Write-ColorOutput "Sst configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.InstallSpec.Package -InstallSpec $toolConfig.InstallSpec
}
