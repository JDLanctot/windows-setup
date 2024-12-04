function Install-Eza {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Eza" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}