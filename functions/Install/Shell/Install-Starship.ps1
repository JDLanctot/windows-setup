function Install-Starship {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "default"
        Required = $true
        Name     = "starship"
        Alias    = "starship"
        Verify   = @{
            Command = "starship"
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
