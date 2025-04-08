function Select-InstallationComponents {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [string]$ProfileName,
        [hashtable]$Config
    )
    
    $selectedComponents = @()
    
    Write-Host "`n╔════════════════════════════════════════════════════════════════╗"
    Write-Host "║                Component Selection for $($ProfileName.PadRight(18))║"
    Write-Host "╠════════════════════════════════════════════════════════════════╣"
    
    # Get profile configuration
    $installProfile = $Config.InstallationProfiles[$ProfileName]
    if (-not $installProfile) {
        Write-ColorOutput "Profile not found: $ProfileName" "Error"
        return $selectedComponents
    }
    
    # Build list of available groups
    $availableGroups = @()
    
    # Add groups from the profile itself
    if ($installProfile.Groups) {
        $availableGroups += $installProfile.Groups
    }
    
    # Add inherited groups if applicable
    if ($installProfile.InheritFrom) {
        $baseProfile = $Config.InstallationProfiles[$installProfile.InheritFrom]
        if ($baseProfile -and $baseProfile.Groups) {
            $availableGroups += $baseProfile.Groups
        }
    }
    
    # Remove duplicates
    $availableGroups = $availableGroups | Select-Object -Unique
    
    # Present each group and let user select components
    foreach ($groupName in $availableGroups) {
        $group = $Config.InstallationGroups[$groupName]
        if (-not $group) { continue }
        
        Write-Host "`n║ Group: $($groupName.PadRight(67))║"
        Write-Host "║ $("-" * 68)║"
        
        $componentNumber = 1
        $componentMap = @{}
        
        foreach ($step in $group.Steps) {
            $isRequired = $step.Required
            $marker = if ($isRequired) { "[Required]" } else { "[ ] $componentNumber." }
            $componentMap[$componentNumber] = $step.Name
            
            $description = if ($step.Description) { " - $($step.Description)" } else { "" }
            $displayLine = "║ $($marker.PadRight(12)) $($step.Name)$description"
            
            # Trim and pad the line to fit in the box
            if ($displayLine.Length -gt 70) {
                $displayLine = $displayLine.Substring(0, 67) + "..."
            }
            
            Write-Host "$($displayLine.PadRight(70))║"
            
            # Add required components automatically
            if ($isRequired) {
                $selectedComponents += $step.Name
            }
            else {
                $componentNumber++
            }
        }
    }
    
    Write-Host "╚════════════════════════════════════════════════════════════════╝"
    
    # Ask user to select components
    Write-Host "`nSelect components to install (comma-separated numbers, or 'all' for everything):"
    $userSelection = Read-Host "Your selection"
    
    if ($userSelection -eq "all") {
        # Add all non-required components (required ones are already added)
        foreach ($groupName in $availableGroups) {
            $group = $Config.InstallationGroups[$groupName]
            if (-not $group) { continue }
            
            foreach ($step in $group.Steps) {
                if (-not $step.Required) {
                    $selectedComponents += $step.Name
                }
            }
        }
    }
    else {
        # Process user selection
        $selectedNumbers = $userSelection -split ',' | ForEach-Object { $_.Trim() }
        foreach ($num in $selectedNumbers) {
            if ($componentMap.ContainsKey([int]$num)) {
                $selectedComponents += $componentMap[[int]$num]
            }
        }
    }
    
    # Show confirmation
    Write-Host "`nYou've selected the following components:"
    foreach ($component in $selectedComponents) {
        Write-Host " • $component"
    }
    
    $confirm = Read-Host "`nContinue with installation? (Y/N)"
    if ($confirm -ne "Y" -and $confirm -ne "y") {
        Write-Host "Installation cancelled."
        return @()
    }
    
    return $selectedComponents
}