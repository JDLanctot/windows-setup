BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
    . $PSScriptRoot/../../Mocks/ChocolateyMock.ps1
}

Describe 'Git Installation' {
    BeforeEach {
        Mock Install-Component { return $true }
        Mock Get-Command { return $null }
    }

    Context 'Installation Process' {
        It 'Should install Git' {
            # Arrange
            Mock Get-ComponentSpec {
                return @{
                    name         = "git"
                    version      = "2.34.0"
                    dependencies = @()
                }
            }

            # Act
            $result = Install-Git

            # Assert
            $result | Should -Be $true
            Should -Invoke Install-Component -Times 1 -ParameterFilter {
                $Name -eq "git"
            }
        }

        It 'Should configure Git user settings' {
            # Arrange
            $testEmail = "test@example.com"
            $testName = "Test User"
            Mock Get-StoredCredential { return $null }
            Mock Read-Host { return $testEmail } -ParameterFilter { $Prompt -like "*email*" }
            Mock Read-Host { return $testName } -ParameterFilter { $Prompt -like "*name*" }

            # Act
            $result = Install-Git

            # Assert
            $result | Should -Be $true
            Should -Invoke Read-Host -Times 2
        }

        It 'Should set up SSH key' {
            # Arrange
            Mock Test-Path { return $false } -ParameterFilter { $Path -like "*/.ssh/*" }
            Mock New-Item { return $true }
            Mock Start-Process { return @{ ExitCode = 0 } }

            # Act
            $result = Install-Git

            # Assert
            $result | Should -Be $true
            Should -Invoke New-Item -Times 1 -ParameterFilter {
                $Path -like "*/.ssh"
            }
            Should -Invoke Start-Process -Times 1 -ParameterFilter {
                $ArgumentList -like "*-t ed25519*"
            }
        }
    }

    Context 'Validation' {
        It 'Should verify Git installation and configuration' {
            # Arrange
            Mock Get-Command { return @{ Version = "2.34.0" } }
            Mock Test-Path { return $true } -ParameterFilter { $Path -like "*/.gitconfig" }

            # Act & Assert
            Test-InstallationState "Git" | Should -Be $true
        }
    }
}