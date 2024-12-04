function Install-Ripgrep {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Ripgrep" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}