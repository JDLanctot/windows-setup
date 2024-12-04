function Install-Chocolatey {
    [CmdletBinding()]
    param()

    $params = @{
        Type               = "custom"
        Name               = "Chocolatey"
        Required           = $true
        CustomInstall      = {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            return $true
        }
        CustomVerification = {
            $hasCommand = Get-Command -Name choco -ErrorAction SilentlyContinue
            return $null -ne $hasCommand
        }
    }

    return Install-Component @params
}