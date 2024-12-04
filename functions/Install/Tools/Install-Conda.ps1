function Install-Conda {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type          = "custom"
        Required      = $true
        Name          = "Conda"
        CustomInstall = {
            $minicondaPath = "$env:USERPROFILE\Miniconda3"
            
            if (-not (Test-Path "$minicondaPath\Scripts\conda.exe")) {
                $installerUrl = "https://repo.anaconda.com/miniconda/Miniconda3-latest-Windows-x86_64.exe"
                $installerPath = Join-Path $env:TEMP "miniconda.exe"
                
                try {
                    Invoke-WebRequest -Uri $installerUrl -OutFile $installerPath -UseBasicParsing
                }
                catch {
                    curl.exe $installerUrl -o $installerPath
                }

                $installArgs = @("/S", "/AddToPath=1", "/RegisterPython=1", "/D=$minicondaPath")
                $result = Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait -PassThru
                Remove-Item $installerPath -Force -ErrorAction SilentlyContinue

                return $result.ExitCode -eq 0
            }
            return $false
        }
        PostInstall   = {
            if (-not (Select-String -Path $PROFILE -Pattern "conda.*initialize" -Quiet)) {
                $initScript = @"
If (Test-Path "$env:USERPROFILE\Miniconda3\Scripts\conda.exe") {
    (& "$env:USERPROFILE\Miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{`$_} | Invoke-Expression
}
"@
                Add-Content -Path $PROFILE -Value $initScript
            }
            return $true
        }
        Verify        = @{
            Command = "conda"
            Config  = @{
                Pattern = "conda initialize"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}