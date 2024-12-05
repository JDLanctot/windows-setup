# build.ps1
[CmdletBinding()]
param(
    [string]$OutputPath = "./out",
    [string]$Version = "1.0.0"
)

# Create output directory
New-Item -ItemType Directory -Force -Path $OutputPath

# Update module version
$manifestPath = "./WindowsSetup.psd1"
Update-ModuleManifest -Path $manifestPath -ModuleVersion $Version

# Copy files to output
$files = @(
    "WindowsSetup.psd1"
    "WindowsSetup.psm1"
    "install.ps1"
    "README.md"
    "LICENSE"
)

foreach ($file in $files) {
    Copy-Item $file $OutputPath
}

# Copy lib directory
Copy-Item -Path "./lib" -Destination "$OutputPath/lib" -Recurse

# Create module package
Compress-Archive -Path "$OutputPath/*" -DestinationPath "$OutputPath/WindowsSetup.zip"