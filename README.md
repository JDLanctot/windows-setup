# Windows Setup Module

An automated setup tool for Windows development environments. This module streamlines the installation of development tools, utilities, and configurations to get you up and running quickly.

The default `irm` flow is tailored to the Windows subset required by `dotfiles`:

- `Chocolatey`
- `Git`
- `Starship`
- `Neovim`
- `Eza`
- `Zoxide`
- `Fzf` + `PSFzf`
- `ag`
- `bat`
- `Claude CLI` (`claude`)
- `OpenCode CLI` (`opencode`)
- Dotfiles bootstrap (PowerShell profile + related config paths)
 - `.claude/skills` synced from dotfiles to `%USERPROFILE%\.claude\skills`

## Quick Start

Run the following command in PowerShell to install with the standard profile:

```powershell
irm https://raw.githubusercontent.com/JDLanctot/windows-setup/main/bootstrap.ps1 | iex
```

`bootstrap.ps1` now runs `install.ps1` with the default `Standard` profile (non-interactive unless you explicitly pass `-Interactive` when running `install.ps1` yourself).

Choose a different profile from the one-liner flow:

```powershell
$env:WINDOWS_SETUP_PROFILE = 'Full'
irm https://raw.githubusercontent.com/JDLanctot/windows-setup/main/bootstrap.ps1 | iex
```

You can also run `bootstrap.ps1` directly and pass `-InstallationType`.

`Full` now includes both `Conda` (Chocolatey `miniconda3`) and `uv` (Chocolatey `uv`).

It also includes the optional webdev/cloud stack from dotfiles:

- `ruff` (installed via `uv tool install ruff`)
- `aws` CLI (Chocolatey `awscli`)
- `biome` (`npm -g @biomejs/biome`)
- `sst` (`npm -g sst`)

Optional desktop extras in `Full` include:

- `GlazeWM`
- `Flow Launcher` (Chocolatey `flow-launcher`) plus dotfile theme copy to `%APPDATA%\FlowLauncher\Themes\rosepine.xaml`
- `Zen Browser` (default browser install target in this setup)

Firefox installer support is still present (`Install-Firefox`) but Firefox is no longer included in default profile groups.
