function Install-VSCode {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "default"
        Required = $true
        Name     = "vscode"
        Verify   = @{
            Command = "code"
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
