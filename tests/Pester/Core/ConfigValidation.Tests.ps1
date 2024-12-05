Describe 'Configuration Validation' {
    Context 'Component Specifications' {
        It 'Should validate required fields' {
            # Arrange
            $spec = @{
                Name = "TestComponent"
                # Missing Version
            }

            # Act & Assert
            { Test-ComponentSpec -Spec $spec } | 
            Should -Throw "Missing required field: Version"
        }

        It 'Should validate dependency chains' {
            # Arrange
            $specs = @{
                ComponentA = @{ Dependencies = @("ComponentB") }
                ComponentB = @{ Dependencies = @("ComponentA") }
            }

            # Act & Assert
            { Test-DependencyChain -Specs $specs } | 
            Should -Throw "Circular dependency detected"
        }
    }

    Context 'Profile Validation' {
        It 'Should validate profile inheritance' {
            # Arrange
            Mock Get-InstallationProfile {
                @{
                    InheritFrom = "NonexistentProfile"
                }
            }

            # Act & Assert
            { Test-ProfileConfiguration -Name "TestProfile" } | 
            Should -Throw "Invalid inheritance"
        }

        It 'Should validate component existence' {
            # Arrange
            Mock Get-InstallationProfile {
                @{
                    Components = @("NonexistentComponent")
                }
            }

            # Act & Assert
            { Test-ProfileConfiguration -Name "TestProfile" } | 
            Should -Throw "Unknown component"
        }
    }
}