[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Create temporary directory
$setupDir = "$env:TEMP\windows-setup"
if (Test-Path $setupDir) {
    try {
        Remove-Item -Path $setupDir -Recurse -Force -ErrorAction Stop
    }
    catch {
        Write-Host "Warning: Could not remove existing directory. Will try to use it anyway."
    }
}
New-Item -ItemType Directory -Path $setupDir -Force | Out-Null

# Download and extract setup files
$repo = "JDLanctot/windows-setup"
$branch = "main"
$url = "https://github.com/$repo/archive/refs/heads/$branch.zip"
$zipFile = "$setupDir\windows-setup.zip"

Invoke-WebRequest -Uri $url -OutFile $zipFile
Expand-Archive -Path $zipFile -DestinationPath $setupDir -Force

# Navigate to extracted directory and run install.ps1
$extractedDir = (Get-ChildItem $setupDir -Directory)[0].FullName
Set-Location $extractedDir
& .\install.ps1

# Cleanup
Set-Location $env:USERPROFILE
try {
    Remove-Item -Path $setupDir -Recurse -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Host "Warning: Could not clean up temp directory. You may want to manually delete: $setupDir"
}