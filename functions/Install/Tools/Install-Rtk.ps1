function Install-Rtk {
    [CmdletBinding()]
    param()

    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Rtk" }
    if (-not $toolConfig) {
        Write-ColorOutput "Rtk configuration not found" "Error"
        return $false
    }

    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}
