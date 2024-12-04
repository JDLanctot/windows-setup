function Install-Node {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type        = "default"
        Required    = $false
        Name        = "nodejs-lts"
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