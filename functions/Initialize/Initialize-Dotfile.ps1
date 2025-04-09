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
        Write-Log "Processing config for $Name with target path $($config.target)" -Level "DEBUG"
        
        $handler = $script:Config.ConfigurationHandlers[$config.handler ?? 'default']
        if (-not $handler) {
            throw "No configuration handler found for $Name"
        }

        # Get source and target paths
        $sourcePath = Join-Path $TempPath $config.source
        $targetPath = $config.target
        $targetDir = Split-Path $targetPath -Parent

        # Create target directory if it doesn't exist
        if (-not (Test-Path $targetDir)) {
            Write-Log "Creating directory for configuration: $targetDir" -Level "INFO"
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }

        # Check source path exists
        if (-not (Test-Path $sourcePath)) {
            Write-Log "Source path not found: $sourcePath" -Level "WARN"
            # Skip instead of failing for missing config files
            # This allows the installation to continue with available configs
            return $false
        }

        $success = $false
        
        try {
            # Use file-specific copying if specified
            if ($handler.PostInstall.Files) {
                Write-Log "Using file-specific copy for $Name" -Level "DEBUG"
                $filesCopied = 0
                
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

                    Write-Log "Processing file: $sourceFile -> $targetFile" -Level "DEBUG"
                    
                    if (Test-Path $sourceFilePath) {
                        # Create target directory if it doesn't exist
                        $targetFileDir = Split-Path $targetFilePath -Parent
                        if (-not (Test-Path $targetFileDir)) {
                            Write-Log "Creating directory: $targetFileDir" -Level "INFO"
                            New-Item -ItemType Directory -Path $targetFileDir -Force | Out-Null
                        }
                        
                        Copy-Item $sourceFilePath $targetFilePath -Force
                        Write-Log "Copied $sourceFile to $targetFilePath" -Level "INFO"
                        $filesCopied++
                    }
                    else {
                        Write-Log "Warning: Source file not found: $sourceFilePath" -Level "WARN"
                    }
                }
                
                $success = ($filesCopied -gt 0)
            }
            else {
                # Default copy behavior
                $copyMode = $handler.CopyMode ?? $config.type
                Write-Log "Using copy mode: $copyMode for $Name" -Level "DEBUG"
                
                if ($copyMode -eq 'directory') {
                    # If target exists, remove it first
                    if (Test-Path $targetPath) {
                        Remove-Item $targetPath -Recurse -Force
                    }
                    
                    # Ensure parent directory exists
                    $targetParent = Split-Path $targetPath -Parent
                    if (-not (Test-Path $targetParent)) {
                        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                    }
                    
                    Copy-Item $sourcePath $targetPath -Recurse -Force
                    Write-Log "Copied directory $sourcePath to $targetPath" -Level "INFO"
                    $success = $true
                }
                else {
                    # Ensure parent directory exists
                    $targetParent = Split-Path $targetPath -Parent
                    if (-not (Test-Path $targetParent)) {
                        New-Item -ItemType Directory -Path $targetParent -Force | Out-Null
                    }
                    
                    Copy-Item $sourcePath $targetPath -Force
                    Write-Log "Copied file $sourcePath to $targetPath" -Level "INFO"
                    $success = $true
                }
            }
            
            # Verify the installation
            if ($success) {
                # Basic verification - check if target exists
                if (Test-Path $targetPath) {
                    Write-Log "${Name} configuration installed" -Level "SUCCESS"
                    return $true
                }
                else {
                    Write-Log "Target path not found after installation: $targetPath" -Level "ERROR"
                    return $false
                }
            }
            else {
                Write-Log "No files were copied for ${Name}" -Level "ERROR"
                return $false
            }
        }
        catch {
            Write-Log "Error during file operations for ${Name}: $_" -Level "ERROR"
            return $false
        }
    }
    catch {
        Write-Log "Failed to initialize dotfile for ${Name}: $_" -Level "ERROR"
        Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level "DEBUG"
        return $false
    }
}