function Install-FlowLauncher {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type     = "custom"
        Required = $false
        Name     = "FlowLauncher"
        CustomInstall = {
            $installed = $false
            $knownExePaths = @(
                "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe",
                "$env:ProgramFiles\FlowLauncher\Flow.Launcher.exe"
            )

            foreach ($path in $knownExePaths) {
                if (Test-Path $path) {
                    $installed = $true
                    break
                }
            }

            if (-not $installed) {
                $versionedPath = Get-ChildItem -Path "$env:LOCALAPPDATA\FlowLauncher" -Filter "Flow.Launcher.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                $installed = $null -ne $versionedPath
            }

            if (-not $installed) {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    Install-Chocolatey | Out-Null
                    RefreshPath
                }

                & choco install flow-launcher --yes --no-progress
                if ($LASTEXITCODE -ne 0) {
                    throw "Chocolatey install flow-launcher failed with exit code $LASTEXITCODE"
                }
            }

            $themesPath = "$env:APPDATA\FlowLauncher\Themes"
            if (-not (Test-Path $themesPath)) {
                New-Item -ItemType Directory -Path $themesPath -Force | Out-Null
            }

            return $true
        }
        Verify = @{
            Script = {
                $knownExePaths = @(
                    "$env:LOCALAPPDATA\FlowLauncher\Flow.Launcher.exe",
                    "$env:ProgramFiles\FlowLauncher\Flow.Launcher.exe"
                )

                foreach ($path in $knownExePaths) {
                    if (Test-Path $path) {
                        return $true
                    }
                }

                $versionedPath = Get-ChildItem -Path "$env:LOCALAPPDATA\FlowLauncher" -Filter "Flow.Launcher.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
                return $null -ne $versionedPath
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
