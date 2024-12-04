function Install-Fd {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Fd" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}