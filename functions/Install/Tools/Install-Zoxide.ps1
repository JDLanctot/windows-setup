function Install-Zoxide {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Zoxide" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}