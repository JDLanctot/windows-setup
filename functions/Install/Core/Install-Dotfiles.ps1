function Install-Dotfiles {
    [CmdletBinding()]
    param()

    $params = @{
        Name               = "Dotfiles"
        Required           = $true
        CustomInstall      = {
            $tempPath = Join-Path $env:TEMP "dotfiles"
            if (Test-Path $tempPath) {
                Remove-Item $tempPath -Recurse -Force
            }

            git clone https://github.com/JDLanctot/dotfiles.git $tempPath
            
            try {
                $success = $true
                foreach ($configName in $CONFIG_PATHS.Keys) {
                    Write-ColorOutput "Installing ${configName} configuration..." "Status"
                    if (-not (Initialize-Dotfile -Name $configName -TempPath $tempPath)) {
                        $success = $false
                        Write-ColorOutput "Failed to install ${configName} configuration" "Error"
                    }
                }
                return $success
            }
            finally {
                if (Test-Path $tempPath) {
                    Remove-Item $tempPath -Recurse -Force
                }
            }
        }
        CustomVerification = {
            $success = $true
            foreach ($config in $CONFIG_PATHS.Keys) {
                $path = $CONFIG_PATHS[$config].target
                if (-not (Test-Path $path)) {
                    $success = $false
                    break
                }
            }
            return $success
        }
    }

    return Install-Component @params
}