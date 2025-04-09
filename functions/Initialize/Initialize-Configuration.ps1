function Initialize-Dotfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$TempPath
    )

    try {
        if (-not $script:CONFIG_PATHS -or -not $script:CONFIG_PATHS.ContainsKey($Name)) {
            Write-Log "Unknown configuration: ${Name}" -Level "ERROR"
            return $false
        }

        $config = $script:CONFIG_PATHS[$Name]
        $handler = $script:Config.ConfigurationHandlers[$config.handler ?? 'default']
        if (-not $handler) {
            throw "No configuration handler found for $Name"
        }

        # Build InstallSpec from configuration
        $installSpec = @{
            Type          = 'custom'
            Required      = $false
            Name          = "${Name}-config"
            # DO NOT use handler.PreInstall directly - that's causing the prompt
            CustomInstall = {
                # Note: Within ScriptBlocks, we need to use Write-Log instead of Write-ColorOutput
                # since functions defined in the parent scope aren't available in ScriptBlock context
                $sourcePath = Join-Path $TempPath $config.source
                $targetPath = $config.target

                # Ensure target directory exists - handle this here instead of in PreInstall
                $targetDir = Split-Path $targetPath -Parent
                if (-not (Test-Path $targetDir)) {
                    Write-Log "Creating directory for configuration: $targetDir" -Level "INFO"
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                # Here we would have used PreInstall but we'll skip it since we've already created the directory

                if (-not (Test-Path $sourcePath)) {
                    Write-Log "Configuration not found in dotfiles at $sourcePath" -Level "ERROR"
                    return $false
                }

                # Handler-specific file copying logic continues as in the original
                if ($handler.PostInstall.Files) {
                    foreach ($file in $handler.PostInstall.Files) {
                        $sourceFile = $file.Source
                        $targetFile = $file.Target

                        # Replace variables in file names
                        if ($config.colorscheme) {
                            $sourceFile = $sourceFile.Replace('{colorscheme}', $config.colorscheme)
                            $targetFile = $targetFile.Replace('{colorscheme}', $config.colorscheme)
                        }

                        $sourceFilePath = Join-Path $sourcePath $sourceFile
                        $targetFilePath = Join-Path $targetPath $targetFile

                        if (Test-Path $sourceFilePath) {
                            # Create target directory if it doesn't exist
                            $targetFileDir = Split-Path $targetFilePath -Parent
                            if (-not (Test-Path $targetFileDir)) {
                                Write-Log "Creating directory: $targetFileDir" -Level "INFO"
                                New-Item -ItemType Directory -Path $targetFileDir -Force | Out-Null
                            }
                            
                            Copy-Item $sourceFilePath $targetFilePath -Force
                            Write-Log "Copied $sourceFile to $targetFilePath" -Level "INFO"
                        }
                        else {
                            Write-Log "Warning: Source file not found: $sourceFilePath" -Level "WARN"
                        }
                    }
                }
                else {
                    # Default copy behavior
                    $copyMode = $handler.CopyMode ?? $config.type
                    if ($copyMode -eq 'directory') {
                        if (Test-Path $targetPath) {
                            Remove-Item $targetPath -Recurse -Force
                        }
                        
                        # Create parent directory if needed
                        $targetParent = Split-Path $targetPath -Parent
                        if (-not (Test-Path $targetParent)) {
                            Write-Log "Creating parent directory: $targetParent" -Level "INFO"
                            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                        }
                        
                        Copy-Item $sourcePath $targetPath -Recurse -Force
                        Write-Log "Copied directory $sourcePath to $targetPath" -Level "INFO"
                    }
                    else {
                        # Create parent directory if needed
                        $targetParent = Split-Path $targetPath -Parent
                        if (-not (Test-Path $targetParent)) {
                            Write-Log "Creating parent directory: $targetParent" -Level "INFO"
                            New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                        }
                        
                        Copy-Item $sourcePath $targetPath -Force
                        Write-Log "Copied file $sourcePath to $targetPath" -Level "INFO"
                    }
                }

                return $true
            }
            Verify        = @{
                Script = {
                    $targetPath = $config.target
                    
                    # Basic path verification
                    if (-not (Test-Path $targetPath)) {
                        return $false
                    }

                    # Handler-specific verification
                    if ($handler.PostInstall.Files) {
                        foreach ($file in $handler.PostInstall.Files) {
                            $targetFile = $file.Target
                            if ($config.colorscheme) {
                                $targetFile = $targetFile.Replace('{colorscheme}', $config.colorscheme)
                            }
                            
                            $targetFilePath = Join-Path $targetPath $targetFile
                            if (-not (Test-Path $targetFilePath)) {
                                return $false
                            }
                        }
                    }

                    return $true
                }
            }
        }

        # Install using our standard component installation system
        $result = Install-Component -Name $installSpec.Name -InstallSpec $installSpec
        
        if ($result) {
            Write-Log "${Name} configuration installed" -Level "SUCCESS"
        }

        return $result
    }
    catch {
        Write-Log "Failed to initialize dotfile for ${Name}: $_" -Level "ERROR"
        return $false
    }
}