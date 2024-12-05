function Mock-WingetInstall {
    param(
        [string]$PackageName,
        [switch]$Force
    )
    
    $script:MockedWingetPackages += $PackageName
    return $true
}

function Mock-WingetUninstall {
    param(
        [string]$PackageName
    )
    
    $script:MockedWingetPackages = $script:MockedWingetPackages |
    Where-Object { $_ -ne $PackageName }
    return $true
}

# Initialize mock state
$script:MockedWingetPackages = @()