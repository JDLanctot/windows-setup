function Start-Installation {
    [CmdletBinding()]
    param(
        [ValidateSet('Minimal', 'Standard', 'Full', 'DataScience', 'WebDevelopment', 'JuliaDevelopment', 'Custom')]
        [string]$InstallationType = 'Standard',
        [switch]$Force,
        [switch]$NoBackup,
        [switch]$Silent,
        [switch]$Interactive,
        [string[]]$CustomComponents,
        [string]$LogPath,
        [switch]$Initialize
    )
    
    try {
        $script:Silent = $Silent
        if ($LogPath) { $script:SCRIPT_LOG_PATH = $LogPath }
        
        if (-not $Silent) {
            Write-Host "`n" # Add initial spacing
        }
        
        # Initialize installation state
        $initResult = Initialize-Installation -InstallationType $InstallationType -Force:$Force
        $configToUse = if ($script:Config) { $script:Config } else { $initResult.Config }
        if (-not $configToUse) { throw "No configuration available" }
        
        # If Initialize switch is specified, just return the configuration
        if ($Initialize) {
            return @{
                Config = $configToUse
            }
        }
        
        # Initialize results tracking
        $results = @{
            Pending         = @()
            RebootRequired  = $false
            Total           = 0
            Successful      = [System.Collections.ArrayList]::new()
            Failed          = [System.Collections.ArrayList]::new()
            Skipped         = [System.Collections.ArrayList]::new()
            ComponentStatus = @{}  # Initialize ComponentStatus
        }

        # Handle custom installation type
        if ($InstallationType -eq 'Custom') {
            if (-not $CustomComponents -or $CustomComponents.Count -eq 0) {
                throw "Custom installation selected but no components specified"
            }
            
            Write-Log "Processing custom installation with components: $($CustomComponents -join ', ')" -Level "INFO"
            
            # Create all steps from all groups
            $allSteps = [System.Collections.ArrayList]::new()
            
            # Process all installation groups to find components
            foreach ($groupName in $configToUse.InstallationGroups.Keys) {
                $group = $configToUse.InstallationGroups[$groupName]
                if (-not $group) { continue }
                
                foreach ($step in $group.Steps) {
                    if (-not $step.Name) { continue }
                    
                    # Include if required or specifically selected
                    if (($group.Required -and $step.Required) -or $CustomComponents -contains $step.Name) {
                        $componentSpec = @{
                            Name     = $step.Name
                            Function = $step.Function
                            Group    = $groupName
                            Order    = $group.Order
                            Required = $step.Required -eq $true
                        }
                        
                        [void]$allSteps.Add($componentSpec)
                    }
                }
            }
            
            # Add special component "Dotfiles" if selected
            if ($CustomComponents -contains "Dotfiles") {
                [void]$allSteps.Add(@{
                    Name     = "Dotfiles"
                    Function = "Install-Dotfiles"
                    Group    = "Core"
                    Order    = 99
                    Required = $false
                })
            }
            

        }
        else {
            # Get installation profile for predefined types
            $thisProfile = $configToUse.InstallationProfiles[$InstallationType]
            if (-not $thisProfile) { throw "Invalid installation profile: $InstallationType" }

            # Get all available groups for this profile
            $availableGroups = @()
            
            # Add groups from the profile
            if ($thisProfile.Groups) {
                $availableGroups += $thisProfile.Groups
            }
            
            # Add inherited groups
            if ($thisProfile.InheritFrom) {
                $baseProfile = $configToUse.InstallationProfiles[$thisProfile.InheritFrom]
                if ($baseProfile -and $baseProfile.Groups) {
                    $availableGroups += $baseProfile.Groups
                }
            }
            
            # Remove duplicates
            $availableGroups = $availableGroups | Select-Object -Unique

            # Add debug logging for troubleshooting
            Write-Log "Available groups for profile ${InstallationType}: $($availableGroups -join ', ')" -Level "DEBUG"

            # If interactive mode is requested, provide clear instructions
            if ($Interactive) {
                Write-Host "`n╔════════════════════════════════════════════════════════════════╗"
                Write-Host "║            Interactive Component Selection Mode                 ║"
                Write-Host "╠════════════════════════════════════════════════════════════════╣"
                Write-Host "║ You'll be prompted to select which components to install.       ║"
                Write-Host "║ Required components will be installed automatically.            ║"
                Write-Host "╚════════════════════════════════════════════════════════════════╝"
                
                $selectedComponents = Select-InstallationComponents -ProfileName $InstallationType -Config $configToUse
                if ($selectedComponents.Count -eq 0) {
                    Write-ColorOutput "No components selected. Installation cancelled." "Warning"
                    return $false
                }
            }

            # Get all steps from groups
            $allSteps = [System.Collections.ArrayList]::new()
            
            # Add group-based installations
            foreach ($groupName in $availableGroups) {
                $group = $configToUse.InstallationGroups[$groupName]
                if (-not $group) { 
                    Write-Log "Group not found in configuration: $groupName" -Level "WARN"
                    continue 
                }
                
                Write-Log "Processing group: $groupName with $($group.Steps.Count) steps" -Level "DEBUG"
                
                foreach ($step in $group.Steps) {
                    if (-not $step.Name) {
                        Write-Log "Step without a name found in group $groupName" -Level "WARN"
                        continue
                    }
                    
                    Write-Log "Processing step: $($step.Name) from group $groupName" -Level "DEBUG"
                    
                    $componentSpec = @{
                        Name        = $step.Name
                        Function    = $step.Function
                        Group       = $groupName
                        Order       = $group.Order
                        Required    = $step.Required -eq $true
                    }
                    
                    # Make all components required if profile specifies it
                    if ($thisProfile.MakeAllRequired) {
                        $componentSpec.Required = $true
                    }
                    
                    # If interactive and component not selected, skip
                    if ($Interactive -and $step.Name -notin $selectedComponents -and -not $step.Required) {
                        Write-Log "Skipping step $($step.Name) (not selected)" -Level "DEBUG"
                        continue
                    }
                    
                    [void]$allSteps.Add($componentSpec)
                    Write-Log "Added step: $($step.Name)" -Level "DEBUG"
                }
            }

            # Add additional steps from profile
            if ($thisProfile.AdditionalSteps) {
                Write-Log "Processing additional steps from profile" -Level "DEBUG"
                
                foreach($step in $thisProfile.AdditionalSteps) {
                    if (-not $step.Name) {
                        Write-Log "Additional step without a name found" -Level "WARN"
                        continue
                    }
                    
                    Write-Log "Processing additional step: $($step.Name)" -Level "DEBUG"
                    
                    # Skip if interactive and not selected
                    if ($Interactive -and $step.Name -notin $selectedComponents -and -not $step.Required) {
                        Write-Log "Skipping additional step $($step.Name) (not selected)" -Level "DEBUG"
                        continue
                    }
                    
                    [void]$allSteps.Add(@{ Name = $step.Name; Function = $step.Function; Required = $step.Required; Group = 'Additional'; Order = 99 })
                    Write-Log "Added additional step: $($step.Name)" -Level "DEBUG"
                }
            }

        }

        # Preserve declaration order within groups and run each installer once.
        $seen = @{}
        $orderedSteps = @(foreach ($step in ($allSteps | Sort-Object { $_.Order } -Stable)) {
            if ($seen.ContainsKey($step.Function)) {
                $seen[$step.Function].Required = $seen[$step.Function].Required -or $step.Required
            }
            else {
                $seen[$step.Function] = $step
                $step
            }
        })
        $results.Total = $orderedSteps.Count

        # In Start-Installation function
        $useProgressUI = $false
        try {
            if ([type]::GetType('ProgressUI')) {
                $progressUI = New-Object ProgressUI
                $useProgressUI = $true
                Write-Log "ProgressUI initialized successfully" -Level "DEBUG"
            }
        }
        catch {
            Write-Log "Progress UI not available, using simple progress: $_" -Level "WARN"
            $useProgressUI = $false
        }

        # The rest of the function remains the same but with more robust error handling
        # and logging to help diagnose issues...
        
        # Serial processing (simplified for clarity)
        $current = 0
        
        foreach ($step in $orderedSteps) {
            # Skip null steps
            if (-not $step) {
                Write-Log "Null step encountered in processing" -Level "WARN"
                continue
            }
            
            $current++
            $stepName = $step.Name
            
            Write-Log "Processing step $current of $($orderedSteps.Count): $stepName" -Level "INFO"
            
            # Display progress
            Write-ColorOutput "[$current/$($results.Total)] Processing: $stepName" "Status"
            
            # Update progress before installation
            if ($useProgressUI -and $progressUI) {
                # Create a safe copy of the status
                $currentStatus = @{}
                foreach ($key in $results.ComponentStatus.Keys) {
                    $currentStatus[$key] = $results.ComponentStatus[$key]
                }
                
                # Set current step status
                $currentStatus[$stepName] = "Installing"
                
                try {
                    $progressUI.Show(
                        "Installing $($step.Group) Components",
                        $current,
                        $results.Total,
                        $currentStatus
                    )
                }
                catch {
                    Write-Log "Error showing progress: $_" -Level "WARN"
                    $useProgressUI = $false
                }
            }
            else {
                Write-Progress -Activity "Installing Components" `
                    -Status "Processing: $stepName" `
                    -PercentComplete ($current / [Math]::Max(1, $results.Total) * 100)
            }
            
            # Check dependencies
            $canInstall = $true
            $dependency = $configToUse.Dependencies[$stepName]
            
            if ($dependency -and $dependency.Requires) {
                foreach ($requiredComp in $dependency.Requires) {
                    if (-not (Test-InstallationState $requiredComp)) {
                        Write-ColorOutput "Dependency $requiredComp not installed for $stepName" "Warning"
                        $canInstall = $false
                        break
                    }
                }
            }
            
            if (-not $canInstall) {
                if ($step.Required) { throw "Missing dependency $requiredComp for $stepName" }
                Write-ColorOutput "Skipping $stepName due to missing dependencies" "Warning"
                [void]$results.Skipped.Add($stepName)
                $results.ComponentStatus[$stepName] = "Skipped"
                continue
            }
            
            # Get correct function name
            $functionName = if ($step.Function) {
                $step.Function
            } else {
                "Install-$stepName"
            }
            
            Write-Log "Calling function: $functionName" -Level "DEBUG"
            
            try {
                # Check if function exists
                if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                    throw "Installation function $functionName not found"
                }
                
                # Execute the installation function
                $installResult = @(& $functionName) | Select-Object -Last 1
                
                # Update results
                if ($installResult -is [bool] -and $installResult) {
                    [void]$results.Successful.Add($stepName)
                    $results.ComponentStatus[$stepName] = "Installed"
                    Write-ColorOutput "Successfully installed: $stepName" "Success"
                } else {
                    throw "$functionName did not report success"
                }
            }
            catch {
                if ($_.Exception.Data.Contains('InstallerRestart')) {
                    $results.RebootRequired = $true
                    $results.Pending = @($orderedSteps | Select-Object -Skip ($current - 1) | ForEach-Object { $_.Name })
                    foreach ($name in $results.Pending) { $results.ComponentStatus[$name] = 'Pending' }
                    Write-Log "Setup paused at ${stepName}. $($_.Exception.Message)" -Level WARN
                    break
                }
                Write-ColorOutput "Failed to install ${stepName}: $_" "Error"
                [void]$results.Failed.Add($stepName)
                $results.ComponentStatus[$stepName] = "Failed"
                
                # If component is required, stop installation
                if ($step.Required) {
                    throw
                }
            }
            
            # Update progress after installation
            if ($useProgressUI -and $progressUI) {
                try {
                    $progressUI.Show(
                        "Installing $($step.Group) Components",
                        $current,
                        $results.Total,
                        $results.ComponentStatus
                    )
                }
                catch {
                    Write-Log "Error showing progress: $_" -Level "WARN"
                    $useProgressUI = $false
                }
            }
            else {
                Write-Progress -Activity "Installing Components" `
                    -Status "Completed: $stepName" `
                    -PercentComplete ($current / [Math]::Max(1, $results.Total) * 100)
            }
        }

        # Complete the progress bar
        if (-not $useProgressUI) {
            Write-Progress -Activity "Installing Components" -Completed
        }

        # Show final summary
        Show-InstallationSummary -Results $results -InstallationType $InstallationType
        return $results
    }
    catch {
        Write-Log "Installation failed: $_" -Level "ERROR"
        throw
    }
}

