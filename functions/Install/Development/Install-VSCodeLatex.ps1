function Get-VSCodeExecutablePath {
    [CmdletBinding()]
    param()

    $command = Get-Command -Name code -ErrorAction SilentlyContinue
    if ($command) {
        $candidatePaths = @(
            (Join-Path (Split-Path $command.Source -Parent) 'Code.exe'),
            $command.Source
        )

        foreach ($candidatePath in $candidatePaths) {
            if ($candidatePath -and (Test-Path $candidatePath) -and $candidatePath -like '*.exe') {
                return $candidatePath
            }
        }
    }

    $knownPaths = @(
        "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles\Microsoft VS Code\Code.exe",
        "$env:ProgramFiles(x86)\Microsoft VS Code\Code.exe"
    )

    foreach ($path in $knownPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Get-SumatraPDFExecutablePath {
    [CmdletBinding()]
    param()

    $knownPaths = @(
        "$env:ProgramFiles\SumatraPDF\SumatraPDF.exe",
        "$env:LocalAppData\SumatraPDF\SumatraPDF.exe"
    )

    foreach ($path in $knownPaths) {
        if (Test-Path $path) {
            return $path
        }
    }

    return $null
}

function Set-KeyValueConfigLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $true)]
        [string]$Key,
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $lines = @()
    if (Test-Path $FilePath) {
        $lines = Get-Content -Path $FilePath
    }

    $updated = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match "^\s*$([regex]::Escape($Key))\s*=") {
            $lines[$i] = "$Key = $Value"
            $updated = $true
            break
        }
    }

    if (-not $updated) {
        $lines += "$Key = $Value"
    }

    Set-Content -Path $FilePath -Value $lines
}

function ConvertFrom-JsonC {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $sanitizedContent = [regex]::Replace($Content, '(?ms)/\*.*?\*/', '')
    $sanitizedLines = @()
    foreach ($line in ($sanitizedContent -split "`r?`n")) {
        if ($line -match '^\s*//') {
            continue
        }
        $sanitizedLines += $line
    }

    $sanitizedContent = ($sanitizedLines -join "`n")
    $sanitizedContent = [regex]::Replace($sanitizedContent, ',\s*(?=[}\]])', '')

    if ([string]::IsNullOrWhiteSpace($sanitizedContent)) {
        return @{}
    }

    return ConvertFrom-Json -InputObject $sanitizedContent -AsHashtable
}

function Install-Tectonic {
    [CmdletBinding()]
    param()

    try {
        $tectonicDir = 'C:\Program Files\Tectonic'
        $tectonicExe = Join-Path $tectonicDir 'tectonic.exe'

        if (-not (Test-Path $tectonicDir)) {
            New-Item -ItemType Directory -Path $tectonicDir -Force | Out-Null
        }

        if (-not (Test-Path $tectonicExe) -and -not (Get-Command -Name tectonic -ErrorAction SilentlyContinue)) {
            Write-ColorOutput 'Installing Tectonic...' 'Status'
            Push-Location $tectonicDir
            try {
                [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
                Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://drop-ps1.fullyjustified.net'))
            }
            finally {
                Pop-Location
            }
        }

        if (Add-PathEntry -PathEntry $tectonicDir -Scope 'User') {
            RefreshPath
        }

        return ($null -ne (Get-Command -Name tectonic -ErrorAction SilentlyContinue)) -or (Test-Path $tectonicExe)
    }
    catch {
        Write-ColorOutput "Failed to install Tectonic: $_" 'Error'
        return $false
    }
}

function Install-SumatraPDF {
    [CmdletBinding()]
    param()

    try {
        if (Get-SumatraPDFExecutablePath) {
            Write-ColorOutput 'SumatraPDF is already installed' 'Status'
            return $true
        }

        Write-ColorOutput 'Installing SumatraPDF...' 'Status'
        & choco install sumatrapdf --yes --no-progress
        if ($LASTEXITCODE -ne 0) {
            throw "Chocolatey install sumatrapdf failed with exit code $LASTEXITCODE"
        }

        return $null -ne (Get-SumatraPDFExecutablePath)
    }
    catch {
        Write-ColorOutput "Failed to install SumatraPDF: $_" 'Error'
        return $false
    }
}

function Install-VSCodeExtension {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ExtensionId
    )

    $extensions = & code --list-extensions 2>$null
    if ($extensions -contains $ExtensionId) {
        return $true
    }

    & code --install-extension $ExtensionId 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $extensions = & code --list-extensions 2>$null
    return $extensions -contains $ExtensionId
}

