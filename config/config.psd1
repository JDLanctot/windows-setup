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
            PreInstall  = 'New-Item -ItemType Directory -Force'
            PostInstall = @{
                Files = @(
                    @{Source = 'alacritty.toml'; Target = 'alacritty.toml' }
                    @{Source = '{colorscheme}.toml'; Target = '{colorscheme}.toml' }
                )
            }
        }
        'neovim'    = @{
            PreInstall = 'New-Item -ItemType Directory -Force'
            CopyMode   = 'directory'
        }
        'default'   = @{
            PreInstall = 'New-Item -ItemType Directory -Force'
            CopyMode   = 'file'
        }
    }

    Paths                 = @{
        'nvim'       = @{
            'source'  = 'config\nvim'
            'target'  = 'nvim'
            'type'    = 'directory'
            'handler' = 'neovim'
        }
        'bat'        = @{
            'source'  = 'config\bat\config'
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
            'source'  = '.windows\profile.ps1'
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
            'source'  = '.config\glazewm\config.yaml'
            'target'  = '.glzr\glazewm\config.yaml'
            'type'    = 'file'
            'handler' = 'default'
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
                    Config  = @{
                        Path    = '{USERPROFILE}\.starship\starship.toml'
                        Pattern = "Invoke-Expression \(&starship init powershell\)"
                    }
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
                    Config  = @{
                        Pattern = "zoxide init"
                        Content = '# Zoxide Configuration
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { ''prompt'' } else { ''pwd'' }
    (zoxide init --hook $hook powershell | Out-String)
})'
                    }
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
                    Config  = @{
                        Pattern = "PSFzf"
                        Content = '# PSFzf Configuration
Import-Module PSFzf
Set-PsFzfOption -PSReadlineChordProvider ''Ctrl+t'' -PSReadlineChordReverseHistory ''Ctrl+r'''
                    }
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
                    Config  = @{
                        Pattern = "Set-Alias.*vim.*nvim"
                        Content = @"
# Neovim alias
Set-Alias vim nvim
"@
                    }
                }
            }
        }
        @{
            Name        = "Conda"
            InstallSpec = @{
                Type     = "custom"
                Required = $true
                Alias    = "conda"
                Verify   = @{
                    Command = "conda"
                    Config  = @{
                        Pattern = "conda initialize"
                    }
                }
            }
        }
    )

    InstallationGroups    = @{
        'Core'        = @{
            Steps    = @(
                @{ Name = "Chocolatey"; Function = "Install-Chocolatey"; Required = $true }
                @{ Name = "Git"; Function = "Install-Git"; Required = $true }
                @{ Name = "PowerShell"; Function = "Install-PowerShell"; Required = $true }
                @{ Name = "Nerd Fonts"; Function = "Install-NerdFonts"; Required = $true }
            )
            Order    = 1
            Required = $true
        }
        'Shell'       = @{
            Steps = @(
                @{ Name = "Starship"; Function = "Install-Starship"; Required = $true }
                @{ Name = "Alacritty"; Function = "Install-Alacritty"; Required = $true }
                @{ Name = "GlazeWM"; Function = "Install-GlazeWM"; Required = $false }
            )
            Order = 2
        }
        'Development' = @{
            Steps = @(
                @{ Name = "Neovim"; Function = "Install-Neovim"; Required = $true }
                @{ Name = "Node"; Function = "Install-Node"; Required = $true }
                @{ Name = "Julia"; Function = "Install-Julia"; Required = $true }
                @{ Name = "Zig"; Function = "Install-Zig"; Required = $true }
            )
            Order = 3
        }
        'Tools'       = @{
            Steps = @(
                @{ Name = "Eza"; Function = "Install-Eza"; Required = $true }
                @{ Name = "Zoxide"; Function = "Install-Zoxide"; Required = $true }
                @{ Name = "Fzf"; Function = "Install-Fzf"; Required = $true }
                @{ Name = "Ag"; Function = "Install-Ag"; Required = $false }
                @{ Name = "Bat"; Function = "Install-Bat"; Required = $false }
                @{ Name = "Ripgrep"; Function = "Install-Ripgrep"; Required = $true }
                @{ Name = "7zip"; Function = "Install-7zip"; Required = $true }
                @{ Name = "Unzip"; Function = "Install-Unzip"; Required = $true }
                @{ Name = "Gzip"; Function = "Install-Gzip"; Required = $true }
                @{ Name = "Wget"; Function = "Install-Wget"; Required = $true }
                @{ Name = "Fd"; Function = "Install-Fd"; Required = $true }
                @{ Name = "Conda"; Function = "Install-Conda"; Required = $true }
            )
            Order = 4
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
            ParallelGroups  = @('Development', 'Tools')
        }
        Full     = @{
            InheritFrom     = "Standard"
            MakeAllRequired = $true
            Parallel        = $false
            ParallelGroups  = @('Development', 'Tools')
        }
    }

    MinimumRequirements   = @{
        'PSVersion'           = '5.1'
        'WindowsVersion'      = '10.0'
        'RequiredDiskSpaceGB' = 10
    }

    Dependencies          = @{
        'neovim'   = @{
            Requires = @('node', 'git', 'ripgrep', 'unzip', 'gzip', 'wget', 'fd', 'zig')
            Order    = 1
        }
        'starship' = @{
            Requires = @()
            Order    = 2
        }
        'node'     = @{
            Requires = @()
            Order    = 3
        }
    }
}