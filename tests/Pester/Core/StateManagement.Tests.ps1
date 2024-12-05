BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
    . $PSScriptRoot/../../Mocks/ChocolateyMock.ps1
}

Describe 'State Management' {
    BeforeEach {
        Initialize-State -TestMode
    }

    AfterEach {
        Clear-State
    }

    Context 'Component State Tracking' {
        It 'Should track installed components' {
            # Arrange
            $component = 'TestComponent'
            $version = '1.0.0'

            # Act
            Save-ComponentState -Name $component -Version $version

            # Assert
            $state = Get-ComponentState -Name $component
            $state.Version | Should -Be $version
            $state.IsInstalled | Should -Be $true
        }

        It 'Should handle version updates' {
            # Arrange
            $component = 'TestComponent'
            $initialVersion = '1.0.0'
            $updatedVersion = '2.0.0'

            # Act
            Save-ComponentState -Name $component -Version $initialVersion
            Save-ComponentState -Name $component -Version $updatedVersion

            # Assert
            $state = Get-ComponentState -Name $component
            $state.Version | Should -Be $updatedVersion
        }
    }

    Context 'Installation Recovery' {
        It 'Should restore previous state on failure' {
            # Arrange
            $component = 'TestComponent'
            $initialVersion = '1.0.0'
            Save-ComponentState -Name $component -Version $initialVersion

            # Act
            $result = Install-Component -Name $component -Force -ErrorAction SilentlyContinue

            # Assert
            $state = Get-ComponentState -Name $component
            $state.Version | Should -Be $initialVersion
        }
    }
}