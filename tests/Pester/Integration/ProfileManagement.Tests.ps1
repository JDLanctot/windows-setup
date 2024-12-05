BeforeAll {
    Import-Module $PSScriptRoot/../../../WindowsSetup.psd1 -Force
}

Describe 'Profile Management' {
    Context 'Profile Loading' {
        It 'Should load minimal profile correctly' {
            # Arrange
            $profileName = "Minimal"

            # Act
            $profile = Get-InstallationProfile $profileName

            # Assert
            $profile | Should -Not -BeNullOrEmpty
            $profile.Groups | Should -Contain "Core"
        }

        It 'Should load standard profile with inherited components' {
            # Arrange
            $profileName = "Standard"

            # Act
            $profile = Get-InstallationProfile $profileName

            # Assert
            $profile | Should -Not -BeNullOrEmpty
            $profile.Groups | Should -Contain "Core"
            $profile.Groups | Should -Contain "Development"
        }

        It 'Should handle invalid profile names' {
            # Act & Assert
            { Get-InstallationProfile "NonexistentProfile" } | Should -Throw
        }
    }

    Context 'Profile Validation' {
        It 'Should validate required components' {
            # Arrange
            $profileName = "Minimal"

            # Act
            $components = Get-ProfileComponents $profileName

            # Assert
            $components | Should -Contain "git"
            $components | Should -Contain "powershell"
        }

        It 'Should validate dependencies within profile' {
            # Arrange
            $profileName = "Standard"

            # Act
            $components = Get-ProfileComponents $profileName
            $installOrder = Get-InstallationOrder $components

            # Assert
            $gitIndex = $installOrder.IndexOf("git")
            $neovimIndex = $installOrder.IndexOf("neovim")
            $gitIndex | Should -BeLessThan $neovimIndex
        }
    }

    Context 'Profile Inheritance' {
        It 'Should properly inherit from base profiles' {
            # Arrange
            $profileName = "Full"

            # Act
            $profile = Get-InstallationProfile $profileName

            # Assert
            $profile.InheritFrom | Should -Be "Standard"
            $components = Get-ProfileComponents $profileName
            $components | Should -Contain "git"  # From Core
            $components | Should -Contain "neovim"  # From Development
        }

        It 'Should handle multi-level inheritance' {
            # Arrange
            $profileName = "Full"

            # Act
            $components = Get-ProfileComponents $profileName

            # Assert
            $components | Should -Contain "git"  # From Core (via Minimal)
            $components | Should -Contain "neovim"  # From Standard
            $components | Should -Contain "conda"  # From Full
        }
    }
}