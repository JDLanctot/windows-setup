function Install-Julia {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "default"
        Required = $false
        Name     = "julia"
        Verify   = @{
            Command = "julia"
            Config  = @{
                Path = "$env:USERPROFILE\.julia\config\startup.jl"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
