function Install-Unzip {
    [CmdletBinding()]
    param()
    
    $toolConfig = $script:Config.CliTools | Where-Object { $_.Name -eq "Unzip" }
    return Install-Component -Name $toolConfig.Name -InstallSpec $toolConfig.InstallSpec
}