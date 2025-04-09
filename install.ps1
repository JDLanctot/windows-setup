#Requires -RunAsAdministrator
#Requires -Version 7

[CmdletBinding()]
param(
    [ValidateSet('Minimal', 'Standard', 'Full', 'DataScience', 'WebDevelopment', 'JuliaDevelopment', 'Custom')]
    [string]$InstallationType,
    [switch]$Force,
    [switch]$NoBackup,
    [switch]$Silent,
    [switch]$Interactive,
    [string]$LogPath
)

# Initialize error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Function to select installation mode and components
function Select-InstallationMode {
    [CmdletBinding()]
    param(
        [hashtable]$Config
    )

    Clear-Host
    Write-Host "`n╔══════════════════════════════════════════════════════════════════╗"
    Write-Host "║                Windows Development Environment Setup                ║"
    Write-Host "╚══════════════════════════════════════════════════════════════════╝"
    Write-Host "`nWelcome! This tool will help you set up your Windows development environment."
    Write-Host "You can choose from predefined profiles or create a custom installation."
    
    # Step 1: Choose installation mode (profile or custom)
    Write-Host "`n╔══════════════════════════════════════════════════╗"
    Write-Host "║  Select Installation Mode                         ║"
    Write-Host "╚══════════════════════════════════════════════════╝"
    Write-Host "  1. Use a predefined profile"
    Write-Host "  2. Create a custom installation"
    
    $modeChoice = 0
    do {
        $modeInput = Read-Host "`nEnter your choice (1-2)"
        if ($modeInput -match "^[1-2]$") {
            $modeChoice = [int]$modeInput
        } else {
            Write-Host "Invalid selection. Please enter 1 or 2." -ForegroundColor Yellow
        }
    } while ($modeChoice -eq 0)
    
    # Result will contain the installation type and component selection
    $result = @{
        InstallationType = $null
        Components = @()
    }
    
    # If using a predefined profile
    if ($modeChoice -eq 1) {
        # Get available profiles
        $profiles = $Config.InstallationProfiles.Keys | Sort-Object
        
        # Step 2: Choose profile
        Write-Host "`n╔══════════════════════════════════════════════════╗"
        Write-Host "║  Select Installation Profile                      ║"
        Write-Host "╚══════════════════════════════════════════════════╝"
        
        $i = 1
        $profileChoices = @{}
        $profileDescriptions = @{
            "Minimal" = "Core tools only (Git, PowerShell)"
            "Standard" = "Development essentials (recommended)"
            "Full" = "Complete development environment"
            "DataScience" = "Python, Conda, data science tools"
            "WebDevelopment" = "Node.js, PNPM, web development tools"
            "JuliaDevelopment" = "Julia and related development tools"
        }
        
        foreach ($profile in $profiles) {
            $description = $profileDescriptions[$profile] ?? "Custom profile"
            Write-Host "  $i. $profile - $description"
            $profileChoices[$i] = $profile
            $i++
        }
        
        $profileChoice = 0
        do {
            $profileInput = Read-Host "`nEnter your choice (1-$($i-1))"
            if ($profileInput -match "^\d+$" -and [int]$profileInput -ge 1 -and [int]$profileInput -lt $i) {
                $profileChoice = [int]$profileInput
            } else {
                Write-Host "Invalid selection. Please enter a number between 1 and $($i-1)." -ForegroundColor Yellow
            }
        } while ($profileChoice -eq 0)
        
        $result.InstallationType = $profileChoices[$profileChoice]
        
        # Show summary of selected profile
        $selectedProfile = $Config.InstallationProfiles[$result.InstallationType]
        
        Write-Host "`n╔══════════════════════════════════════════════════╗"
        Write-Host "║  Selected Profile: $($result.InstallationType.PadRight(31)) ║"
        Write-Host "╚══════════════════════════════════════════════════╝"
        
        Write-Host "`nThis profile includes:"
        
        # List groups included in the profile
        $includedGroups = @()
        
        # Add groups from the profile
        if ($selectedProfile.Groups) {
            $includedGroups += $selectedProfile.Groups
        }
        
        # Add inherited groups if applicable - safely access InheritFrom
        if ($selectedProfile.PSObject.Properties.Name -contains "InheritFrom" -and $selectedProfile.InheritFrom) {
            $baseProfile = $Config.InstallationProfiles[$selectedProfile.InheritFrom]
            if ($baseProfile -and $baseProfile.Groups) {
                $includedGroups += $baseProfile.Groups
            }
        }
        
        # Remove duplicates
        $includedGroups = $includedGroups | Select-Object -Unique
        
        foreach ($group in $includedGroups) {
            $groupConfig = $Config.InstallationGroups[$group]
            if ($groupConfig) {
                $groupDesc = if ($groupConfig.PSObject.Properties.Name -contains "Description") { $groupConfig.Description } else { "Group of components" }
                Write-Host "  • $group - $groupDesc"
                
                # List components in each group
                foreach ($step in $groupConfig.Steps) {
                    $requiredMarker = if ($step.Required) { "[Required] " } else { "" }
                    Write-Host "    - $requiredMarker$($step.Name)"
                }
            }
            else {
                Write-Host "  • $group - Group not found in configuration" -ForegroundColor Yellow
            }
        }
        
        # List additional steps
        if ($selectedProfile.AdditionalSteps) {
            Write-Host "`n  • Additional Components:"
            foreach ($step in $selectedProfile.AdditionalSteps) {
                $requiredMarker = if ($step.Required) { "[Required] " } else { "" }
                Write-Host "    - $requiredMarker$($step.Name)"
            }
        }
    }
    # If creating a custom installation
    else {
        $result.InstallationType = "Custom"
        $selectedComponents = @()
        
        Write-Host "`n╔══════════════════════════════════════════════════╗"
        Write-Host "║  Create Custom Installation                       ║"
        Write-Host "╚══════════════════════════════════════════════════╝"
        Write-Host "Select which components you want to install:"
        
        # Get all available groups and their components
        $allGroups = $Config.InstallationGroups.Keys | Sort-Object
        
        foreach ($group in $allGroups) {
            $groupConfig = $Config.InstallationGroups[$group]
            if ($groupConfig) {
                $groupDesc = if ($groupConfig.PSObject.Properties.Name -contains "Description") { $groupConfig.Description } else { "Group of components" }
                Write-Host "`n• $group - $groupDesc"
                
                foreach ($step in $groupConfig.Steps) {
                    $componentName = $step.Name
                    $isRequired = $step.Required
                    
                    if ($isRequired) {
                        Write-Host "  [Required] $componentName - will be installed automatically"
                        $selectedComponents += $componentName
                    }
                    else {
                        $response = Read-Host "  Install $componentName? (y/n)"
                        if ($response -eq "y") {
                            $selectedComponents += $componentName
                            Write-Host "    ✓ Will be installed" -ForegroundColor Green
                        }
                        else {
                            Write-Host "    ✗ Will be skipped" -ForegroundColor DarkGray
                        }
                    }
                }
            }
        }
        
        # Ask about dotfiles installation
        Write-Host "`n• Additional Components"
        $response = Read-Host "  Install Dotfiles? (y/n)"
        if ($response -eq "y") {
            $selectedComponents += "Dotfiles"
            Write-Host "    ✓ Will be installed" -ForegroundColor Green
        }
        else {
            Write-Host "    ✗ Will be skipped" -ForegroundColor DarkGray
        }
        
        $result.Components = $selectedComponents
    }
    
    # Final confirmation
    Write-Host "`n╔══════════════════════════════════════════════════╗"
    Write-Host "║  Installation Summary                            ║"
    Write-Host "╚══════════════════════════════════════════════════╝"
    Write-Host "Installation Type: $($result.InstallationType)"
    
    if ($result.InstallationType -eq "Custom") {
        Write-Host "`nSelected Components:"
        foreach ($component in $result.Components) {
            Write-Host "  • $component"
        }
    }
    
    $confirmResponse = Read-Host "`nProceed with installation? (y/n)"
    if ($confirmResponse -ne "y") {
        Write-Host "Installation cancelled." -ForegroundColor Yellow
        exit
    }
    
    return $result
}

