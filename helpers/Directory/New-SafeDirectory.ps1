# Example of improved user input handling for when creating a new item
function New-SafeDirectory {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [switch]$Force
    )
    
    if (-not (Test-Path $Path)) {
        Write-ColorOutput "Creating directory: $Path" "Status"
        try {
            New-Item -ItemType Directory -Path $Path -Force:$Force -ErrorAction Stop
            Write-ColorOutput "Successfully created directory: $Path" "Success"
            return $true
        }
        catch {
            Write-ColorOutput "Failed to create directory: $Path - $_" "Error"
            return $false
        }
    }
    else {
        Write-ColorOutput "Directory already exists: $Path" "Status"
        return $true
    }
}