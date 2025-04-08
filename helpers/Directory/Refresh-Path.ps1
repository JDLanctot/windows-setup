function RefreshPath {
    # This stores the original PATH value to compare with later
    $originalPath = $env:Path
    
    # Get updated PATH from system
    $newPath = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
    
    # Only update if there's a change
    if ($originalPath -ne $newPath) {
        $env:Path = $newPath
        Write-Log "PATH environment variable refreshed" -Level "DEBUG"
    }
}