Describe 'Bundled Python profile helpers' {
    BeforeAll {
        . (Join-Path (Split-Path $PSScriptRoot) 'config/uv-profile.ps1')
    }
    It 'creates an environment once and activates it on each call' {
        $envPath = "$TestDrive/project space"
        $calls = [Collections.Generic.List[string]]::new()
        function uv {
            $calls.Add(($args -join ' '))
            $null = New-Item -ItemType Directory "$envPath/Scripts" -Force
            Set-Content "$envPath/Scripts/Activate.ps1" "'activated'"
            $global:LASTEXITCODE = 0
        }
        ca $envPath | Should -Be activated
        ca $envPath | Should -Be activated
        $calls | Should -Be @("venv $envPath")
    }
    It 'stops on uv creation failure' {
        function uv { $global:LASTEXITCODE = 1 }
        { ca "$TestDrive/absent" } | Should -Throw '*could not create*'
    }
}
