function Install-Starship {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "default"
        Required = $true
        Name     = "starship"
        Verify   = @{
            Command = "starship"
            Config  = @{
                Path    = "$env:USERPROFILE\.starship\starship.toml"
                Pattern = "Invoke-Expression \(&starship init powershell\)"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}