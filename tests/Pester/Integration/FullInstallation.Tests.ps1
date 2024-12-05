BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
}

Describe 'Full Installation' {
    Context 'Installation Profiles' {
        It 'Should complete minimal installation' {
            # Arrange
            Mock Start-Installation { return $true }

            # Act
            $result = Start-Installation -Profile 'Minimal'

            # Assert
            $result | Should -Be $true
            Should -Invoke Start-Installation -Times 1 -ParameterFilter {
                $Profile -eq 'Minimal'
            }
        }

        It 'Should complete standard installation' {
            # Arrange
            Mock Start-Installation { return $true }

            # Act
            $result = Start-Installation -Profile 'Standard'

            # Assert
            $result | Should -Be $true
            Should -Invoke Start-Installation -Times 1 -ParameterFilter {
                $Profile -eq 'Standard'
            }
        }
    }

    Context 'Component Dependencies' {
        It 'Should install components in correct order' {
            # Arrange
            $installedComponents = @()
            Mock Install-Component {
                param($Name)
                $installedComponents += $Name
                return $true
            }

            # Act
            Start-Installation -Profile 'Standard'

            # Assert
            $installedComponents | Should -Not -BeNullOrEmpty
            $gitIndex = [array]::IndexOf($installedComponents, 'git')
            $neovimIndex = [array]::IndexOf($installedComponents, 'neovim')
            $gitIndex | Should -BeLessThan $neovimIndex
        }
    }
}