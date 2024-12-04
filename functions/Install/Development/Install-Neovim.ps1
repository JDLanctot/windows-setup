function Install-Neovim {
    [CmdletBinding()]
    param()

    $params = @{
        Name               = "Neovim"
        Required           = $true
        PostInstall        = {
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

    return Install-Component @params
}