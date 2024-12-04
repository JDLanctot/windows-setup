function Install-Ag {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Ag" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}