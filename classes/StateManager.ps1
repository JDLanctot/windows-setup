class StateManager {
    [hashtable]$Components = @{}
    [hashtable]$Groups = @{}
    [string]$StateFile
    static [StateManager]$Instance

    StateManager([string]$stateFile) {
        $this.StateFile = $stateFile
        $this.Load()
    }

    static [StateManager]GetInstance() {
        if (-not [StateManager]::Instance) {
            [StateManager]::Instance = [StateManager]::new("$env:USERPROFILE\.dotfiles_state.json")
        }
        return [StateManager]::Instance
    }
    
    [void]Load() {
        if (Test-Path $this.StateFile) {
            $state = Get-Content $this.StateFile -Raw | ConvertFrom-Json
            
            # Load components
            foreach ($prop in $state.Components.PSObject.Properties) {
                $component = [ComponentState]::new($prop.Name)
                $component.Version = $prop.Value.Version
                $component.Path = $prop.Value.Path
                $component.InstalledDate = [datetime]$prop.Value.InstalledDate
                $component.AdditionalData = $this.ConvertPSObjectToHashtable($prop.Value.AdditionalData)
                $component.Required = $prop.Value.Required
                $component.Group = $prop.Value.Group
                $component.InstallSpec = $this.ConvertPSObjectToHashtable($prop.Value.InstallSpec)
                $this.Components[$prop.Name] = $component
            }

            # Load groups
            foreach ($prop in $state.Groups.PSObject.Properties) {
                $this.Groups[$prop.Name] = $this.ConvertPSObjectToHashtable($prop.Value)
            }
        }
    }

    [void]Save() {
        $state = @{
            Components = $this.Components
            Groups     = $this.Groups
        }
        $state | ConvertTo-Json -Depth 10 | Set-Content $this.StateFile
    }

    [ComponentState]GetComponent([string]$name) {
        return $this.Components[$name]
    }

    [ComponentState[]]GetGroupComponents([string]$group) {
        return @($this.Components.Values | Where-Object { $_.Group -eq $group })
    }

    [bool]AddComponent([ComponentState]$component) {
        try {
            if ($component.Save()) {
                $this.Components[$component.Name] = $component
                if ($component.Group) {
                    if (-not $this.Groups[$component.Group]) {
                        $this.Groups[$component.Group] = @{
                            Components = @()
                        }
                    }
                    if ($this.Groups[$component.Group].Components -notcontains $component.Name) {
                        $this.Groups[$component.Group].Components += $component.Name
                    }
                }
                $this.Save()
                return $true
            }
            return $false
        }
        catch {
            Write-Log "Failed to add component $($component.Name): $_" -Level "ERROR"
            return $false
        }
    }

    [bool]RemoveComponent([string]$name) {
        try {
            $component = $this.Components[$name]
            if ($component) {
                if ($component.Group -and $this.Groups[$component.Group]) {
                    $this.Groups[$component.Group].Components = @($this.Groups[$component.Group].Components | 
                        Where-Object { $_ -ne $name })
                }
                $this.Components.Remove($name)
                $this.Save()
                return $true
            }
            return $false
        }
        catch {
            Write-Log "Failed to remove component $(name): $_" -Level "ERROR"
            return $false
        }
    }

    [bool]IsInstalled([string]$name) {
        try {
            # If we already have a component with proper InstallSpec, use that
            $component = $this.Components[$name]
            if ($component -and $component.InstallSpec) {
                Write-Log "Checking installed state for $name using existing component" -Level "DEBUG"
                return $component.Verify()
            }

            # Check if the program exists on the system
            $command = Get-Command -Name $name -ErrorAction SilentlyContinue
            if ($command) {
                Write-Log "Found command for $name at $($command.Source)" -Level "DEBUG"
                return $true
            }

            # Check common installation paths
            $commonPaths = @(
                "${env:ProgramFiles}\$name",
                "${env:ProgramFiles(x86)}\$name",
                "${env:LocalAppData}\Programs\$name",
                "${env:ProgramData}\chocolatey\bin\$name.exe",
                "${env:USERPROFILE}\scoop\apps\$name"
            )

            foreach ($path in $commonPaths) {
                if (Test-Path $path) {
                    Write-Log "Found $name at $path" -Level "DEBUG"
                    return $true
                }
            }

            Write-Log "$name not found in system" -Level "DEBUG"
            return $false
        }
        catch {
            Write-Log "Error checking installation status for $name`: $_" -Level "ERROR"
            return $false
        }
    }

    [bool]IsGroupInstalled([string]$group) {
        try {
            $groupComponents = $this.GetGroupComponents($group)
            if ($groupComponents.Count -eq 0) {
                Write-Log "No components found for group $group" -Level "DEBUG"
                return $false
            }

            foreach ($component in $groupComponents) {
                if (-not $this.IsInstalled($component.Name)) {
                    Write-Log "Component $($component.Name) from group $group is not installed" -Level "DEBUG"
                    return $false
                }
            }

            Write-Log "All components in group $group are installed" -Level "DEBUG"
            return $true
        }
        catch {
            Write-Log "Error checking group installation status for $group`: $_" -Level "ERROR"
            return $false
        }
    }

    hidden [hashtable]ConvertPSObjectToHashtable($object) {
        $hashtable = @{}
        if ($object -is [System.Management.Automation.PSCustomObject]) {
            $object.PSObject.Properties | ForEach-Object {
                if ($_.Value -is [System.Management.Automation.PSCustomObject]) {
                    $hashtable[$_.Name] = $this.ConvertPSObjectToHashtable($_.Value)
                }
                else {
                    $hashtable[$_.Name] = $_.Value
                }
            }
        }
        return $hashtable
    }
}
