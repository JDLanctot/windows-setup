function Initialize-Configuration {
    [CmdletBinding()]
    param()
    
    Write-Log "Loading configuration..." -Level "INFO"
    
    try {
        $configPath = Join-Path $script:CONFIG_ROOT "config.psd1"
        
        # Import and validate configuration
        if (-not (Test-Path $configPath)) {
            throw "Configuration file not found at: $configPath"
        }
        
        $loadedConfig = Import-PowerShellDataFile -Path $configPath -ErrorAction Stop
        
        # Replace placeholders with actual values
        $replacements = @{
            '{USERPROFILE}'  = $env:USERPROFILE
            '{ProgramFiles}' = $env:ProgramFiles
            '{LocalAppData}' = $env:LOCALAPPDATA
            '{AppData}'      = $env:APPDATA
        }

        # Function to recursively process hashtables and arrays
        function Update-ConfigValues {
            param($InputObject)
            
            if ($null -eq $InputObject) {
                return $null
            }
            elseif ($InputObject -is [System.Collections.IDictionary]) {
                $newHash = @{}
                foreach ($key in $InputObject.Keys) {
                    $newHash[$key] = Update-ConfigValues $InputObject[$key]
                }
                return $newHash
            }
            elseif ($InputObject -is [System.Collections.IList]) {
                return @($InputObject | ForEach-Object { Update-ConfigValues $_ })
            }
            elseif ($InputObject -is [string]) {
                $result = $InputObject
                foreach ($placeholder in $replacements.Keys) {
                    $result = $result.Replace($placeholder, $replacements[$placeholder])
                }
                return $result
            }
            else {
                return $InputObject
            }
        }

        # Process the entire configuration
        $loadedConfig = Update-ConfigValues $loadedConfig

        # Validate required sections
        $requiredSections = @(
            'InstallationSteps',
            'ConfigurationHandlers',
            'Paths',
            'Programs',
            'CliTools',
            'InstallationGroups',
            'InstallationProfiles',
            'MinimumRequirements',
            'Dependencies'
        )

        foreach ($section in $requiredSections) {
            if (-not $loadedConfig.ContainsKey($section)) {
                throw "Missing required configuration section: $section"
            }
        }

        # Validate InstallationSteps
        foreach ($step in $loadedConfig.InstallationSteps.Keys) {
            $stepConfig = $loadedConfig.InstallationSteps[$step]
            if (-not $stepConfig.Verification) {
                throw "Missing Verification in InstallationStep: $step"
            }
            if ($step -ne 'custom' -and -not $stepConfig.PackageManager) {
                throw "Missing PackageManager in InstallationStep: $step"
            }
        }

        # MODIFIED: ConfigurationHandlers validation - removed PreInstall requirement
        foreach ($handler in $loadedConfig.ConfigurationHandlers.Keys) {
            $handlerConfig = $loadedConfig.ConfigurationHandlers[$handler]
            # No longer requiring PreInstall property
        }

        # Validate InstallationGroups
        foreach ($group in $loadedConfig.InstallationGroups.Keys) {
            $groupConfig = $loadedConfig.InstallationGroups[$group]
            if (-not $groupConfig.Steps -or $groupConfig.Steps.Count -eq 0) {
                throw "Empty or missing Steps in InstallationGroup: $group"
            }
            if (-not $groupConfig.Order) {
                throw "Missing Order in InstallationGroup: $group"
            }
        }

        # Process and validate paths
        $processedPaths = @{}
        foreach ($key in $loadedConfig.Paths.Keys) {
            $pathConfig = $loadedConfig.Paths[$key]
            
            # Check required fields
            if (-not $pathConfig.ContainsKey('source') -or 
                -not $pathConfig.ContainsKey('target') -or 
                -not $pathConfig.ContainsKey('type') -or 
                -not $pathConfig.ContainsKey('handler')) {
                throw "Invalid path configuration for: $key. Missing required fields (source, target, type, or handler)"
            }

            # Check handler exists
            if (-not $loadedConfig.ConfigurationHandlers.ContainsKey($pathConfig.handler)) {
                throw "Invalid handler '$($pathConfig.handler)' specified for path: $key"
            }

            # Check valid type
            if ($pathConfig.type -notin @('file', 'directory')) {
                throw "Invalid type '$($pathConfig.type)' specified for path: $key. Must be 'file' or 'directory'"
            }

            # Process target path
            $targetPath = switch ($key) {
                'nvim' { Join-Path $env:LOCALAPPDATA $pathConfig.target }
                'bat' { Join-Path $env:APPDATA $pathConfig.target }
                'powershell' { $PROFILE }
                default { Join-Path $env:USERPROFILE $pathConfig.target }
            }

            $processedPaths[$key] = @{
                'source'      = $pathConfig.source
                'target'      = $targetPath
                'type'        = $pathConfig.type
                'handler'     = $pathConfig.handler
                'colorscheme' = $pathConfig.colorscheme
            }
        }

        # Update configuration with processed paths
        $loadedConfig.Paths = $processedPaths

        # Process installation profiles
        foreach ($profileName in $loadedConfig.InstallationProfiles.Keys) {
            $thisProfile = $loadedConfig.InstallationProfiles[$profileName]

            # Handle inheritance
            if ($thisProfile.InheritFrom) {
                $baseProfile = $loadedConfig.InstallationProfiles[$thisProfile.InheritFrom]
                if ($baseProfile) {
                    # Handle group inheritance
                    if ($baseProfile.Groups -and $thisProfile.Groups) {
                        $thisProfile.Groups = @($baseProfile.Groups) + @($thisProfile.Groups) | Select-Object -Unique
                    }
                    elseif ($baseProfile.Groups) {
                        $thisProfile.Groups = $baseProfile.Groups
                    }
                    
                    # Apply MakeAllRequired if specified
                    if ($thisProfile.MakeAllRequired) {
                        foreach ($group in $thisProfile.Groups) {
                            $groupConfig = $loadedConfig.InstallationGroups[$group]
                            if ($groupConfig) {
                                foreach ($step in $groupConfig.Steps) {
                                    $step.Required = $true
                                }
                            }
                        }
                    }
                }
            }
        }

        # Set global config paths so they're accessible to other functions
        $script:CONFIG_PATHS = $loadedConfig.Paths
        
        # Store configuration globally
        $script:Config = $loadedConfig
        
        if (-not $script:Silent) {
            Write-Log "Configuration loaded successfully" -Level "SUCCESS"
        }
        
        return $true
    }
    catch {
        Write-Log "Failed to load configuration: $_" -Level "ERROR"
        throw
    }
}