function Install-GlazeWM {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type        = "winget"
        Required    = $false
        Name        = "GlazeWM"
        PostInstall = {
            $configPath = "$env:USERPROFILE\.glzr\glazewm"
            if (-not (Test-Path $configPath)) {
                New-Item -ItemType Directory -Path $configPath -Force | Out-Null
            }
            return $true
        }
        Verify      = @{
            Command = "glazewm"
            Config  = @{
                Path = "$env:USERPROFILE\.glzr\glazewm\config.yaml"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}