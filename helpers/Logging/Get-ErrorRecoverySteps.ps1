function Get-ErrorRecoverySteps {
    param(
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$ComponentName
    )
    
    $message = $ErrorRecord.Exception.Message
    $recoverySteps = @()
    
    # Network errors
    if ($message -match "network|connectivity|unreachable|timed out") {
        $recoverySteps += "Check your internet connection"
        $recoverySteps += "Verify proxy settings if using a proxy"
        $recoverySteps += "Try running the installation again"
    }
    
    # Permission errors
    elseif ($message -match "access is denied|permission|unauthorized") {
        $recoverySteps += "Run the script with administrator privileges"
        $recoverySteps += "Check if any processes are locking files"
    }
    
    # Component-specific errors
    elseif ($ComponentName -eq "Git") {
        $recoverySteps += "Ensure no Git processes are running"
        $recoverySteps += "Check if Git is already installed but in a different location"
    }
    elseif ($ComponentName -eq "Node") {
        $recoverySteps += "Try removing any existing Node.js installations first"
        $recoverySteps += "Check for conflicting global npm packages"
    }
    elseif ($ComponentName -eq "Neovim") {
        $recoverySteps += "Make sure no Neovim instances are running"
        $recoverySteps += "Try cleaning the Neovim plugin cache directory"
    }
    
    # Default recovery steps
    if ($recoverySteps.Count -eq 0) {
        $recoverySteps += "Try running the installation again"
        $recoverySteps += "Check the log file for more details"
    }
    
    return $recoverySteps
}