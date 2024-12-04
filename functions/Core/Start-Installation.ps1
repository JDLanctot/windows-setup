function Start-Installation {
    [CmdletBinding()]
    param(
        [ValidateSet('Minimal', 'Standard', 'Full')]
        [string]$InstallationType = 'Standard',
        [switch]$Force,
        [switch]$NoBackup,
        [switch]$Silent
    )
    
    try {
        $script:Silent = $Silent
        
        if (-not $Silent) {
            Write-Host "`n" # Add initial spacing
        }
        
        # Initialize installation state
        $initResult = Initialize-Installation -InstallationType $InstallationType -Force:$Force
        $configToUse = if ($script:Config) { $script:Config } else { $initResult.Config }
        if (-not $configToUse) { throw "No configuration available" }
        
        # Get installation profile
        $thisProfile = $configToUse.InstallationProfiles[$InstallationType]
        if (-not $thisProfile) { throw "Invalid installation profile: $InstallationType" }
        
        # Initialize results tracking
        $results = @{
            Total      = 0
            Successful = [System.Collections.ArrayList]::new()
            Failed     = [System.Collections.ArrayList]::new()
            Skipped    = [System.Collections.ArrayList]::new()
        }

        # Process installation groups
        $groups = $thisProfile.ParallelGroups
        if ($thisProfile.InheritFrom) {
            $baseProfile = $configToUse.InstallationProfiles[$thisProfile.InheritFrom]
            if ($baseProfile) {
                $groups = @($baseProfile.Groups) + @($groups) | Select-Object -Unique
            }
        }

        # Get all steps, including from groups
        $allSteps = [System.Collections.ArrayList]::new()
        
        # Add group-based installations first
        foreach ($groupName in $groups) {
            $group = $configToUse.InstallationGroups[$groupName]
            if (-not $group) { continue }
        
            foreach ($step in $group.Steps) {
                $componentSpec = if ($step.Name -in $configToUse.CliTools.Name) {
                    $toolConfig = $configToUse.CliTools | Where-Object { $_.Name -eq $step.Name }
                    if ($thisProfile.MakeAllRequired) { $toolConfig.InstallSpec.Required = $true }
                    @{
                        Name        = $toolConfig.Name
                        InstallSpec = @{
                            Name     = $toolConfig.Name
                            Type     = $toolConfig.InstallSpec.Type
                            Required = $toolConfig.InstallSpec.Required
                            Alias    = $toolConfig.InstallSpec.Alias
                            Package  = $toolConfig.InstallSpec.Package
                            Verify   = $toolConfig.InstallSpec.Verify
                        }
                        Function    = $step.Function
                        Group       = $groupName
                        Order       = $group.Order
                    }
                }
                else {
                    $step
                }
                $allSteps.Add($componentSpec)
            }
        }

        # Add additional steps from profile
        if ($thisProfile.AdditionalSteps) {
            $allSteps.AddRange(@($thisProfile.AdditionalSteps))
        }

        # Sort steps by order and dependencies
        $orderedSteps = $allSteps | Sort-Object { 
            $step = $_
            $dependency = $configToUse.Dependencies[$step.Name]
            @($dependency.Requires).Count
        } | Sort-Object { $_.Order }

        $results.Total = $orderedSteps.Count

        # Process steps based on parallel configuration
        if ($thisProfile.Parallel -and $thisProfile.ParallelGroups) {
            $parallelGroups = $orderedSteps | Group-Object { $_.Group } | 
            Where-Object { $_.Name -in $thisProfile.ParallelGroups }

            $serialGroups = $orderedSteps | Group-Object { $_.Group } | 
            Where-Object { $_.Name -notin $thisProfile.ParallelGroups }

            # Process serial groups first
            foreach ($group in $serialGroups) {
                foreach ($step in $group.Group) {
                    $installResult = Install-ComponentStep -Step $step -Force:$Force
                    Update-Results -Results $results -Step $step -Success $installResult
                }
            }

            # Process parallel groups
            $jobs = @()
            foreach ($group in $parallelGroups) {
                foreach ($step in $group.Group) {
                    $jobs += Start-Job -ScriptBlock {
                        param($Step, $Force)
                        Install-ComponentStep -Step $Step -Force:$Force
                    } -ArgumentList $step, $Force
                }
            }

            # Wait for and process results
            $jobs | Wait-Job | ForEach-Object {
                $result = Receive-Job -Job $_ -Wait
                $step = $orderedSteps | Where-Object { $_.Name -eq $result.Name }
                Update-Results -Results $results -Step $step -Success $result.Success
                Remove-Job -Job $_
            }
        }
        else {
            # Serial processing
            foreach ($step in $orderedSteps) {
                $installResult = Install-ComponentStep -Step $step -Force:$Force
                Update-Results -Results $results -Step $step -Success $installResult
            }
        }

        # Show final summary
        Show-InstallationSummary -Results $results
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
            return $false
        }
        
        return Install-Component -Name $Step.Name -InstallSpec $Step.InstallSpec -Force:$Force
    }
    catch {
        Write-Log "Failed to execute $($Step.Name): $_" -Level "ERROR"
        if ($Step.InstallSpec.Required -and -not $Force) { throw }
        return $false
    }
}

# Helper function to update results
function Update-Results {
    param($Results, $Step, $Success)
    
    if ($Success -eq $true) {
        [void]$Results.Successful.Add($Step.Name)
    }
    elseif ($Success -eq $false) {
        [void]$Results.Skipped.Add($Step.Name)
    }
    else {
        [void]$Results.Failed.Add($Step.Name)
    }
}

# Helper function to show installation summary
function Show-InstallationSummary {
    param($Results)
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗"
    Write-Host "║                      Installation Summary                       ║"
    Write-Host "╠════════════════════════════════════════════════════════════════╣"
    Write-Host "║ Total Steps:    $($Results.Total.ToString().PadRight(4)) ║"
    Write-Host "║ Successful:     $($Results.Successful.Count.ToString().PadRight(4)) ║"
    Write-Host "║ Failed:         $($Results.Failed.Count.ToString().PadRight(4)) ║"
    Write-Host "║ Skipped:        $($Results.Skipped.Count.ToString().PadRight(4)) ║"
    Write-Host "╚════════════════════════════════════════════════════════════════╝"

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