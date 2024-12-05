BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
    . $PSScriptRoot/../../Mocks/ChocolateyMock.ps1
}

Describe 'Node.js Installation' {
    BeforeEach {
        Mock Install-Component { return $true }
        Mock Get-Command { return $null }
    }

    Context 'Installation Process' {
        It 'Should install Node.js LTS version' {
            # Arrange
            Mock Get-ComponentSpec {
                return @{
                    name         = "node"
                    version      = "18.0.0"
                    dependencies = @()
                }
            }

            # Act
            $result = Install-Node

            # Assert
            $result | Should -Be $true
            Should -Invoke Install-Component -Times 1 -ParameterFilter {
                $Name -eq "nodejs-lts"
            }
        }

        It 'Should install pnpm' {
            # Arrange
            Mock Start-Process { return @{ ExitCode = 0 } }
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "node" }

            # Act
            $result = Install-Node

            # Assert
            $result | Should -Be $true
            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $ArgumentList -like "*install -g pnpm*"
            }
        }
    }

    Context 'Validation' {
        It 'Should verify Node.js and pnpm installation' {
            # Arrange
            Mock Get-Command { return @{ Version = "18.0.0" } } -ParameterFilter { $Name -eq "node" }
            Mock Get-Command { return $true } -ParameterFilter { $Name -eq "pnpm" }

            # Act & Assert
            Test-InstallationState "Node" | Should -Be $true
        }
    }
}