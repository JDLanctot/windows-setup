function Install-Chocolatey {
    [CmdletBinding()]
    param()

    $params = @{
        Type     = "custom"
        Name     = "Chocolatey"
        # Remove Required parameter to fix the error
        # The Install-Component function will handle this
        CustomInstall = {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            return $true
        }
        Verify   = @{
            Script = {
                $hasCommand = Get-Command -Name choco -ErrorAction SilentlyContinue
                return $null -ne $hasCommand
            }
        }
    }

    return Install-Component -Name $params.Name -InstallSpec $params
}