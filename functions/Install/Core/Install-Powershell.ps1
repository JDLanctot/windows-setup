function Install-PowerShell {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type               = "default"
        Name               = "powershell-core"
        Required           = $true
        CustomVerification = {
            $hasCommand = Get-Command -Name choco -ErrorAction SilentlyContinue
            return $null -ne $hasCommand
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
