function Initialize-Cache {
    [CmdletBinding()]
    param([string]$CachePath = (Join-Path $env:TEMP "WindowsSetup\Cache"))
    
    if (-not (Test-Path $CachePath)) {
        New-Item -ItemType Directory -Path $CachePath -Force | Out-Null
    }
    $script:CACHE_PATH = $CachePath

    if (-not $script:Silent) {
        Write-Log "Cache initialized successfully" -Level "SUCCESS"
    }
    
    return $true
}