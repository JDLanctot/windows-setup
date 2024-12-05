Describe 'Installation Flow' {
    Context 'Order and Dependencies' {
        It 'Should install dependencies before dependent components' {
            # Arrange
            $installOrder = @()
            Mock Install-Component { 
                $installOrder += $Name
                return $true 
            }

            # Act
            Start-Installation -Profile "Standard"

            # Assert
            $gitIndex = $installOrder.IndexOf("git")
            $neovimIndex = $installOrder.IndexOf("neovim")
            $gitIndex | Should -BeLessThan $neovimIndex
        }

        It 'Should handle optional component failures' {
            # Arrange
            Mock Install-Component { 
                if ($Name -eq "optional-component") { 
                    throw "Installation failed" 
                }
                return $true
            }

            # Act
            $result = Start-Installation -Profile "Standard"

            # Assert
            $result.FailedComponents | Should -Contain "optional-component"
            $result.Success | Should -Be $true
        }
    }

    Context 'Rollback' {
        It 'Should rollback all changes on critical failure' {
            # Arrange
            $systemState = New-SystemStateSnapshot
            Mock Install-Component { 
                if ($Name -eq "critical-component") { 
                    throw "Critical failure" 
                }
            }

            # Act
            Start-Installation -Profile "Minimal" -ErrorAction SilentlyContinue

            # Assert
            Compare-SystemState -State1 $systemState -State2 (New-SystemStateSnapshot) |
            Should -Be $true
        }
    }
}