function Install-Dotfiles {
    [CmdletBinding()]
    param()

    try {
        Write-ColorOutput "Setting up dotfiles..." "Status"
        
        $tempPath = Join-Path $env:TEMP ("dotfiles-" + [guid]::NewGuid())

        # Clone dotfiles repository
        Write-Log "Cloning dotfiles repository to $tempPath" -Level "INFO"
        git clone --depth 1 https://github.com/JDLanctot/dotfiles.git $tempPath
        
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path $tempPath)) {
            Write-ColorOutput "Failed to clone dotfiles repository" "Error"
            return $false
        }
        
        $anySuccess = $false
        if ($script:CONFIG_PATHS) {
            foreach ($configName in $script:CONFIG_PATHS.Keys) {
                Write-ColorOutput "Installing ${configName} configuration..." "Status"
                
                $result = Initialize-Dotfile -Name $configName -TempPath $tempPath
                if ($result) {
                    $anySuccess = $true
                }
                else {
                    Write-ColorOutput "Failed to install ${configName} configuration" "Error"
                }
            }
        } else {
            Write-ColorOutput "No configuration paths defined" "Error"
            $anySuccess = $false
        }
        
        # Return true if at least one configuration was successful
        return $anySuccess
    }
    catch {
        Write-Log "Failed to install dotfiles: $_" -Level "ERROR"
        return $false
    }
    finally {
        if ($tempPath -and (Test-Path -LiteralPath $tempPath)) {
            Remove-Item -LiteralPath $tempPath -Recurse -Force
        }
    }
}
