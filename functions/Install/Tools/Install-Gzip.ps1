function Install-Gzip {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Gzip" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}