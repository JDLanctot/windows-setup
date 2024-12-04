function Install-Wget {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Wget" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}