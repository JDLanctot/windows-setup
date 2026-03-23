function Install-Git {
    [CmdletBinding()]
    param()

    try {
        Write-ColorOutput "Checking Git installation..." "Status"

        if (-not (Get-Command -Name git -ErrorAction SilentlyContinue)) {
            $installSpec = @{
                Type     = "default"
                Required = $true
                Name     = "git"
                Alias    = "git"
                Verify   = @{
                    Command = "git"
                }
            }

            $installed = Install-Component -Name $installSpec.Name -InstallSpec $installSpec
            if (-not $installed) {
                return $false
            }
        }

        $sshDir = "$env:USERPROFILE\.ssh"
        if (-not (Test-Path $sshDir)) {
            New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
        }

        $gitEmail = git config --global user.email 2>$null
        $gitName = git config --global user.name 2>$null
        if (-not $gitEmail -or -not $gitName) {
            Write-ColorOutput "Git is installed but global user.name/user.email are not set." "Warning"
            Write-ColorOutput "Configure them later with: git config --global user.name \"Your Name\" and git config --global user.email \"you@example.com\"" "Warning"
        }

        Save-InstallationState -Component "Git" | Out-Null
        Write-ColorOutput "Git setup completed" "Success"
        return $true
    }
    catch {
        Resolve-Error -ErrorRecord $_ `
            -ComponentName "Git Environment" `
            -Operation "Setup" `
            -Critical
        throw
    }
}
