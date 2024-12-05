BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
    . $PSScriptRoot/../../Mocks/ChocolateyMock.ps1
}

Describe 'Neovim Installation' {
    BeforeEach {
        Mock Install-Component { return $true }
        Mock Get-Command { return $null }
        Mock Test-Path { return $false }
    }

    Context 'Installation Process' {
        It 'Should install Neovim and its dependencies' {
            # Arrange
            Mock Test-PathPermissions { return $true }
            Mock Get-ComponentSpec {
                return @{
                    name         = "neovim"
                    version      = "0.9.0"
                    dependencies = @("git")
                }
            }

            # Act
            $result = Install-Neovim

            # Assert
            $result | Should -Be $true
            Should -Invoke Install-Component -Times 1 -ParameterFilter {
                $Name -eq "neovim"
            }
        }

        It 'Should create necessary directories' {
            # Arrange
            Mock New-Item { return $true }

            # Act
            Install-Neovim

            # Assert
            Should -Invoke New-Item -Times 1 -ParameterFilter {
                $Path -like "*/.config/nvim*"
            }
        }

        It 'Should handle plugin installation' {
            # Arrange
            Mock Start-Process { return @{ ExitCode = 0 } }

            # Act
            $result = Install-Neovim

            # Assert
            $result | Should -Be $true
            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $ArgumentList -like "*+Lazy! sync*"
            }
        }
    }

    Context 'Validation' {
        It 'Should verify Neovim installation' {
            # Arrange
            Mock Get-Command { return @{ Version = "0.9.0" } }

            # Act & Assert
            Test-InstallationState "Neovim" | Should -Be $true
        }
    }
}