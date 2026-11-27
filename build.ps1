[CmdletBinding()]
param(
    [string]$OutputPath = "./out",
    [version]$Version = "1.0.0"
)

$ErrorActionPreference = 'Stop'
$null = New-Item -ItemType Directory -Force -Path $OutputPath
$items = @(
    'WindowsSetup.psd1', 'WindowsSetup.psm1', 'install.ps1', 'README.md', 'LICENSE',
    'classes', 'config', 'functions', 'helpers'
)
foreach ($item in $items) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $item) -Destination $OutputPath -Recurse -Force
}

Update-ModuleManifest -Path (Join-Path $OutputPath 'WindowsSetup.psd1') -ModuleVersion $Version
$paths = foreach ($item in $items) { Join-Path $OutputPath $item }
Compress-Archive -LiteralPath $paths -DestinationPath (Join-Path $OutputPath 'WindowsSetup.zip') -Force
