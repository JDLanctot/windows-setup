#requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0' }
Describe 'Windows setup profile orchestration' {
    BeforeAll {
        $root = Split-Path $PSScriptRoot
        $fixture = Join-Path $TestDrive 'windows-setup-main'
        $null = New-Item -ItemType Directory $fixture
        foreach ($item in 'WindowsSetup.psm1','WindowsSetup.psd1','functions','helpers','config','classes') {
            Copy-Item (Join-Path $root $item) $fixture -Recurse
        }
        # Replace every component before import, including components added in future.
        Get-ChildItem "$fixture/functions/Install" -Recurse -Filter '*.ps1' | ForEach-Object {
            Set-Content $_.FullName "function $($_.BaseName) { return `$true }"
        }
        Set-Content "$fixture/functions/Test/Test-Environment.ps1" 'function Test-Environment { @{Success=$true} }'
        Set-Content "$fixture/functions/Test/Test-InstallationState.ps1" 'function Test-InstallationState { $true }'
        $saved = @{}
        foreach ($key in 'TEMP','USERPROFILE','APPDATA','LOCALAPPDATA') {
            $saved[$key] = [Environment]::GetEnvironmentVariable($key)
            [Environment]::SetEnvironmentVariable($key, $TestDrive)
        }
        $module = Import-Module "$fixture/WindowsSetup.psd1" -PassThru -ErrorAction Stop
    }
    AfterAll {
        if ($module) { Remove-Module $module }
        foreach ($key in $saved.Keys) { [Environment]::SetEnvironmentVariable($key,$saved[$key]) }
    }
    It 'finishes <profile> with all expected components exactly once' -ForEach @(
        @{profile='Minimal'; groups=@('Core')}
        @{profile='Standard'; groups=@('Core','Shell','Development','Tools')}
        @{profile='Full'; groups=@('Core','Shell','Development','Tools','Optional','DeepLearning','WebDev','JuliaDev')}
        @{profile='DataScience'; groups=@('Core','DeepLearning')}
        @{profile='WebDevelopment'; groups=@('Core','WebDev')}
        @{profile='JuliaDevelopment'; groups=@('Core','JuliaDev')}
    ) {
        $raw = Import-PowerShellDataFile "$fixture/config/config.psd1"
        $expected = @($(foreach ($group in $groups) { $raw.InstallationGroups[$group].Steps.Name })
            if ($profile -ne 'Minimal') { 'Dotfiles' }) | Sort-Object -Unique
        $result = Start-Installation -InstallationType $profile -Silent 6>$null
        ($result.Successful | Sort-Object) -join ',' | Should -Be ($expected -join ',')
        $result.Total | Should -Be $expected.Count
        if ($profile -ne 'Minimal') { $result.Successful[-1] | Should -Be Dotfiles }
        if ($profile -in 'Standard','Full') {
            foreach ($tool in 'OpenCode','Rtk','GitHubCli','Jq','Uv') { $result.Successful | Should -Contain $tool }
        }
        if ($profile -eq 'DataScience') { $result.Successful | Should -Contain Uv }
        $result.Successful | Should -Not -Contain Conda
    }
    It 'honors a custom selection and required core prerequisites' {
        $result = Start-Installation -InstallationType Custom -CustomComponents Rtk -Silent 6>$null
        ($result.Successful -join ',') | Should -Be 'Chocolatey,Git,Rtk'
    }
    It 'propagates a required failure even when the installer emits progress output' {
        Mock Install-Git -ModuleName WindowsSetup { 'installer output'; $false }
        { Start-Installation Minimal -Silent 6>$null } | Should -Throw '*Git*'
    }

    It 'builds a reusable release archive with the module and its runtime files' {
        Copy-Item "$root/build.ps1","$root/install.ps1","$root/README.md","$root/LICENSE" $fixture
        $manifest = Get-FileHash "$fixture/WindowsSetup.psd1"
        Push-Location $fixture
        try {
            & ./build.ps1 -Version 1.2.3 -OutputPath "$TestDrive/package" -ErrorAction Stop
            & ./build.ps1 -Version 1.2.3 -OutputPath "$TestDrive/package" -ErrorAction Stop
        }
        finally { Pop-Location }
        $archive = "$TestDrive/package/WindowsSetup.zip"
        Expand-Archive $archive "$TestDrive/release"
        foreach ($file in 'classes/StateManager.ps1','helpers/Logging/Write-Log.ps1','functions/Core/Start-Installation.ps1','config/uv-profile.ps1','install.ps1') {
            Join-Path "$TestDrive/release" $file | Should -Exist
        }
        (Import-PowerShellDataFile "$TestDrive/release/WindowsSetup.psd1").ModuleVersion | Should -Be '1.2.3'
        (Get-FileHash "$fixture/WindowsSetup.psd1").Hash | Should -Be $manifest.Hash
    }

    It 'runs bootstrap through the script entry point using a local fixture archive' {
        # Only the disposable copy bypasses elevation. The child imports the stubbed module.
        $entry = Get-Content "$root/install.ps1" -Raw
        $entry -replace '(?im)^#Requires -RunAsAdministrator.*$', '' | Set-Content "$fixture/install.ps1"
        $archive = "$TestDrive/fixture.zip"
        Compress-Archive -LiteralPath $fixture -DestinationPath $archive
        $driver = "$TestDrive/driver.ps1"
        Set-Content $driver @(
            'param($bootstrap, $archive)'
            '$ErrorActionPreference = "Stop"'
            'function Invoke-WebRequest { param($Uri,$OutFile) Copy-Item $archive $OutFile }'
            '& $bootstrap -InstallationType Standard'
        )
        $existing = New-Item -ItemType Directory "$TestDrive/windows-setup" -Force
        Set-Content "$existing/sentinel" 'keep'
        $output = & pwsh -NoProfile -NonInteractive -File $driver "$root/bootstrap.ps1" $archive 2>&1
        $LASTEXITCODE | Should -Be 0 -Because ($output -join ' ')
        ($output -join ' ') | Should -Match 'Installation Summary'
        ($output -join ' ') | Should -Match 'Dotfiles'
        Get-Content "$existing/sentinel" | Should -Be keep
    }

    It 'installs <name> by exact package ID, verifies the CLI, and reuses it on rerun' -ForEach @(
        @{name='OpenCode'; package='Anomaly.OpenCode'; cli='opencode'}
        @{name='GitHubCli'; package='GitHub.cli'; cli='gh'}
        @{name='Rtk'; package='rtk-ai.rtk'; cli='rtk'}
        @{name='Jq'; package='jqlang.jq'; cli='jq'}
    ) {
        $calls = [Collections.Generic.List[string]]::new()
        $result = & $module {
            param($source, $name, $cli, $calls)
            . "$source/functions/Install/Tools/Install-$name.ps1"
            function winget {
                $calls.Add(($args -join ' '))
                $global:LASTEXITCODE = 0
                'simulated package manager output'
            }
            function Get-Command {
                param($Name)
                if ($Name -ne $cli) { throw "Unexpected command lookup $Name" }
                if ($calls.Count) { return @{Name=$cli} }
            }
            function RefreshPath {}
            function Update-InstallationState {}
            function choco { throw 'Unexpected Chocolatey call' }
            function npm { throw 'Unexpected npm call' }
            & "Install-$name"
            & "Install-$name"
        } $root $name $cli $calls 6>$null
        $result | Should -Be @($true,$true)
        $calls.Count | Should -Be 1
        $calls[0] | Should -Be "install --id $package --exact --source winget --accept-source-agreements --accept-package-agreements"
    }

    It 'runs a script-block post-install task before verifying the configured path' {
        $marker = "$TestDrive/post-install"
        $result = & $module {
            param($marker)
            function choco { $global:LASTEXITCODE = 0 }
            function RefreshPath {}
            function Resolve-Error {}
            function Update-InstallationState {}
            function Get-Command { $true }
            $spec = @{
                Type='default'; Required=$true
                PostInstall={ Set-Content $marker 'ready'; $true }
                Verify=@{Command='example'; Config=@{Path=$marker}}
            }
            Install-Component Example $spec -Force -RetryCount 0
        } $marker 6>$null
        $result | Should -BeTrue
    }

    It 'rejects a package-manager success when the executable is missing' {
        {
            & $module {
                function Get-Command {}
                function winget { $global:LASTEXITCODE = 0 }
                function RefreshPath {}
                function Resolve-Error {}
                $spec = ($script:Config.CliTools | Where-Object Name -eq OpenCode).InstallSpec
                Install-Component OpenCode $spec -RetryCount 0
            } 6>$null
        } | Should -Throw '*command not found after installation*'
    }

    It 'reloads recorded components after restarting the module' {
        & $module {
            $manager = [StateManager]::GetInstance()
            $manager.Components['Example'] = [ComponentState]::new('Example', @{Required=$true; Alias='example'})
            $manager.Save()
            $restored = [StateManager]::new($manager.StateFile)
            $restored.GetComponent('Example').InstallSpec.Alias
        } | Should -Be example
    }

    It 'provisions a fresh Chocolatey installation through the custom handler' {
        $tracker = @{installed=$false}
        $result = & $module {
            param($tracker)
            function RefreshPath {}
            function Update-InstallationState {}
            function Resolve-Error {}
            $spec = @{
                Type='custom'; Required=$true; Alias='fixture-choco'
                CustomInstall={ $tracker.installed = $true; $true }
                Verify=@{Script={ $tracker.installed }}
            }
            Install-Component 'FixtureChocolatey' $spec -Force -RetryCount 0
        } $tracker 6>$null
        $tracker.installed | Should -BeTrue
        $result | Should -BeTrue
    }

    It 'installs the uv helpers alongside the downloaded profile on repeated setup' {
        $source = New-Item -ItemType Directory "$TestDrive/profile-source"
        Set-Content "$source/profile.ps1" @('function upstreamSetting { 42 }','function ca { "legacy" }')
        $target = "$TestDrive/profile destination/profile.ps1"
        & $module {
            param($source,$target)
            $script:CONFIG_PATHS = @{powershell=@{source='profile.ps1';target=$target;type='file';handler='default'}}
            Initialize-Dotfile powershell $source
            Initialize-Dotfile powershell $source
        } $source $target 6>$null | Should -Be @($true,$true)
        . $target
        upstreamSetting | Should -Be 42
        (Get-Command ca).Definition | Should -Match 'uv venv'
        (Get-Command caz).CommandType | Should -Be Function
        @(Select-String -Path $target -Pattern 'uv-profile.ps1').Count | Should -Be 1
    }

    It 'installs the Windows locale fix alongside the upstream Neovim config' {
        $source = New-Item -ItemType Directory "$TestDrive/nvim-source"
        $null = New-Item -ItemType Directory "$source/nvim"
        Set-Content "$source/nvim/init.lua" '-- upstream config'
        $target = "$TestDrive/nvim-destination"
        & $module {
            param($source,$target)
            $script:CONFIG_PATHS = @{nvim=@{source='nvim';target=$target;type='directory';handler='neovim'}}
            Initialize-Dotfile nvim $source
        } $source $target 6>$null | Should -BeTrue
        Get-Content "$target/init.lua" | Should -Be '-- upstream config'
        (Get-FileHash "$target/after/plugin/windows-locale.lua").Hash |
            Should -Be (Get-FileHash "$root/config/nvim/after/plugin/windows-locale.lua").Hash
    }

    It 'copies dotfiles using a temporary source and destination' {
        $source = New-Item -ItemType Directory "$TestDrive/sample"
        Set-Content "$source/test.toml" 'fixture'
        $target = "$TestDrive/destination/test.toml"
        $ok = & $module {
            param($source,$target)
            $script:CONFIG_PATHS = @{sample=@{source='test.toml';target=$target;type='file';handler='default'}}
            Initialize-Dotfile -Name sample -TempPath $source
        } $source $target 6>$null
        $ok | Should -BeTrue
        Get-Content $target | Should -Be fixture
    }
}