# Helper function to process individual installation steps
function Install-ComponentStep {
    param($Step, [switch]$Force)
    
    try {
        if (-not $Force -and (Test-InstallationState $Step.Name)) {
            Write-Log "$($Step.Name) is already installed" -Level "INFO"
            return @{
                Name = $Step.Name
                Success = $false  # False here indicates "no changes needed"
            }
        }
        
        # Get correct function name from step
        $functionName = if ($Step.Function) {
            $Step.Function
        } else {
            "Install-$($Step.Name)"
        }
        
        # Check if function exists
        if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
            throw "Installation function $functionName not found"
        }
        
        $result = & $functionName
        
        return @{
            Name = $Step.Name
            Success = $result
        }
    }
    catch {
        Write-Log "Failed to execute $($Step.Name): $_" -Level "ERROR"
        if ($Step.Required -and -not $Force) { throw }
        
        return @{
            Name = $Step.Name
            Success = $null  # Null indicates error
        }
    }
}

# Helper function to update results
function Update-Results {
    param($Results, $Step, $Success)
    
    if ($Success -eq $true) {
        [void]$Results.Successful.Add($Step.Name)
        $Results.ComponentStatus[$Step.Name] = "Installed"
    }
    elseif ($Success -eq $false) {
        [void]$Results.Skipped.Add($Step.Name)
        $Results.ComponentStatus[$Step.Name] = "Skipped" 
    }
    else {
        [void]$Results.Failed.Add($Step.Name)
        $Results.ComponentStatus[$Step.Name] = "Failed"
    }
}

