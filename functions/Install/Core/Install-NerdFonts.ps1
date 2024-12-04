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
            $downloadPath = "$env:TEMP\JetBrainsMono.zip"
            $extractPath = "$env:TEMP\JetBrainsMono"

            try {
                if (-not (Test-Path $fontsFolder)) {
                    New-Item -ItemType Directory -Path $fontsFolder -Force | Out-Null
                }

                Invoke-WebRequest -Uri $fontUrl -OutFile $downloadPath
                Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force

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
                if (Test-Path $downloadPath) { Remove-Item $downloadPath -Force }
                if (Test-Path $extractPath) { Remove-Item $extractPath -Recurse -Force }
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