try {
    # Load required helpers first
    $helpersDirPath = Join-Path $PSScriptRoot "helpers"
    $essentialHelpers = @(
        "Logging\Write-Log.ps1"
    )

    foreach ($helper in $essentialHelpers) {
        $helperPath = Join-Path $helpersDirPath $helper
        if (Test-Path $helperPath) {
            . $helperPath
        }
        else {
            throw "Essential helper not found: $helperPath"
        }
    }

    # Import module
    $modulePath = Join-Path $PSScriptRoot "WindowsSetup.psd1"
    if (-not (Test-Path $modulePath)) {
        throw "Module manifest not found at: $modulePath"
    }

    # Use -Force to ensure clean loading and -Global to ensure proper scope
    Import-Module $modulePath -Force -Global -DisableNameChecking
    
    # For interactive mode, first determine if we have modules properly loaded and config available
    $config = $null
    if ($Interactive -or [string]::IsNullOrEmpty($InstallationType)) {
        # Initialize the installation to get config
        $initResult = Start-Installation -Initialize -Silent:$Silent
        $config = $initResult.Config
        
        if (-not $config) {
            throw "Failed to load configuration"
        }
    
        # Now proceed with interactive selection
        $selection = Select-InstallationMode -Config $config
        
        if ($selection.InstallationType -eq "Custom") {
            # For custom installations, we'll provide the component list to Start-Installation
            $customComponents = $selection.Components
            Start-Installation -InstallationType "Custom" -Force:$Force -NoBackup:$NoBackup -Silent:$Silent -CustomComponents $customComponents
        }
        else {
            # For predefined profiles, just use the profile name
            Start-Installation -InstallationType $selection.InstallationType -Force:$Force -NoBackup:$NoBackup -Silent:$Silent
        }
    }
    else {
        # Start installation with parameters as before
        $params = @{
            InstallationType = $InstallationType
            Force            = $Force
            NoBackup         = $NoBackup
            Silent           = $Silent
        }
        
        if ($LogPath) {
            $params['LogPath'] = $LogPath
        }
        
        if ($DebugPreference -eq 'Continue') {
            $params['Debug'] = $true
        }

        $result = Start-Installation @params
        
        if (-not $result) {
            throw "Installation failed without specific error"
        }
    }
}
catch {
    Write-Error "Installation failed: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}