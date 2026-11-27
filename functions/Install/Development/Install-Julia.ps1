function Install-Julia {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "default"
        Required = $false
        Name     = "julia"
        Verify   = @{
            Command = "julia"
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
