function Install-VSCode {
    [CmdletBinding()]
    param()

    try {
        $installSpec = @{
            Type     = "default"
            Required = $true
            Name     = "vscode"
            Verify   = @{
                Command = "code"
            }
        }

        $null = Install-Component -Name $installSpec.Name -InstallSpec $installSpec
        return Install-VSCodeLatex
    }
    catch {
        Write-ColorOutput "Failed to install VS Code: $_" 'Error'
        return $false
    }
}
