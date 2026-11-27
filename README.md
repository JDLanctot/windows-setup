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
- RTK (`rtk`), GitHub CLI (`gh`), jq and uv
- Dotfiles bootstrap (PowerShell profile + related config paths)

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

Standard, Full and DataScience use uv. Run `uv venv` in a project to create `.venv` and activate it with `.\.venv\Scripts\Activate.ps1`. The installed PowerShell profile also provides `ca` to create or activate a project environment and `caz <project>` to jump to a project with zoxide and activate its `.venv`. Conda remains available explicitly through `Install-Conda`.

It also includes the optional webdev/cloud stack from dotfiles:

- `ruff` (installed via `uv tool install ruff`)
- `aws` CLI (Chocolatey `awscli`)
- `biome` (`npm -g @biomejs/biome`)
- `sst` (`npm -g sst`)

Optional desktop extras in `Full` include:

- `GlazeWM`
- `Flow Launcher` (Chocolatey `flow-launcher`) plus bundled theme copy to `%APPDATA%\FlowLauncher\Themes\rosepine.xaml`
- `Zen Browser` (default browser install target in this setup)

VS Code installs now also provision a LaTeX workflow for users who prefer it over Neovim:

- installs `Tectonic` into `C:\Program Files\Tectonic` using the official PowerShell drop script and adds it to user `PATH` if needed
- installs `SumatraPDF` via Chocolatey
- installs the `James-Yu.latex-workshop` VS Code extension
- configures VS Code user settings to build with `tectonic` and view PDFs in `SumatraPDF`
- configures Sumatra inverse search back into VS Code

Firefox installer support is still present (`Install-Firefox`) but Firefox is no longer included in default profile groups.

## Restarting during setup

If an installer reports a required restart, setup pauses. Save your work, restart Windows, then run the bootstrap again in an elevated PowerShell 7 window using the profile shown in the summary. Setup rechecks installed components and continues with the remaining work. For Custom, select the same components again.

## Testing

From PowerShell 7 with Pester 5 installed, run `Invoke-Pester ./tests -Output Detailed`. The suite uses a temporary module copy, a local bootstrap archive and simulated package managers. It exercises profile selection, component ordering, failure reporting, CLI verification, state reload and file copying without applying a setup profile to the host.
