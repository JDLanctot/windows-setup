function Install-JuliaExtension {
    [CmdletBinding()]
    param()

    try {
        Write-ColorOutput "Installing Julia extension for VS Code..." "Status"
        
        # Ensure VS Code is installed first
        if (-not (Get-Command -Name code -ErrorAction SilentlyContinue)) {
            Write-ColorOutput "VS Code is required for Julia extension installation" "Error"
            Write-ColorOutput "Please install VS Code first by running 'Install-VSCode'" "Error"
            return $false
        }
        
        # Check if extension is already installed
        $extensions = & code --list-extensions 2>$null
        if ($extensions -contains "julialang.language-julia") {
            Write-ColorOutput "Julia extension is already installed in VS Code" "Status"
            return $true
        }
        
        # Install Julia extension for VS Code
        Write-ColorOutput "Running VS Code extension installation command..." "Status"
        $result = & code --install-extension julialang.language-julia 2>&1
        
        # Verify installation
        $extensions = & code --list-extensions 2>$null
        if ($extensions -contains "julialang.language-julia") {
            Write-ColorOutput "Julia extension successfully installed for VS Code" "Success"
            return $true
        } else {
            Write-ColorOutput "Failed to install Julia extension: $result" "Error"
            return $false
        }
    }
    catch {
        Write-ColorOutput "Error installing Julia extension: $_" "Error"
        return $false
    }
}