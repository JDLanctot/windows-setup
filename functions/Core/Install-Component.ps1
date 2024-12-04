function Install-Component {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [Parameter(Mandatory = $true)]
        [hashtable]$InstallSpec,
        [switch]$Force
    )

    try {
        Write-ColorOutput "Checking $Name installation..." "Status"
        $stateManager = [StateManager]::GetInstance()

        # Get installation step configuration
        $stepConfig = $script:Config.InstallationSteps[$InstallSpec.Type ?? 'default']
        if (-not $stepConfig) {
            throw "Invalid installation type: $($InstallSpec.Type)"
        }

        # Early exit if already installed (unless forced)
        if (-not $Force -and $stateManager.IsInstalled($InstallSpec.Alias)) {
            Write-ColorOutput "$Name already installed" "Status"
            return $false
        }

        Write-ColorOutput "Installing $Name..." "Status"
        $didInstallSomething = $false

        # Pre-installation tasks from InstallSpec
        if ($InstallSpec.PreInstall) {
            Write-ColorOutput "Running pre-installation tasks..." "Status"
            $preInstallResult = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($InstallSpec.PreInstall))
            if (-not $preInstallResult) {
                throw "Pre-installation tasks failed"
            }
        }

        # Main installation
        switch ($stepConfig.PackageManager) {
            'choco' {
                Write-ColorOutput "Using Chocolatey to install $Name" "Status"
                $installArgs = @($Name, '--yes', '--no-progress')
                if ($InstallSpec.InstallArgs) {
                    $installArgs += $InstallSpec.InstallArgs
                }
                try {
                    # Check if Chocolatey is installed
                    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                        Write-ColorOutput "Chocolatey not found. Installing Chocolatey first..." "Status"
                        Install-Chocolatey
                    }

                    # Capture and log the output from Chocolatey
                    $chocoOutput = & choco install @installArgs *>&1
                    Write-Log "Chocolatey output: $($chocoOutput -join "`n")" -Level "DEBUG"

                    if ($LASTEXITCODE -ne 0) {
                        throw "Chocolatey installation failed with exit code: $LASTEXITCODE`nOutput: $($chocoOutput -join "`n")"
                    }
                    
                    $didInstallSomething = $true
                }
                catch {
                    Write-ColorOutput "Failed to install $Name via Chocolatey: $_" "Error"
                    throw
                }
            }
            'winget' {
                Write-ColorOutput "Using Winget to install $Name" "Status"
                try {
                    $wingetArgs = @('install', $InstallSpec.Package ?? $Name)
                    Write-Host $InstallSpec
                    if ($InstallSpec.InstallArgs) { $wingetArgs += $InstallSpec.InstallArgs }
                    & winget @wingetArgs
                    if ($LASTEXITCODE -ne 0) {
                        throw "Winget installation failed with exit code: $LASTEXITCODE"
                    }
                    $didInstallSomething = $true
                }
                catch {
                    Write-ColorOutput "Failed to install $Name via Winget: $_" "Error"
                    throw
                }
            }
            'npm' {
                Write-ColorOutput "Using NPM to install $Name" "Status"
                try {
                    $installArgs = @('install')
                    if ($stepConfig.InstallArgs) { $installArgs += $stepConfig.InstallArgs }
                    $installArgs += $Name
                    if ($InstallSpec.InstallArgs) { $installArgs += $InstallSpec.InstallArgs }
                    
                    & npm @installArgs
                    if ($LASTEXITCODE -ne 0) {
                        throw "NPM installation failed with exit code: $LASTEXITCODE"
                    }
                    $didInstallSomething = $true
                }
                catch {
                    Write-ColorOutput "Failed to install $Name via NPM: $_" "Error"
                    throw
                }
            }
            'custom' {
                if ($InstallSpec.CustomInstall) {
                    Write-ColorOutput "Running custom installation for $Name" "Status"
                    $result = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($InstallSpec.CustomInstall))
                    $didInstallSomething = $result
                }
                else {
                    throw "Custom installation type requires CustomInstall script"
                }
            }
        }

        # Refresh PATH if needed
        if ($didInstallSomething -and $stepConfig.PathRefresh) {
            Write-ColorOutput "Refreshing PATH environment" "Status"
            RefreshPath
        }

        # Post-installation tasks
        if ($didInstallSomething -and $InstallSpec.PostInstall) {
            Write-ColorOutput "Running post-installation tasks..." "Status"

            # Handle PATH additions
            if ($InstallSpec.PostInstall.PathAdd) {
                $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
                if ($userPath -notlike "*$($InstallSpec.PostInstall.PathAdd)*") {
                    [Environment]::SetEnvironmentVariable(
                        "Path",
                        "$userPath;$($InstallSpec.PostInstall.PathAdd)",
                        "User"
                    )
                    RefreshPath
                }
            }

            # Handle configuration checks/updates
            if ($InstallSpec.PostInstall.ConfigCheck) {
                $checkResult = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($InstallSpec.PostInstall.ConfigCheck))
                if (-not $checkResult) {
                    throw "Post-installation configuration check failed"
                }
            }

            # Handle custom post-install script
            if ($InstallSpec.PostInstall.Script) {
                $postInstallResult = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($InstallSpec.PostInstall.Script))
                if (-not $postInstallResult) {
                    throw "Post-installation script failed"
                }
            }
        }

        # Verification
        $verifyResult = switch ($stepConfig.Verification) {
            'command' {
                $alias = $InstallSpec.Alias
                Write-ColorOutput "Verifying $Name installation using command check..." "Status"
                if (-not (Get-Command -Name $alias -ErrorAction SilentlyContinue)) {
                    throw "$Name command not found after installation"
                }
                # Additional configuration verification if specified
                if ($InstallSpec.Verify.Config) {
                    if ($InstallSpec.Verify.Config.Pattern) {
                        Test-Path $PROFILE -and (Select-String -Path $PROFILE -Pattern $InstallSpec.Verify.Config.Pattern -Quiet)
                    }
                    elseif ($InstallSpec.Verify.Config.Path) {
                        Test-Path $InstallSpec.Verify.Config.Path
                    }
                    else { $true }
                }
                else { $true }
            }
            'custom' {
                Write-ColorOutput "Running custom verification for $Name..." "Status"
                if ($InstallSpec.Verify.Script) {
                    Invoke-Command -ScriptBlock ([ScriptBlock]::Create($InstallSpec.Verify.Script))
                }
                else { $true }
            }
            default { $true }
        }

        if (-not $verifyResult) {
            throw "Installation verification failed"
        }

        if ($didInstallSomething) {
            Update-InstallationState -ComponentName $Name -InstallSpec $InstallSpec -Required:$InstallSpec.Required
            Write-ColorOutput "$Name installation completed" "Success"
            return $true
        }

        Write-ColorOutput "No changes were needed for $Name" "Status"
        return $false
    }
    catch {
        Handle-Error -ErrorRecord $_ `
            -ComponentName $Name `
            -Operation "Installation" `
            -InstallSpec $InstallSpec `
            -Critical:$InstallSpec.Required
        if ($InstallSpec.Required) { throw }
        return $false
    }
}