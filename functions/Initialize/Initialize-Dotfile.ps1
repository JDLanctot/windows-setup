function Initialize-Dotfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [string]$TempPath
    )

    try {
        if (-not $CONFIG_PATHS.ContainsKey($Name)) {
            Write-ColorOutput "Unknown configuration: ${Name}" "Error"
            return $false
        }

        $config = $CONFIG_PATHS[$Name]
        $handler = $script:Config.ConfigurationHandlers[$config.handler ?? 'default']
        if (-not $handler) {
            throw "No configuration handler found for $Name"
        }

        # Build InstallSpec from configuration
        $installSpec = @{
            Type          = 'custom'
            Required      = $false
            Name          = "${Name}-config"
            PreInstall    = $handler.PreInstall
            CustomInstall = {
                $sourcePath = Join-Path $TempPath $config.source
                $targetPath = Join-Path $env:USERPROFILE $config.target

                # Ensure target directory exists
                $targetDir = Split-Path $targetPath -Parent
                if (-not (Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                if (-not (Test-Path $sourcePath)) {
                    Write-ColorOutput "${Name} configuration not found in dotfiles" "Error"
                    return $false
                }

                # Handle file copying based on handler type
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
                            Copy-Item $sourceFilePath $targetFilePath -Force
                        }
                        else {
                            Write-ColorOutput "Warning: Source file not found: $sourceFilePath" "Warning"
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
                        Copy-Item $sourcePath $targetPath -Recurse -Force
                    }
                    else {
                        Copy-Item $sourcePath $targetPath -Force
                    }
                }

                return $true
            }
            Verify        = @{
                Script = {
                    $targetPath = Join-Path $env:USERPROFILE $config.target
                    
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
            Write-ColorOutput "${Name} configuration installed" "Success"
        }

        return $result
    }
    catch {
        Handle-Error -ErrorRecord $_ `
            -ComponentName "Configuration-$Name" `
            -Operation "Installation" `
            -Critical:$false
        return $false
    }
}