@{
    RootModule         = 'WindowsSetup.psm1'
    ModuleVersion      = '1.0.0'
    GUID               = '31fc73d6-fc26-4670-b77a-4c7bcb60319c'
    Author             = 'Jordi Lanctot'
    Description        = 'Windows Development Environment Setup'
    PowerShellVersion  = '7.0'
    
    # Prevent .psd1 files from being opened in notepad
    FileList           = @(
        'config\config.psd1'
    )
    
    PrivateData        = @{
        PSData = @{
            Tags       = @('windows', 'setup', 'development')
            ProjectUri = 'https://github.com/jdlanctot/dotfiles'
        }
    }
    
    # Updated function exports - removed old test functions
    FunctionsToExport  = @(
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
    
    # Specify required modules
    RequiredModules    = @()
    
    # Specify file types that should be treated as data
    TypesToProcess     = @()
    FormatsToProcess   = @()
    
    # Specify configuration files
    RequiredAssemblies = @()
    ScriptsToProcess   = @()
}