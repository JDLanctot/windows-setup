function Update-InstallationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ComponentName,
        [bool]$Required = $false,
        [hashtable]$AdditionalData
    )
    
    try {
        $stateManager = [StateManager]::GetInstance()
        
        if ($stateManager.IsInstalled($ComponentName)) {
            Write-Log "$ComponentName is already installed and verified" -Level "INFO"
            return $false
        }
        
        $result = $stateManager.AddComponent($ComponentName, $Required)
        if ($result) {
            $component = $stateManager.GetComponent($ComponentName)
            if ($AdditionalData) {
                $component.AdditionalData = $AdditionalData
                $stateManager.Save()
            }
            Write-Log "Successfully updated installation state for $ComponentName" -Level "SUCCESS"
            return $true
        }
        
        throw "Failed to update installation state"
    }
    catch {
        Write-Log "Failed to update installation state for $(ComponentName): $_" -Level "ERROR"
        throw
    }
}