function Install-PowerShell {
    [CmdletBinding()]
    param()

    # Check if PowerShell Core is already installed first
    if (Get-Command -Name pwsh -ErrorAction SilentlyContinue) {
        Write-ColorOutput "PowerShell Core is already installed" "Status"
        
        # Use Save-InstallationState instead of Update-InstallationState
        Save-InstallationState -Component "powershell-core"
        return $true
    }

    # Original install logic
    $installSpec = @{
        Type     = "default"
        Required = $true
        Name     = "powershell-core"
        Alias    = "pwsh"
        Verify   = @{
            Command = "pwsh"
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
