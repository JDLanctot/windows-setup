function Install-Dotfiles {
    [CmdletBinding()]
    param()

    try {
        Write-ColorOutput "Setting up dotfiles..." "Status"
        
        $tempPath = Join-Path $env:TEMP "dotfiles"
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Recurse -Force
        }

        # Clone dotfiles repository
        git clone https://github.com/JDLanctot/dotfiles.git $tempPath
        
        if (-not (Test-Path $tempPath)) {
            Write-ColorOutput "Failed to clone dotfiles repository" "Error"
            return $false
        }
        
        $success = $true
        if ($script:CONFIG_PATHS) {
            foreach ($configName in $script:CONFIG_PATHS.Keys) {
                Write-ColorOutput "Installing ${configName} configuration..." "Status"
                if (-not (Initialize-Dotfile -Name $configName -TempPath $tempPath)) {
                    $success = $false
                    Write-ColorOutput "Failed to install ${configName} configuration" "Error"
                }
            }
        } else {
            Write-ColorOutput "No configuration paths defined" "Error"
            $success = $false
        }
        
        # Clean up
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Recurse -Force
        }
        
        return $success
    }
    catch {
        Write-ColorOutput "Failed to install dotfiles: $_" "Error"
        if (Test-Path $tempPath) {
            Remove-Item $tempPath -Recurse -Force
        }
        return $false
    }
}