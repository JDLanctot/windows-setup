function Test-Environment {
    [CmdletBinding()]
    param(
        [switch]$Requirements,
        [switch]$Network,
        [switch]$Permissions,
        [switch]$All
    )
    
    $results = @{
        Success = $true
        Details = @{
            Requirements = $null
            Network      = $null
            Permissions  = $null
        }
        Errors  = @()
    }
    
    try {
        $config = $script:Config
        if (-not $config) {
            $configPath = Join-Path $script:CONFIG_ROOT "config.psd1"
            if (Test-Path $configPath) {
                $config = Import-PowerShellDataFile -Path $configPath
            }
        }

        $minimumRequirements = if ($config -and $config.MinimumRequirements) {
            $config.MinimumRequirements
        }
        else {
            @{
                PSVersion           = '7.0'
                WindowsVersion      = '10.0'
                RequiredDiskSpaceGB = 10
            }
        }

        if ($All -or $Requirements) {
            $freeGB = (Get-PSDrive -Name ($env:SystemDrive.TrimEnd(':')) -ErrorAction Stop).Free / 1GB
            $reqCheck = @{
                PSVersion      = $PSVersionTable.PSVersion -ge [Version]$minimumRequirements.PSVersion
                WindowsVersion = [System.Environment]::OSVersion.Version -ge [Version]$minimumRequirements.WindowsVersion
                DiskSpace      = $freeGB -ge $minimumRequirements.RequiredDiskSpaceGB
                AdminRights    = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            }
            if (-not $reqCheck.DiskSpace) {
                $results.Errors += ("{0} has {1:N2} GB free. Setup requires {2} GB." -f $env:SystemDrive, $freeGB, $minimumRequirements.RequiredDiskSpaceGB)
            }
            if (-not $reqCheck.AdminRights) {
                $results.Errors += "Open PowerShell 7 as Administrator and rerun setup."
            }
            if (-not $reqCheck.PSVersion) {
                $results.Errors += "PowerShell $($PSVersionTable.PSVersion) detected. Setup requires $($minimumRequirements.PSVersion) or later."
            }
            if (-not $reqCheck.WindowsVersion) {
                $results.Errors += "Windows $([Environment]::OSVersion.Version) detected. Setup requires $($minimumRequirements.WindowsVersion) or later."
            }
            $results.Details.Requirements = $reqCheck
            $results.Success = $results.Success -and (-not ($reqCheck.Values -contains $false))
        }

        if ($All -or $Network) {
            $netCheck = Test-NetConnection -ComputerName "github.com" -Port 443 -WarningAction SilentlyContinue
            $results.Details.Network = @{
                Connected      = $netCheck.TcpTestSucceeded
                NameResolution = $netCheck.NameResolutionSucceeded
                PingSucceeded  = $netCheck.PingSucceeded
            }
            if (-not $netCheck.TcpTestSucceeded) { $results.Errors += "Could not connect to github.com on TCP port 443." }
            $results.Success = $results.Success -and $netCheck.TcpTestSucceeded
        }

        if ($All -or $Permissions) {
            $paths = @(
                $env:USERPROFILE
                $env:LOCALAPPDATA
                $env:APPDATA
            )
            $permCheck = @{}
            foreach ($path in $paths) {
                try {
                    $probeFile = Join-Path $path (".windows-setup-" + [guid]::NewGuid() + ".tmp")
                    Set-Content -Path $probeFile -Value "ok" -ErrorAction Stop
                    Remove-Item -Path $probeFile -Force -ErrorAction Stop
                    $permCheck[$path] = $true
                }
                catch {
                    $results.Errors += "Directory permission check failed for '$path': $($_.Exception.Message)"
                    $permCheck[$path] = $false
                }
            }
            $results.Details.Permissions = $permCheck
            $results.Success = $results.Success -and (-not ($permCheck.Values -contains $false))
        }

        return $results
    }
    catch {
        $results.Success = $false
        $results.Errors += $_.Exception.Message
        return $results
    }
}
