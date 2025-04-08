class ProgressUI {
    [int]$LastLine = 0
    [string]$LastPhase = ""
    [hashtable]$LastStatus = @{}
    [System.Diagnostics.Stopwatch]$Timer
    [int]$TotalComponents = 0
    [hashtable]$GroupProgress = @{}
    
    ProgressUI() {
        $this.Timer = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    [void] Clear() {
        if ($this.LastLine -gt 0) {
            $currentLine = [Console]::CursorTop
            [Console]::SetCursorPosition(0, $currentLine - $this.LastLine)
            for ($i = 0; $i -lt $this.LastLine; $i++) {
                Write-Host (" " * [Console]::WindowWidth)
            }
            [Console]::SetCursorPosition(0, $currentLine - $this.LastLine)
        }
    }

    [void] Show([string]$Phase, [int]$Current, [int]$Total, [hashtable]$ComponentStatus) {
        # Clear previous progress if it exists
        $this.Clear()
        
        $this.TotalComponents = $Total
        
        # Calculate progress
        $percentComplete = [math]::Floor(($Current / [math]::Max(1, $Total)) * 100)
        $width = 50
        $completed = [math]::Floor(($width * $Current) / [math]::Max(1, $Total))
        $progressBar = "[" + ("█" * $completed) + ("░" * ($width - $completed)) + "]"
        
        # Calculate elapsed and estimated time
        $elapsed = $this.Timer.Elapsed
        $elapsedStr = "{0:hh\:mm\:ss}" -f $elapsed
        
        $estimatedTotal = if ($percentComplete -gt 0) { $elapsed.TotalSeconds * 100 / $percentComplete } else { 0 }
        $remaining = [TimeSpan]::FromSeconds($estimatedTotal - $elapsed.TotalSeconds)
        $remainingStr = "{0:hh\:mm\:ss}" -f $remaining
        
        # Group components by status and group
        $statusGroups = @{}
        $groupDetails = @{}
        
        foreach ($component in $ComponentStatus.Keys) {
            $status = $ComponentStatus[$component]
            $group = $this.GetComponentGroup($component)
            
            # Initialize group in groupProgress if not exists
            if (-not $this.GroupedProgress.ContainsKey($group)) {
                $this.GroupedProgress[$group] = @{
                    Total = 0
                    Completed = 0
                    Failed = 0
                    Skipped = 0
                }
            }
            
            # Update group progress counts
            if ($status -eq "Installed") {
                $this.GroupedProgress[$group].Completed++
            }
            elseif ($status -eq "Failed") {
                $this.GroupedProgress[$group].Failed++
            }
            elseif ($status -eq "Skipped") {
                $this.GroupedProgress[$group].Skipped++
            }
            
            $this.GroupedProgress[$group].Total++
            
            # Group by status first
            if (-not $statusGroups.ContainsKey($status)) {
                $statusGroups[$status] = @{}
            }
            
            # Then by group within status
            if (-not $statusGroups[$status].ContainsKey($group)) {
                $statusGroups[$status][$group] = [System.Collections.ArrayList]::new()
            }
            
            [void]$statusGroups[$status][$group].Add($component)
            
            # Build group details
            if (-not $groupDetails.ContainsKey($group)) {
                $groupDetails[$group] = @{
                    Total = 0
                    Components = [System.Collections.ArrayList]::new()
                }
            }
            
            $groupDetails[$group].Total++
            [void]$groupDetails[$group].Components.Add($component)
        }
        
        # Build status display
        $lines = @(
            "╔════════════════════════════════════════════════════════════════╗",
            "║ Windows Setup - $Phase",
            "║ $progressBar $percentComplete%",
            "║ Elapsed: $elapsedStr | Remaining: $remainingStr",
            "║ Components: $Current of $Total"
        )
        
        # Show group progress summary
        $lines += "║"
        $lines += "║ Group Progress:"
        
        foreach ($group in $this.GroupedProgress.Keys | Sort-Object) {
            $this.GroupProgress = $this.GroupedProgress[$group]
            $groupTotal = $this.GroupProgress.Total
            $groupCompleted = $this.GroupProgress.Completed
            $groupFailed = $this.GroupProgress.Failed
            $groupSkipped = $this.GroupProgress.Skipped
            
            if ($groupTotal -gt 0) {
                $groupPercent = [math]::Floor(($groupCompleted / $groupTotal) * 100)
                $groupStatus = "$group".PadRight(15) + 
                               "[$groupCompleted/$groupTotal]".PadRight(10) + 
                               "$groupPercent%"
                               
                if ($groupFailed -gt 0) {
                    $groupStatus += " | $groupFailed failed"
                }
                if ($groupSkipped -gt 0) {
                    $groupStatus += " | $groupSkipped skipped"
                }
                
                $lines += "║ • $groupStatus"
            }
        }
        
        # Show active operations and recent changes
        $lines += "║"
        $lines += "║ Current Status:"
        
        # Show Installing components first
        if ($statusGroups.ContainsKey("Installing")) {
            foreach ($group in $statusGroups["Installing"].Keys | Sort-Object) {
                foreach ($component in $statusGroups["Installing"][$group]) {
                    $lines += "║ → Installing: $component"
                }
            }
        }
        
        # Show most recent completions (max 3)
        $recentComplete = @()
        if ($statusGroups.ContainsKey("Installed")) {
            foreach ($group in $statusGroups["Installed"].Keys | Sort-Object) {
                foreach ($component in $statusGroups["Installed"][$group]) {
                    $recentComplete += "║ ✓ Installed: $component"
                }
            }
        }
        if ($recentComplete.Count -gt 0) {
            $recentComplete = $recentComplete | Select-Object -Last 3
            $lines += $recentComplete
        }
        
        # Show failures (all of them)
        if ($statusGroups.ContainsKey("Failed")) {
            $lines += "║"
            $lines += "║ Failures:"
            foreach ($group in $statusGroups["Failed"].Keys | Sort-Object) {
                foreach ($component in $statusGroups["Failed"][$group]) {
                    $lines += "║ ✗ Failed: $component"
                }
            }
        }
        
        $lines += "╚════════════════════════════════════════════════════════════════╝"
        
        # Store state
        $this.LastLine = $lines.Count
        $this.LastPhase = $Phase
        $this.LastStatus = $ComponentStatus.Clone()
        
        # Display
        $lines | ForEach-Object { Write-Host $_ }
    }
    
    [string] GetComponentGroup([string]$ComponentName) {
        # Define groups - can be customized based on your components
        if ($ComponentName -match "Git|PowerShell|Chocolatey|NerdFonts") {
            return "Core"
        }
        elseif ($ComponentName -match "Node|PNPM|NPM|Webpack|Vite") {
            return "Web Dev"
        }
        elseif ($ComponentName -match "Python|Conda|Jupyter|PyTorch|TensorFlow") {
            return "Data Science"
        }
        elseif ($ComponentName -match "Julia") {
            return "Julia Dev"
        }
        elseif ($ComponentName -match "Neovim|VS Code|Vim") {
            return "Editors"
        }
        elseif ($ComponentName -match "Starship|Alacritty|GlazeWM|Terminal") {
            return "Shell"
        }
        elseif ($ComponentName -match "Eza|Zoxide|Fzf|Ripgrep|Fd|Ag|Bat|7zip|Unzip|Gzip|Wget") {
            return "CLI Tools"
        }
        return "Other"
    }
}