function Install-PNPM {
    [CmdletBinding()]
    param()

    try {
        Write-ColorOutput "Installing PNPM..." "Status"
        
        # Ensure Node.js is installed first
        if (-not (Get-Command -Name node -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "Node.js is required for PNPM installation" "Error"
            return $false
        }
        
        # Check if already installed
        if (Get-Command -Name pnpm -ErrorAction SilentlyContinue) {
            Write-ColorOutput "PNPM is already installed" "Status"
            return $true
        }
        
        # Install pnpm globally using npm
        npm install -g pnpm
        
        # Verify installation
        if (Get-Command -Name pnpm -ErrorAction SilentlyContinue) {
            Write-ColorOutput "PNPM installed successfully" "Success"
            return $true
        } else {
            Write-ColorOutput "PNPM installation verification failed" "Error"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Failed to install PNPM: $_" "Error"
        return $false
    }
}