@{
    InstallationSteps     = @{
        'default'    = @{
            PackageManager = 'choco'
            PathRefresh    = $true
            Verification   = 'command'
        }
        'winget'     = @{
            PackageManager = 'winget'
            PathRefresh    = $true
            Verification   = 'command'
        }
        'npm-global' = @{
            PackageManager = 'npm'
            InstallArgs    = @('-g')
            PathRefresh    = $true
            Verification   = 'command'
        }
        'custom'     = @{
            Verification = 'custom'
            PathRefresh  = $false
        }
    }

    ConfigurationHandlers = @{
        'alacritty' = @{
            PostInstall = @{
                Files = @(
                    @{Source = 'alacritty.toml'; Target = 'alacritty.toml' }
                    @{Source = '{colorscheme}.toml'; Target = '{colorscheme}.toml' }
                )
            }
        }
        'neovim'    = @{
            CopyMode   = 'directory'
        }
        'directory' = @{
            CopyMode   = 'directory'
        }
        'default'   = @{
            CopyMode   = 'file'
        }
    }

    Paths                 = @{
        'nvim'       = @{
            'source'  = '.config\nvim'
            'target'  = 'nvim'
            'type'    = 'directory'
            'handler' = 'neovim'
        }
        'bat'        = @{
            'source'  = '.config\bat\config'
            'target'  = 'bat\config'
            'type'    = 'file'
            'handler' = 'default'
        }
        'julia'      = @{
            'source'  = '.julia\config\startup.jl'
            'target'  = '.julia\config\startup.jl'
            'type'    = 'file'
            'handler' = 'default'
        }
        'powershell' = @{
            'source'  = '.windows\powershell\profile.ps1'
            'target'  = 'profile.ps1'
            'type'    = 'file'
            'handler' = 'default'
        }
        'starship'   = @{
            'source'  = '.config\starship.toml'
            'target'  = '.starship\starship.toml'
            'type'    = 'file'
            'handler' = 'default'
        }
        'alacritty'  = @{
            'source'      = '.config\alacritty'
            'target'      = 'AppData\Roaming\alacritty'
            'type'        = 'file'
            'handler'     = 'alacritty'
            'colorscheme' = 'rose-pine-moon'
        }
        'glazewm'    = @{
            'source'  = '.windows\.glzr\glazewm\config.yaml'
            'target'  = '.glzr\glazewm\config.yaml'
            'type'    = 'file'
            'handler' = 'default'
        }
        'flowlauncher' = @{
            'source'  = '.config\flow-launcher\rosepine.xaml'
            'target'  = 'AppData\Roaming\FlowLauncher\Themes\rosepine.xaml'
            'type'    = 'file'
            'handler' = 'default'
        }
        'claudeskills' = @{
            'source'  = '.claude\skills'
            'target'  = '.claude\skills'
            'type'    = 'directory'
            'handler' = 'directory'
        }
    }


    Programs              = @(
        @{
            Name        = "Git"
            InstallSpec = @{
                Type        = "default"
                Required    = $true
                Alias       = "git"
                PostInstall = @{
                    PathAdd     = '{ProgramFiles}\Git\cmd'
                    ConfigCheck = "git config --global user.email"
                }
                Verify      = @{
                    Command = "git"
                    Config  = @{
                        Check = "git config --global user.email"
                    }
                }
            }
        }
        @{
            Name        = "Powershell"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "pwsh"
                Verify   = @{
                    Command = "pwsh"
                }
            }
        }
        @{
            Name        = "Starship"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "starship"
                Verify   = @{
                    Command = "starship"
                }
            }
        }
        @{
            Name        = "Zig"
            InstallSpec = @{
                Type        = "default"
                Required    = $true
                Alias       = "zig"
                PostInstall = @{
                    PathAdd = "C:\ProgramData\chocolatey\bin"
                }
                Verify      = @{
                    Command = "zig"
                }
            }
        }
        @{
            Name        = "Julia"
            InstallSpec = @{
                Type     = "default"
                Required = $false
                Alias    = "julia"
                Verify   = @{
                    Command = "julia"
                    Config  = @{
                        Path = '{USERPROFILE}\.julia\config\startup.jl'
                    }
                }
            }
        }
        @{
            Name        = "Alacritty"
            InstallSpec = @{
                Type     = "default"
                Required = $false
                Alias    = "alacritty"
                Verify   = @{
                    Command = "alacritty"
                    Config  = @{
                        Path = '{USERPROFILE}\AppData\Roaming\alacritty'
                    }
                }
            }
        }
        @{
            Name        = "GlazeWM"
            InstallSpec = @{
                Type     = "winget"
                Required = $false
                Alias    = "glazewm"
                Verify   = @{
                    Command = "glazewm"
                    Config  = @{
                        Path = '{USERPROFILE}\.glzr\glazewm\config.yaml'
                    }
                }
            }
        }
    )

    CliTools              = @(
        @{
            Name        = "Eza"
            InstallSpec = @{
                Type     = "winget"
                Required = $true
                Alias    = "eza"
                Package  = "eza-community.eza"
                Verify   = @{
                    Command = "eza"
                }
            }
        }
        @{
            Name        = "Zoxide"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "zoxide"
                Verify   = @{
                    Command = "zoxide"
                }
            }
        }
        @{
            Name        = "ZenBrowser"
            InstallSpec = @{
                Type     = "winget"
                Required = $false
                Alias    = "zen"
                Package  = "Zen-Team.Zen-Browser"
                Verify   = @{
                    Command = "zen"
                }
            }
        }
        @{
            Name        = "Firefox"
            InstallSpec = @{
                Type     = "winget"
                Required = $false
                Alias    = "firefox"
                Package  = "Mozilla.Firefox"
                Verify   = @{
                    Command = "firefox"
                }
            }
        }
        @{
            Name        = "Fzf"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "fzf"
                Verify   = @{
                    Command = "fzf"
                }
            }
        }
        @{
            Name        = "Ag"
            InstallSpec = @{
                Type     = "default"
                Required = $false
                Alias    = "ag"
                Verify   = @{
                    Command = "ag"
                }
            }
        }
        @{
            Name        = "Bat"
            InstallSpec = @{
                Type     = "default"
                Required = $false
                Alias    = "bat"
                Verify   = @{
                    Command = "bat"
                }
            }
        }
        @{
            Name        = "Ripgrep"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "rg"
                Verify   = @{
                    Command = "rg"
                }
            }
        }
        @{
            Name        = "7zip"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "7z"
                Verify   = @{
                    Command = "7z"
                }
            }
        }
        @{
            Name        = "Unzip"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "unzip"
                Verify   = @{
                    Command = "unzip"
                }
            }
        }
        @{
            Name        = "Gzip"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "gzip"
                Verify   = @{
                    Command = "gzip"
                }
            }
        }
        @{
            Name        = "Wget"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "wget"
                Verify   = @{
                    Command = "wget"
                }
            }
        }
        @{
            Name        = "Fd"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "fd"
                Verify   = @{
                    Command = "fd"
                }
            }
        }
        @{
            Name        = "Neovim"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "nvim"
                Verify   = @{
                    Command = "nvim"
                }
            }
        }
        @{
            Name        = "Conda"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "conda"
                Package  = "miniconda3"
                Verify   = @{
                    Command = "conda"
                }
            }
        }
        @{
            Name        = "Uv"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "uv"
                Package  = "uv"
                Verify   = @{
                    Command = "uv"
                }
            }
        }
        @{
            Name        = "Ruff"
            InstallSpec = @{
                Type     = "custom"
                Required = $true
                Alias    = "ruff"
                Verify   = @{
                    Command = "ruff"
                }
            }
        }
        @{
            Name        = "AwsCli"
            InstallSpec = @{
                Type     = "default"
                Required = $true
                Alias    = "aws"
                Package  = "awscli"
                Verify   = @{
                    Command = "aws"
                }
            }
        }
        @{
            Name        = "Biome"
            InstallSpec = @{
                Type     = "npm-global"
                Required = $true
                Alias    = "biome"
                Package  = "@biomejs/biome"
                Verify   = @{
                    Command = "biome"
                }
            }
        }
        @{
            Name        = "Sst"
            InstallSpec = @{
                Type     = "npm-global"
                Required = $true
                Alias    = "sst"
                Package  = "sst"
                Verify   = @{
                    Command = "sst"
                }
            }
        }
        @{
            Name        = "ClaudeCli"
            InstallSpec = @{
                Type     = "npm-global"
                Required = $true
                Alias    = "claude"
                Package  = "@anthropic-ai/claude-code"
                Verify   = @{
                    Command = "claude"
                }
            }
        }
        @{
            Name        = "OpenCode"
            InstallSpec = @{
                Type     = "npm-global"
                Required = $true
                Alias    = "opencode"
                Package  = "opencode-ai"
                Verify   = @{
                    Command = "opencode"
                }
            }
        }
    )

    InstallationGroups    = @{
        'Core'        = @{
            Steps    = @(
                @{ Name = "Chocolatey"; Function = "Install-Chocolatey"; Required = $true }
                @{ Name = "Git"; Function = "Install-Git"; Required = $true }
            )
            Order    = 1
            Required = $true
        }
        'Shell'       = @{
            Steps = @(
                @{ Name = "Starship"; Function = "Install-Starship"; Required = $true }
            )
            Order = 2
        }
        'Development' = @{
            Steps = @(
                @{ Name = "Neovim"; Function = "Install-Neovim"; Required = $true }
            )
            Order = 3
        }
        'Tools'       = @{
            Steps = @(
                @{ Name = "Eza"; Function = "Install-Eza"; Required = $true }
                @{ Name = "Zoxide"; Function = "Install-Zoxide"; Required = $true }
                @{ Name = "Fzf"; Function = "Install-Fzf"; Required = $true }
                @{ Name = "Ag"; Function = "Install-Ag"; Required = $true }
                @{ Name = "Bat"; Function = "Install-Bat"; Required = $true }
                @{ Name = "ClaudeCli"; Function = "Install-ClaudeCli"; Required = $true }
                @{ Name = "OpenCode"; Function = "Install-OpenCode"; Required = $true }
            )
            Order = 4
        }
        'Optional'    = @{
            Steps = @(
                @{ Name = "Ripgrep"; Function = "Install-Ripgrep"; Required = $true }
                @{ Name = "7zip"; Function = "Install-7zip"; Required = $true }
                @{ Name = "Unzip"; Function = "Install-Unzip"; Required = $true }
                @{ Name = "Gzip"; Function = "Install-Gzip"; Required = $true }
                @{ Name = "Wget"; Function = "Install-Wget"; Required = $true }
                @{ Name = "Fd"; Function = "Install-Fd"; Required = $true }
                @{ Name = "Conda"; Function = "Install-Conda"; Required = $true }
                @{ Name = "Uv"; Function = "Install-Uv"; Required = $true }
                @{ Name = "Ruff"; Function = "Install-Ruff"; Required = $true }
                @{ Name = "AwsCli"; Function = "Install-AwsCli"; Required = $true }
                @{ Name = "Biome"; Function = "Install-Biome"; Required = $true }
                @{ Name = "Sst"; Function = "Install-Sst"; Required = $true }
                @{ Name = "PowerShell"; Function = "Install-PowerShell"; Required = $true }
                @{ Name = "Nerd Fonts"; Function = "Install-NerdFonts"; Required = $false }
                @{ Name = "Alacritty"; Function = "Install-Alacritty"; Required = $false }
                @{ Name = "GlazeWM"; Function = "Install-GlazeWM"; Required = $false }
                @{ Name = "FlowLauncher"; Function = "Install-FlowLauncher"; Required = $false }
                @{ Name = "ZenBrowser"; Function = "Install-ZenBrowser"; Required = $false }
                @{ Name = "Node"; Function = "Install-Node"; Required = $true }
                @{ Name = "Julia"; Function = "Install-Julia"; Required = $false }
                @{ Name = "Zig"; Function = "Install-Zig"; Required = $true }
            )
            Order = 5
        }
        # New bundles
        'DeepLearning' = @{
            Steps = @(
                @{ Name = "Conda"; Function = "Install-Conda"; Required = $true }
            )
            Order = 5
            Description = "Tools for deep learning and data science"
        }
        'WebDev' = @{
            Steps = @(
                @{ Name = "Node"; Function = "Install-Node"; Required = $true }
                @{ Name = "PNPM"; Function = "Install-PNPM"; Required = $true }
                @{ Name = "Vscode"; Function = "Install-VSCode"; Required = $true }
            )
            Order = 6
            Description = "Web development environment"
        }
        'JuliaDev' = @{
            Steps = @(
                @{ Name = "Julia"; Function = "Install-Julia"; Required = $true }
                @{ Name = "VSCode"; Function = "Install-VSCode"; Required = $false }
                @{ Name = "JuliaExtension"; Function = "Install-JuliaExtension"; Required = $false }
            )
            Order = 7
            Description = "Julia development environment"
        }
    }

    InstallationProfiles  = @{
        Minimal  = @{
            Groups   = @('Core')
            Parallel = $false
        }
        Standard = @{
            Groups          = @('Core', 'Shell', 'Development', 'Tools')
            AdditionalSteps = @(
                @{ Name = "Dotfiles"; Function = "Install-Dotfiles"; Required = $true }
            )
            Parallel        = $false
            ParallelGroups  = @('Tools')
        }
        Full     = @{
            InheritFrom     = "Standard"
            Groups          = @('Optional', 'DeepLearning', 'WebDev', 'JuliaDev')
            MakeAllRequired = $true
            Parallel        = $false
            ParallelGroups  = @('Development', 'Tools', 'Optional')
        }
        # New specialized profiles
        DataScience = @{
            InheritFrom = "Minimal"
            Groups = @('DeepLearning')
            AdditionalSteps = @(
                @{ Name = "Dotfiles"; Function = "Install-Dotfiles"; Required = $true }
            )
        }
        WebDevelopment = @{
            InheritFrom = "Minimal"
            Groups = @('WebDev')
            AdditionalSteps = @(
                @{ Name = "Dotfiles"; Function = "Install-Dotfiles"; Required = $true }
            )
        }
        JuliaDevelopment = @{
            InheritFrom = "Minimal"
            Groups = @('JuliaDev')
            AdditionalSteps = @(
                @{ Name = "Dotfiles"; Function = "Install-Dotfiles"; Required = $true }
            )
        }
    }

    MinimumRequirements   = @{
        'PSVersion'           = '5.1'
        'WindowsVersion'      = '10.0'
        'RequiredDiskSpaceGB' = 10
    }

    Dependencies          = @{
        'Neovim'   = @{
            Requires = @('Git')
            Order    = 1
        }
        'Starship' = @{
            Requires = @()
            Order    = 2
        }
        'Node'     = @{
            Requires = @()
            Order    = 3
        }
    }
}
