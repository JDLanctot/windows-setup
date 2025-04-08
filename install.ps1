#Requires -RunAsAdministrator
#Requires -Version 7

[CmdletBinding()]
param(
    [ValidateSet('Minimal', 'Standard', 'Full', 'DataScience', 'WebDevelopment', 'JuliaDevelopment')]
    [string]$InstallationType = 'Standard',
    [switch]$Force,
    [switch]$NoBackup,
    [switch]$Silent,
    [switch]$Menu,
    [string]$LogPath
)

# Initialize error handling
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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
    
    # Display menu if requested or no installation type provided
    if ($Menu -or [string]::IsNullOrEmpty($InstallationType)) {
        Write-Host "`n╔════════════════════════════════════════════════════════════════╗"
        Write-Host "║                  Windows Setup Installation                    ║"
        Write-Host "╠════════════════════════════════════════════════════════════════╣"
        Write-Host "║ Please select an installation profile:                         ║"
        Write-Host "║                                                                ║"
        Write-Host "║  1. Minimal   - Core tools only (Git, PowerShell)              ║"
        Write-Host "║  2. Standard  - Development essentials (default)               ║"
        Write-Host "║  3. Full      - Everything                                     ║"
        Write-Host "║                                                                ║"
        Write-Host "║ Specialized bundles:                                           ║"
        Write-Host "║  4. DataScience      - Python, Conda, Jupyter, PyTorch         ║"
        Write-Host "║  5. WebDevelopment   - Node.js, PNPM, VSCode                   ║"
        Write-Host "║  6. JuliaDevelopment - Julia and related tools                 ║"
        Write-Host "╚════════════════════════════════════════════════════════════════╝"
        
        $selection = Read-Host "Enter your choice (1-6)"
        
        $InstallationType = switch ($selection) {
            "1" { "Minimal" }
            "2" { "Standard" }
            "3" { "Full" }
            "4" { "DataScience" }
            "5" { "WebDevelopment" }
            "6" { "JuliaDevelopment" }
            default { "Standard" }
        }
        
        Write-Host "`nSelected profile: $InstallationType"
    }
    
    # Start installation with parameters
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
catch {
    Write-Error "Installation failed: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}