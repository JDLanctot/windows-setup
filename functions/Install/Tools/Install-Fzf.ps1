function Install-Fzf {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Fzf" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}