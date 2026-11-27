Describe 'Git setup on a new PC' {
    BeforeAll {
        $root = Split-Path $PSScriptRoot
        . "$root/functions/Install/Core/Install-Git.ps1"
        . "$root/helpers/Logging/Write-ColorOutput.ps1"
        . "$root/helpers/Logging/Resolve-Error.ps1"
        . "$root/helpers/Logging/Write-StructuredLogging.ps1"
        function Write-Log { param($Message,$Level) }
        function Save-InstallationState { param($Component) }
        function Get-ErrorRecoverySteps {}
        $savedProfile = $env:USERPROFILE
        $savedTemp = $env:TEMP
        $env:USERPROFILE = $TestDrive
        $env:TEMP = $TestDrive
    }
    AfterAll {
        $env:USERPROFILE = $savedProfile
        $env:TEMP = $savedTemp
    }
    It 'completes Git setup and shows identity guidance when the global identity is missing' {
        function git {
            if ($args[0] -ne 'config' -or $args[-1] -notin 'user.name','user.email') {
                throw 'Unexpected Git invocation'
            }
        }
        Mock Write-Log {}
        Mock Save-InstallationState {}
        Install-Git | Should -BeTrue
        Should -Invoke Save-InstallationState -Times 1 -Exactly -ParameterFilter { $Component -eq 'Git' }
        Should -Invoke Write-Log -Times 1 -Exactly -ParameterFilter {
            $Level -eq 'WARN' -and $Message -like '*git config --global user.name "Your Name"*'
        }
    }
    It 'logs a critical command error once and preserves its message' {
        Mock Write-Log {}
        function Invoke-FailingCommand { [CmdletBinding()]param() }
        try { Invoke-FailingCommand unexpected } catch { $record = $_ }
        $WarningPreference = 'Stop'
        { Resolve-Error $record -ComponentName Git -Operation Setup -Critical } |
            Should -Throw '*positional parameter*'
        $entry = Get-Content "$TestDrive/windows_setup_logs/*.jsonl" -Tail 1 | ConvertFrom-Json
        $entry.Data.Command | Should -Be 'Invoke-FailingCommand'
        Should -Invoke Write-Log -Times 0 -Exactly -ParameterFilter { $Message -like 'Error processing error handler*' }
    }
}
