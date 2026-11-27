Describe 'Installer temporary file cleanup' {
    BeforeAll {
        $root = Split-Path $PSScriptRoot
        . "$root/functions/Install/Core/Install-NerdFonts.ps1"
        . "$root/functions/Install/Core/Install-Dotfiles.ps1"
        function Write-ColorOutput {}
        function Write-Log {}
        function Install-Component {
            param($Name,$InstallSpec)
            & $InstallSpec.CustomInstall
        }
        function Initialize-Dotfile { $true }
        $script:CONFIG_PATHS = @{sample=@{}}
    }
    BeforeEach {
        $oldTemp = $env:TEMP
        $oldLocal = $env:LOCALAPPDATA
        $env:TEMP = (New-Item -ItemType Directory "$TestDrive/temp-$([guid]::NewGuid())").FullName
        $env:LOCALAPPDATA = (New-Item -ItemType Directory "$TestDrive/local-$([guid]::NewGuid())").FullName
    }
    AfterEach {
        $env:TEMP = $oldTemp
        $env:LOCALAPPDATA = $oldLocal
    }

    It 'cleans up the font download and preserves other files (failure=<fail>)' -ForEach @(
        @{fail=$false}, @{fail=$true}
    ) {
        $null = New-Item -ItemType Directory "$env:TEMP/JetBrainsMono"
        Set-Content "$env:TEMP/JetBrainsMono/keep" 'existing'
        Set-Content "$env:TEMP/JetBrainsMono.zip" 'existing'
        Mock Invoke-WebRequest { Set-Content $OutFile 'fixture archive' }
        Mock Expand-Archive {
            $null = New-Item -ItemType Directory $DestinationPath -Force
            Set-Content "$DestinationPath/JetBrainsMonoFixture.ttf" 'fixture font'
            if ($fail) { throw 'extraction failed' }
        }
        if ($fail) { { Install-NerdFonts } | Should -Throw '*extraction failed*' }
        else {
            Install-NerdFonts | Should -BeTrue
            "$env:LOCALAPPDATA/Microsoft/Windows/Fonts/JetBrainsMonoFixture.ttf" | Should -Exist
        }
        Get-Content "$env:TEMP/JetBrainsMono/keep" | Should -Be existing
        Get-Content "$env:TEMP/JetBrainsMono.zip" | Should -Be existing
        @(Get-ChildItem $env:TEMP -Force).Count | Should -Be 2
    }

    It 'removes a complete or partial dotfiles clone (failure=<fail>)' -ForEach @(
        @{fail=$false}, @{fail=$true}
    ) {
        function git {
            $clone = $args[-1]
            $null = New-Item -ItemType Directory $clone
            Set-Content "$clone/sample" 'partial download'
            $global:LASTEXITCODE = [int]$fail
        }
        Install-Dotfiles | Should -Be (-not $fail)
        @(Get-ChildItem $env:TEMP -Force).Count | Should -Be 0
    }

    It 'propagates a required dotfile failure even if another copy succeeds' {
        $script:CONFIG_PATHS = @{good=@{source='a'}; bad=@{source='b'}}
        function git { $null = New-Item -ItemType Directory $args[-1]; $global:LASTEXITCODE = 0 }
        function Initialize-Dotfile { param($Name,$TempPath) $Name -eq 'good' }
        Install-Dotfiles | Should -BeFalse
    }

    It 'removes a partial bootstrap download on failure' {
        Mock Invoke-WebRequest {
            Set-Content $OutFile 'partial download'
            throw 'download failed'
        }
        { & "$root/bootstrap.ps1" -InstallationType Minimal } | Should -Throw '*download failed*'
        @(Get-ChildItem $env:TEMP -Force).Count | Should -Be 0
    }
}
