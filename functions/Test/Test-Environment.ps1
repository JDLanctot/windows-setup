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
        if ($All -or $Requirements) {
            $reqCheck = @{
                PSVersion      = $PSVersionTable.PSVersion -ge [Version]$Config.MinimumRequirements.PSVersion
                WindowsVersion = [System.Environment]::OSVersion.Version -ge [Version]$Config.MinimumRequirements.WindowsVersion
                DiskSpace      = ((Get-PSDrive $env:SystemDrive[0]).Free / 1GB) -ge $Config.MinimumRequirements.RequiredDiskSpaceGB
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
                $acl = Get-Acl -Path $path
                $permCheck[$path] = $acl.Access | Where-Object {
                    $_.IdentityReference.Value -eq "$env:USERDOMAIN\$env:USERNAME" -and
                    $_.FileSystemRights -band [System.Security.AccessControl.FileSystemRights]::Modify
                }
            }
            $results.Details.Permissions = $permCheck
            $results.Success = $results.Success -and (-not ($permCheck.Values -contains $null))
        }

        return $results
    }
    catch {
        $results.Success = $false
        $results.Errors += $_.Exception.Message
        return $results
    }
}