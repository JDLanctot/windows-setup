Describe 'Security and Permissions' {
    Context 'User Permissions' {
        It 'Should detect admin privileges correctly' {
            # Arrange
            Mock Test-AdminPrivileges { $true }

            # Act
            $result = Confirm-InstallationPrerequisites

            # Assert
            $result.HasAdminRights | Should -Be $true
        }

        It 'Should handle non-admin installation attempts' {
            # Arrange
            Mock Test-AdminPrivileges { $false }

            # Act & Assert
            { Start-Installation -RequireAdmin } | 
            Should -Throw "Administrator privileges required"
        }
    }

    Context 'File System Permissions' {
        It 'Should verify write permissions' {
            # Arrange
            $testPath = "TestDrive:\test"
            New-Item -ItemType Directory -Path $testPath

            # Act
            $result = Test-WritePermission -Path $testPath

            # Assert
            $result | Should -Be $true
        }

        It 'Should handle restricted paths' {
            # Arrange
            Mock Test-WritePermission { $false }

            # Act & Assert
            { Install-Component -Name "TestComponent" } | 
            Should -Throw "Insufficient permissions"
        }
    }
}