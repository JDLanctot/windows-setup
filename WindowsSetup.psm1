# Start of WindowsSetup.psm1
# Initialize empty module state
$script:Config = $null
$script:CONFIG_PATHS = $null
$script:INSTALLED_COMPONENTS = @{}
$script:InstallationState = $null
$script:Progress = $null

# Get module root path
$script:MODULE_ROOT = $PSScriptRoot
if (-not $MODULE_ROOT) {
    $MODULE_ROOT = Split-Path -Parent $MyInvocation.MyCommand.Path
    if (-not $MODULE_ROOT) {
        throw "Unable to determine module root path"
    }
}

# Initialize essential paths
$script:CONFIG_ROOT = Join-Path $MODULE_ROOT "config"
$script:FUNCTIONS_ROOT = Join-Path $MODULE_ROOT "functions"
$script:HELPERS_ROOT = Join-Path $MODULE_ROOT "helpers"
$script:CLASSES_ROOT = Join-Path $MODULE_ROOT "classes"

# Initialize logging path
$logDirectory = Join-Path $env:TEMP "WindowsSetup\logs"
if (-not (Test-Path $logDirectory)) {
    New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
}
$script:SCRIPT_LOG_PATH = Join-Path $logDirectory "setup_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Export paths for module-wide access
$ExecutionContext.SessionState.PSVariable.Set("WindowsSetup_ModulePaths", @{
        ModuleRoot    = $script:MODULE_ROOT
        ConfigRoot    = $script:CONFIG_ROOT
        FunctionsRoot = $script:FUNCTIONS_ROOT
        HelpersRoot   = $script:HELPERS_ROOT
        ClassesRoot   = $script:CLASSES_ROOT
        LogPath       = $script:SCRIPT_LOG_PATH
    })

# Validate all paths exist
$paths = @{
    'Module Root'    = $script:MODULE_ROOT
    'Config Root'    = $script:CONFIG_ROOT
    'Functions Root' = $script:FUNCTIONS_ROOT
    'Helpers Root'   = $script:HELPERS_ROOT
    'Classes Root'   = $script:CLASSES_ROOT
}

foreach ($pathName in $paths.Keys) {
    if (-not (Test-Path $paths[$pathName])) {
        throw "Required path '$pathName' not found: $($paths[$pathName])"
    }
}

# Load classes first (order matters!)
$classFiles = [ordered]@{
    'ComponentState.ps1'       = $true  # Load first
    'StateManager.ps1'         = $true  # Load second
    'WindowsSetupConfig.ps1'   = $false
    'InstallationState.ps1'    = $false
    'InstallationStep.ps1'     = $false
    'InstallationProgress.ps1' = $false
    'ProgressUI.ps1'           = $false
}

foreach ($classFile in $classFiles.Keys) {
    $classPath = Join-Path $CLASSES_ROOT $classFile
    if (Test-Path $classPath) {
        $content = Get-Content -Path $classPath -Raw
        Write-Debug "Loading class: $classPath"
        try {
            . ([scriptblock]::Create($content))
        }
        catch {
            Write-Error "Failed to load class $classFile`: $_"
            throw
        }
    }
    else {
        if ($classFiles[$classFile]) {
            # Only throw for required classes
            throw "Required class file not found: $classPath"
        }
    }
}

# Load ALL helper functions first since Initialize functions depend on them
$helperFolders = @(
    'Directory', # Contains Test-PathPermissions
    'Logging',
    'Utils'
)

foreach ($folder in $helperFolders) {
    $folderPath = Join-Path $HELPERS_ROOT $folder
    if (Test-Path $folderPath) {
        Get-ChildItem -Path $folderPath -Filter "*.ps1" | 
        ForEach-Object {
            Write-Debug "Loading helper: $($_.FullName)"
            . $_.FullName
        }
    }
}

# Function loading section - ordered by dependencies
$functionFolders = @(
    'State', 'Test', 'Cache', 'Core', 'Security', 'Network', 'Initialize', 'Install', 'UI'
)

foreach ($folder in $functionFolders) {
    $folderPath = Join-Path $FUNCTIONS_ROOT $folder
    if (Test-Path $folderPath) {
        # Get all .ps1 files in current folder and all subfolders
        Get-ChildItem -Path $folderPath -Filter "*.ps1" -Recurse | 
        ForEach-Object {
            Write-Debug "Loading function: $($_.FullName)"
            . $_.FullName
        }
    }
}

$configFiles = @(
    "config.psd1"
)

foreach ($configFile in $configFiles) {
    $configPath = Join-Path $CONFIG_ROOT $configFile
    if (Test-Path $configPath) {
        $script:Config = Import-PowerShellDataFile $configPath
    }
    else {
        throw "Required configuration file not found: $configPath"
    }
}

# Initialize state manager singleton
try {
    $global:LASTEXITCODE = 0
    Write-Log "Starting module initialization..." -Level "INFO"
    
    $envCheck = Test-Environment -Requirements -Permissions
    if (-not $envCheck.Success) {
        $errorMsg = "Module initialization failed - Environment check failed:`n"
        foreach ($key in $envCheck.Details.Keys) {
            $value = $envCheck.Details[$key]
            if ($value -eq $false) {
                $errorMsg += "- $key check failed`n"
            }
        }
        if ($envCheck.Errors) {
            $errorMsg += "Errors:`n" + ($envCheck.Errors -join "`n")
        }
        throw $errorMsg
    }
    
    Initialize-ModuleComponents
    Initialize-ModuleConfiguration
    [StateManager]::Instance = [StateManager]::new("$env:USERPROFILE\.dotfiles_state.json")
    
    Write-Log "Module initialization completed successfully" -Level "SUCCESS"
}
catch {
    Write-Log "Module initialization failed: $_" -Level "ERROR"
    throw
}

# Export public functions
Export-ModuleMember -Function @(
    'Start-Installation',
    'Install-Chocolatey',
    'Install-Configuration',
    'Install-Git',
    'Install-NerdFonts',
    'Install-PowerShell',
    'Install-Julia',
    'Install-Neovim',
    'Install-Node',
    'Install-Zig',
    'Install-Alacritty',
    'Install-GlazeWM',
    'Install-Starship',
    'Install-7Zip',
    'Install-Ag',
    'Install-Bat',
    'Install-Conda',
    'Install-Eza',
    'Install-fd',
    'Install-Fzf',
    'Install-Gzip',
    'Install-Ripgrep',
    'Install-Unzip',
    'Install-Wget',
    'Install-Zoxide',
    'Show-Summary',
    'Test-Environment'
)