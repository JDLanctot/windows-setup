function Install-Bat {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Bat" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}