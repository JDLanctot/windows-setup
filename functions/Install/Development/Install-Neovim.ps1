function Install-Neovim {
    [CmdletBinding()]
    param()

    # Check if Neovim is already installed
    if (Get-Command -Name nvim -ErrorAction SilentlyContinue) {
        Write-ColorOutput "Neovim is already installed" "Status"
        
        # Register as installed
        Save-InstallationState -Component "Neovim"
        return $true
    }

    $params = @{
        Name        = "Neovim"
        PostInstall = {
            # Add Neovim to Path if not already there
            $neovimPath = "C:\tools\neovim\Neovim\bin"
            $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
            if ($userPath -notlike "*$neovimPath*") {
                [Environment]::SetEnvironmentVariable(
                    "Path",
                    "$userPath;$neovimPath",
                    "User"
                )
                return $true
            }
            return $true
        }
        CustomVerification = {
            $hasCommand = Get-Command -Name nvim -ErrorAction SilentlyContinue
            $configPath = "$env:LOCALAPPDATA\nvim\init.lua"
            return ($hasCommand -and (Test-Path $configPath))
        }
    }

    $installSpec = @{
        Type        = "default"
        Required    = $true
        Name        = "neovim"
        Alias       = "nvim"
        PostInstall = $params.PostInstall
        Verify      = @{
            Command = "nvim"
            Script  = $params.CustomVerification
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}