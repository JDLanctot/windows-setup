Describe 'Installation environment diagnostics' {
    BeforeAll {
        . "$PSScriptRoot/../functions/Test/Test-Environment.ps1"
        $script:Config = @{ MinimumRequirements = @{
            PSVersion = '7.0'; WindowsVersion = '10.0'; RequiredDiskSpaceGB = 10
        } }
    }

    It 'reports available and required free space' {
        Mock Get-PSDrive { @{ Free = 3GB } }
        $result = Test-Environment -Requirements
        $result.Success | Should -BeFalse
        $result.Errors -join ' ' | Should -Match '3.*GB.*10.*GB'
    }

    It 'reports the exact directory that failed a write check' {
        Mock Set-Content { throw 'Access denied by fixture' }
        Mock Remove-Item { throw 'Unexpected removal' }
        $result = Test-Environment -Permissions
        $result.Success | Should -BeFalse
        $result.Errors -join ' ' | Should -Match ([regex]::Escape($env:LOCALAPPDATA))
        $result.Errors -join ' ' | Should -Match 'Access denied by fixture'
    }
}
