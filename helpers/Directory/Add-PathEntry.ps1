function Add-PathEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PathEntry,
        [ValidateSet('User', 'Machine')]
        [string]$Scope = 'User'
    )

    if ([string]::IsNullOrWhiteSpace($PathEntry)) {
        return $false
    }

    $normalizedPathEntry = $PathEntry.Trim().TrimEnd('\')
    $currentPath = [Environment]::GetEnvironmentVariable('Path', $Scope)
    $entries = @()

    if (-not [string]::IsNullOrWhiteSpace($currentPath)) {
        $entries = @(
            $currentPath -split ';' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    foreach ($entry in $entries) {
        if ($entry.TrimEnd('\') -ieq $normalizedPathEntry) {
            return $false
        }
    }

    [Environment]::SetEnvironmentVariable('Path', (@($entries + $PathEntry) -join ';'), $Scope)
    return $true
}