function Set-VSCodeLatexSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SumatraPath
    )

    $settingsDir = Join-Path $env:APPDATA 'Code\User'
    $settingsPath = Join-Path $settingsDir 'settings.json'
    if (-not (Test-Path $settingsDir)) {
        New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
    }

    $settings = @{}
    if (Test-Path $settingsPath) {
        $rawSettings = Get-Content -Path $settingsPath -Raw
        if (-not [string]::IsNullOrWhiteSpace($rawSettings)) {
            $settings = ConvertFrom-JsonC -Content $rawSettings
        }
    }

    $settings['latex-workshop.latex.recipe.default'] = 'tectonic'
    $settings['latex-workshop.latex.recipes'] = @(
        @{
            name = 'tectonic'
            tools = @('tectonic')
        }
    )
    $settings['latex-workshop.latex.tools'] = @(
        @{
            name = 'tectonic'
            command = 'tectonic'
            args = @('--synctex', '--keep-logs', '--print', '%DOC%.tex')
            env = @{}
        }
    )
    $settings['latex-workshop.view.pdf.viewer'] = 'external'
    $settings['latex-workshop.view.pdf.external.viewer.command'] = $SumatraPath
    $settings['latex-workshop.view.pdf.external.viewer.args'] = @('%PDF%')
    $settings['latex-workshop.view.pdf.external.synctex.command'] = $SumatraPath
    $settings['latex-workshop.view.pdf.external.synctex.args'] = @('-reuse-instance', '-forward-search', '%TEX%', '%LINE%', '%PDF%')
    $settings['latex-workshop.synctex.afterBuild.enabled'] = $true

    $settings | ConvertTo-Json -Depth 10 | Set-Content -Path $settingsPath
    return $true
}

function Set-SumatraPDFLatexSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$VSCodePath
    )

    $sumatraSettingsDir = Join-Path $env:LOCALAPPDATA 'SumatraPDF'
    if (-not (Test-Path $sumatraSettingsDir)) {
        New-Item -ItemType Directory -Path $sumatraSettingsDir -Force | Out-Null
    }

    $sumatraSettingsPath = Join-Path $sumatraSettingsDir 'SumatraPDF-settings.txt'
    Set-KeyValueConfigLine -FilePath $sumatraSettingsPath -Key 'EnableTeXEnhancements' -Value 'true'
    Set-KeyValueConfigLine -FilePath $sumatraSettingsPath -Key 'InverseSearchCmdLine' -Value ('"{0}" -r -g "%%f:%%l"' -f $VSCodePath)
    return $true
}

function Install-VSCodeLatex {
    [CmdletBinding()]
    param()

    try {
        $vsCodePath = Get-VSCodeExecutablePath
        if (-not $vsCodePath) {
            Write-ColorOutput 'VS Code is required before configuring LaTeX support' 'Error'
            return $false
        }

        if (-not (Install-Tectonic)) {
            return $false
        }

        if (-not (Install-SumatraPDF)) {
            return $false
        }

        if (-not (Install-VSCodeExtension -ExtensionId 'James-Yu.latex-workshop')) {
            Write-ColorOutput 'Failed to install LaTeX Workshop for VS Code' 'Error'
            return $false
        }

        $sumatraPath = Get-SumatraPDFExecutablePath
        if (-not $sumatraPath) {
            Write-ColorOutput 'SumatraPDF executable not found after installation' 'Error'
            return $false
        }

        if (-not (Set-VSCodeLatexSettings -SumatraPath $sumatraPath)) {
            return $false
        }

        if (-not (Set-SumatraPDFLatexSettings -VSCodePath $vsCodePath)) {
            return $false
        }

        Write-ColorOutput 'VS Code LaTeX support configured' 'Success'
        return $true
    }
    catch {
        Write-ColorOutput "Failed to configure VS Code LaTeX support: $_" 'Error'
        return $false
    }
}
