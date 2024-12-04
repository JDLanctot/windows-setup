function Install-Zig {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type        = "default"
        Required    = $true
        Name        = "zig"
        PostInstall = @{
            PathAdd = "C:\ProgramData\chocolatey\bin"
        }
        Verify      = @{
            Command = "zig"
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}