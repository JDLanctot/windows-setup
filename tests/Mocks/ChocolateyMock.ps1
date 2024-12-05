function Mock-ChocolateyInstall {
    param(
        [string]$PackageName,
        [switch]$Force
    )
    
    $script:MockedInstalledPackages += $PackageName
    return $true
}

function Mock-ChocolateyUninstall {
    param(
        [string]$PackageName
    )
    
    $script:MockedInstalledPackages = $script:MockedInstalledPackages | 
    Where-Object { $_ -ne $PackageName }
    return $true
}

# Initialize mock state
$script:MockedInstalledPackages = @()