function Install-7zip {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "7zip" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}