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
        
        $allSucceeded = $true
        if ($script:CONFIG_PATHS) {
            foreach ($configName in $script:CONFIG_PATHS.Keys) {
                Write-ColorOutput "Installing ${configName} configuration..." "Status"
                
                $result = Initialize-Dotfile -Name $configName -TempPath $tempPath
                if (-not $result) {
                    $allSucceeded = $false
                    Write-ColorOutput "Failed to install ${configName} configuration" "Error"
                }
            }
        } else {
            Write-ColorOutput "No configuration paths defined" "Error"
            $allSucceeded = $false
        }
        
        return $allSucceeded
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
