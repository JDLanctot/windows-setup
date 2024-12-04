function Install-Alacritty {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type        = "default"
        Required    = $true
        Name        = "alacritty"
        PreInstall  = {
            # Check if installed via MSI
            $msiPath = @(
                "${env:ProgramFiles}\Alacritty\alacritty.exe",
                "${env:LocalAppData}\Programs\Alacritty\alacritty.exe"
            )
            
            foreach ($path in $msiPath) {
                if (Test-Path $path) {
                    $alacrittyDir = Split-Path $path -Parent
                    [Environment]::SetEnvironmentVariable(
                        "Path",
                        "$([Environment]::GetEnvironmentVariable('Path', 'User'));$alacrittyDir",
                        "User"
                    )
                    return $false
                }
            }
            return $true
        }
        PostInstall = {
            $configPath = "$env:USERPROFILE\AppData\Roaming\alacritty"
            if (-not (Test-Path $configPath)) {
                New-Item -ItemType Directory -Path $configPath -Force | Out-Null
            }
            return $true
        }
        Verify      = @{
            Command = "alacritty"
            Config  = @{
                Path = "$env:USERPROFILE\AppData\Roaming\alacritty"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}