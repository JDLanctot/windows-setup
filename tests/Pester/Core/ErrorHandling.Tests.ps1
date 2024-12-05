BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
}

Describe 'Error Handling' {
    Context 'Installation Errors' {
        It 'Should handle component installation failures' {
            # Arrange
            Mock Install-Component { throw "Installation failed" }
            Mock Handle-Error { return $false }

            # Act & Assert
            { Install-Component "TestComponent" } | Should -Throw
            Should -Invoke Handle-Error -Times 1
        }

        It 'Should attempt recovery after failure' {
            # Arrange
            Mock Install-Component { throw "Installation failed" }
            Mock Restore-ComponentState { return $true }

            # Act
            try {
                Install-Component "TestComponent"
            }
            catch {
                # Expected exception
            }

            # Assert
            Should -Invoke Restore-ComponentState -Times 1
        }

        It 'Should log errors appropriately' {
            # Arrange
            Mock Write-Log { }
            Mock Install-Component { throw "Test error" }

            # Act
            try {
                Install-Component "TestComponent"
            }
            catch {
                # Expected exception
            }

            # Assert
            Should -Invoke Write-Log -Times 1 -ParameterFilter {
                $Level -eq "ERROR"
            }
        }
    }

    Context 'Resource Access Errors' {
        It 'Should handle file access errors' {
            # Arrange
            Mock Test-Path { throw "Access denied" }
            Mock Handle-Error { return $false }

            # Act & Assert
            { Test-PathPermissions "C:\test" } | Should -Throw
            Should -Invoke Handle-Error -Times 1
        }
    }

    Context 'Network Errors' {
        It 'Should handle network timeouts' {
            # Arrange
            Mock Start-NetworkOperation { throw "Network timeout" }
            Mock Handle-Error { return $false }

            # Act & Assert
            { Start-NetworkOperation { } } | Should -Throw
            Should -Invoke Handle-Error -Times 1
        }
    }
}