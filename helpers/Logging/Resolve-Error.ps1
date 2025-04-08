function Resolve-Error {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [string]$ComponentName = "Unknown",
        [string]$Operation = "Unknown",
        [hashtable]$InstallSpec,
        [switch]$Critical,
        [switch]$Continue
    )
    
    try {
        # Build detailed error message
        $errorDetails = @{
            Component  = $ComponentName
            Operation  = $Operation
            Message    = $ErrorRecord.Exception.Message
            Category   = $ErrorRecord.CategoryInfo.Category
            StackTrace = $ErrorRecord.ScriptStackTrace
            LineNumber = $ErrorRecord.InvocationInfo.ScriptLineNumber
            Command    = $ErrorRecord.InvocationInfo.MyCommand
            Timestamp  = Get-Date
        }

        # Check for common errors and suggest recovery
        $recoverySteps = Get-ErrorRecoverySteps -ErrorRecord $ErrorRecord -ComponentName $ComponentName
        
        # Log structured error
        Write-StructuredLog -Message "Error in $Operation" `
            -Level "ERROR" `
            -Component $ComponentName `
            -Data $errorDetails

        # Handle critical errors
        if ($Critical) {
            Write-Log "CRITICAL ERROR: $($errorDetails.Message)" -Level "ERROR"
            
            if ($recoverySteps) {
                Write-Log "Suggested recovery:" -Level "INFO"
                foreach ($step in $recoverySteps) {
                    Write-Log " - $step" -Level "INFO"
                }
            }
            
            if (-not $Continue) {
                throw $ErrorRecord
            }
        }
        else {
            Write-Log "NON-CRITICAL ERROR: $($errorDetails.Message)" -Level "WARN"
            if ($recoverySteps) {
                Write-Log "Suggested recovery:" -Level "INFO"
                foreach ($step in $recoverySteps) {
                    Write-Log " - $step" -Level "INFO"
                }
            }
        }

        return $errorDetails
    }
    catch {
        # Fallback logging if structured logging fails
        Write-Log "Error processing error handler: $_" -Level "ERROR"
        throw
    }
}