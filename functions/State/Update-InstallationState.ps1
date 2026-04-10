function Update-InstallationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComponentName,
        [hashtable]$InstallSpec,
        [bool]$Required = $false,
        [hashtable]$AdditionalData
    )
    
    try {
        $stateManager = [StateManager]::GetInstance()
        
        if ($stateManager.IsInstalled($ComponentName)) {
            Write-Log "$ComponentName is already installed and verified" -Level "INFO"
            return $false
        }

        if (-not $InstallSpec) {
            $InstallSpec = @{
                Required = $Required
            }
        }

        $component = [ComponentState]::new($ComponentName, $InstallSpec)
        $component.Required = $Required
        if ($AdditionalData) {
            $component.AdditionalData = $AdditionalData
        }

        $result = $stateManager.AddComponent($component)
        if ($result) {
            Save-InstallationState -Component $ComponentName -AdditionalData $AdditionalData | Out-Null
            Write-Log "Successfully updated installation state for $ComponentName" -Level "SUCCESS"
            return $true
        }
        
        throw "Failed to update installation state"
    }
    catch {
        Write-Log "Failed to update installation state for ${ComponentName}: $_" -Level "ERROR"
        throw
    }
}
