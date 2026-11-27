function Assert-NoInstallerRestart {
    param([string]$Manager, [int]$Code)

    $restartCodes = if ($Manager -eq 'Chocolatey') {
        1641, 3010, 350, 1604
    } else {
        # WinGet HRESULTs for reboot required to finish, required to install, or initiated.
        0x8A150109, 0x8A15010A, 0x8A15010B
    }
    if ($Code -in $restartCodes) {
        $signal = [OperationCanceledException]::new("$Manager reported a restart (exit $Code).")
        $signal.Data['InstallerRestart'] = $Code
        throw $signal
    }
}
