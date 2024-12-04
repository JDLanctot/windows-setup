class ComponentState {
    [string]$Name
    [string]$Version
    [string]$Path
    [datetime]$InstalledDate
    [hashtable]$AdditionalData
    [bool]$Required
    [string]$Group
    [hashtable]$InstallSpec
    hidden [string]$ProfilePath
    
    ComponentState([string]$name, [hashtable]$installSpec) {
        if ([string]::IsNullOrEmpty($name)) {
            throw "Component name cannot be null or empty"
        }
        $this.Name = $name
        $this.InstallSpec = $installSpec
        $this.Required = $installSpec.Required
        $this.InstalledDate = Get-Date
        $this.AdditionalData = @{}
        $this.ProfilePath = $global:profile
    }
    
    [bool]Save() {
        try {
            if ($this.InstallSpec.Verify.Command) {
                $alias = $this.InstallSpec.Alias
                $this.Version = switch ($alias) {
                    'git' { (git --version).Split(' ')[2] }
                    'nvim' { ((nvim --version)[0] -split ' ')[1] }
                    'node' { (node --version).TrimStart('v') }
                    'starship' { (starship --version).Split(' ')[1] }
                    default { 
                        $cmd = Get-Command -Name $alias -ErrorAction SilentlyContinue
                        if ($cmd) { $cmd.Version.ToString() } else { "Unknown" }
                    }
                }
            }
            return $true
        }
        catch {
            Write-Log "Failed to save state for $($this.Name): $_" -Level "ERROR"
            return $false
        }
    }
    
    [bool]Verify() {
        try {
            if (-not $this.InstallSpec) {
                Write-Log "No InstallSpec available for verification of $($this.Name)" -Level "DEBUG"
                return $false
            }

            # Basic command verification
            $hasCommand = Get-Command -Name $this.InstallSpec.Alias -ErrorAction SilentlyContinue
            if (-not $hasCommand) { return $false }

            # Configuration verification if specified
            if ($this.InstallSpec.Verify.Config) {
                $config = $this.InstallSpec.Verify.Config

                if ($config.Pattern -and $config.Content) {
                    # Check for configuration in profile
                    $hasConfig = Test-Path $this.ProfilePath -and 
                                (Select-String -Path $this.ProfilePath -Pattern $config.Pattern -Quiet)
                    if (-not $hasConfig) { return $false }
                }

                if ($config.Path) {
                    # Check for configuration files
                    $hasPath = Test-Path $config.Path
                    if (-not $hasPath) { return $false }
                }

                if ($config.Check) {
                    # Run custom check
                    $checkResult = Invoke-Expression $config.Check
                    if (-not $checkResult) { return $false }
                }
            }

            # Custom verification if specified
            if ($this.InstallSpec.Verify.Script) {
                $verifyResult = Invoke-Command -ScriptBlock ([ScriptBlock]::Create($this.InstallSpec.Verify.Script))
                if (-not $verifyResult) { return $false }
            }

            return $true
        }
        catch {
            Write-Log "Failed to verify $($this.Name): $_" -Level "ERROR"
            return $false
        }
    }

    [void]SetGroup([string]$group) {
        $this.Group = $group
    }
}