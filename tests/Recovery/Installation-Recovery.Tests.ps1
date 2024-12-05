BeforeAll {
    Import-Module $PSScriptRoot/../../WindowsSetup.psd1 -Force
}

Describe 'Installation Recovery' {
    BeforeEach {
        $script:testState = Save-InstallationState
    }

    AfterEach {
        Restore-InstallationState $script:testState
    }

    It 'Should recover from failed component installation' {
        # Arrange
        Mock Install-Component { throw "Installation failed" } -ParameterFilter {
            $Name -eq 'neovim'
        }
        
        # Act
        $result = Start-Installation -Profile 'Minimal' -ErrorAction SilentlyContinue
        
        # Assert
        $state = Get-InstallationState
        $state.Failed | Should -Contain 'neovim'
        $state.Recovered | Should -Be $true
    }

    It 'Should maintain system state on failure' {
        # Arrange
        $initialState = Get-SystemState
        Mock Install-Component { throw "Fatal error" }
        
        # Act
        Start-Installation -Profile 'Minimal' -ErrorAction SilentlyContinue
        
        # Assert
        $currentState = Get-SystemState
        Compare-SystemState $initialState $currentState | Should -Be $true
    }
}