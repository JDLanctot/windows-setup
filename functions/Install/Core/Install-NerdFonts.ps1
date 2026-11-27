function Install-NerdFonts {
    [CmdletBinding()]
    param()

    $installSpec = @{
        Type          = "custom"
        Required      = $false
        Name          = "NerdFonts"
        CustomInstall = {
            $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip"
            $fontsFolder = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
            $workDir = Join-Path $env:TEMP ("windows-setup-fonts-" + [guid]::NewGuid())
            $null = New-Item -ItemType Directory -Path $workDir -ErrorAction Stop
            $downloadPath = Join-Path $workDir 'JetBrainsMono.zip'
            $extractPath = Join-Path $workDir 'fonts'

            try {
                if (-not (Test-Path $fontsFolder)) {
                    New-Item -ItemType Directory -Path $fontsFolder -Force | Out-Null
                }

                Invoke-WebRequest -Uri $fontUrl -OutFile $downloadPath -ErrorAction Stop
                Expand-Archive -LiteralPath $downloadPath -DestinationPath $extractPath -ErrorAction Stop

                $installedCount = 0
                Get-ChildItem -Path $extractPath -Filter "*.ttf" | ForEach-Object {
                    $targetPath = Join-Path $fontsFolder $_.Name
                    if (-not (Test-Path $targetPath)) {
                        Copy-Item $_.FullName $targetPath
                        $installedCount++
                    }
                }

                return $installedCount -gt 0
            }
            finally {
                Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction Stop
            }
        }
        Verify        = @{
            Script = {
                Test-Path "$env:LOCALAPPDATA\Microsoft\Windows\Fonts\JetBrainsMono*.ttf"
            }
        }
    }

    return Install-Component -Name $installSpec.Name -InstallSpec $installSpec
}