# Helper function to show installation summary
function Show-InstallationSummary {
    param($Results, $InstallationType)
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗"
    Write-Host "║                      Installation Summary                       ║"
    Write-Host "╠════════════════════════════════════════════════════════════════╣"
    Write-Host "║ Total Steps:    $($Results.Total.ToString().PadRight(4)) ║"
    Write-Host "║ Successful:     $($Results.Successful.Count.ToString().PadRight(4)) ║"
    Write-Host "║ Failed:         $($Results.Failed.Count.ToString().PadRight(4)) ║"
    Write-Host "║ Skipped:        $($Results.Skipped.Count.ToString().PadRight(4)) ║"
    Write-Host "╚════════════════════════════════════════════════════════════════╝"

    if ($Results.RebootRequired) {
        Write-Host "Pending ($($Results.Pending.Count)): $($Results.Pending -join ', ')"
        Write-Host "Save your work and restart Windows. Open PowerShell 7 as Administrator and run:"
        Write-Host "`$env:WINDOWS_SETUP_PROFILE = '$InstallationType'"
        Write-Host 'irm https://raw.githubusercontent.com/JDLanctot/windows-setup/main/bootstrap.ps1 | iex'
        if ($InstallationType -eq 'Custom') { Write-Host 'Select the same custom components again.' }
    }

    if ($Results.Successful.Count -gt 0) {
        Write-Host "`nSuccessfully Completed:"
        foreach ($step in $Results.Successful) {
            Write-Host "  • $step"
        }
    }
    if ($Results.Skipped.Count -gt 0) {
        Write-Host "`nSkipped Steps:"
        foreach ($step in $Results.Skipped) {
            Write-Host "  • $step"
        }
    }
    if ($Results.Failed.Count -gt 0) {
        Write-Host "`nFailed Steps:" -ForegroundColor Red
        foreach ($step in $Results.Failed) {
            Write-Host "  • $step" -ForegroundColor Red
        }
    }

    Write-Host "`nLog File: $script:SCRIPT_LOG_PATH"
}
