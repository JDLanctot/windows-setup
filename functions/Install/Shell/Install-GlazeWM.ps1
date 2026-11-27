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
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}