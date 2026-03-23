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
                PSVersion           = '5.1'
                WindowsVersion      = '10.0'
                RequiredDiskSpaceGB = 10
            }
        }

        if ($All -or $Requirements) {
            $reqCheck = @{
                PSVersion      = $PSVersionTable.PSVersion -ge [Version]$minimumRequirements.PSVersion
                WindowsVersion = [System.Environment]::OSVersion.Version -ge [Version]$minimumRequirements.WindowsVersion
                DiskSpace      = ((Get-PSDrive $env:SystemDrive[0]).Free / 1GB) -ge $minimumRequirements.RequiredDiskSpaceGB
                AdminRights    = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
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
                    $probeFile = Join-Path $path ".windows-setup-permission-check.tmp"
                    Set-Content -Path $probeFile -Value "ok" -ErrorAction Stop
                    Remove-Item -Path $probeFile -Force -ErrorAction Stop
                    $permCheck[$path] = $true
                }
                catch {
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
