function Install-Node {
    [CmdletBinding()]
    param()

    # Check if Node.js is already installed
    if (Get-Command -Name node -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Node.js is already installed" "Status"
        
        # Check for PNPM and install if necessary
        if (-not (Get-Command -Name pnpm -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "Installing PNPM..." "Status"
            npm install -g pnpm
        }
        
        # Install neovim package if not present
        if (-not (Get-Command -Name neovim -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "Installing Neovim package for Node.js..." "Status"
            npm install -g neovim
        }
        
        # Update installation state
        Save-InstallationState -Component "nodejs-lts"
        return $true
    }

    # Installation spec for Chocolatey
    $installSpec = @{
        Type        = "default"
        Required    = $false
        Name        = "nodejs-lts"  # This is the Chocolatey package name
        Alias       = "node"        # This is the command to check for
        PostInstall = {
            # Install pnpm if not present
            if (-not (Get-Command -Name pnpm -ErrorAction SilentlyContinue)) {
                npm install -g pnpm
            }
            # Install neovim package if not present
            if (-not (Get-Command -Name neovim -ErrorAction SilentlyContinue)) {
                npm install -g neovim
            }
            return $true
        }
        Verify      = @{
            Command = "node"
            Config  = @{
                Check = {
                    (Get-Command -Name node -ErrorAction SilentlyContinue) -and 
                    (Get-Command -Name pnpm -ErrorAction SilentlyContinue)
                }
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}