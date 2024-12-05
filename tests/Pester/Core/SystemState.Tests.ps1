Describe 'System State Management' {
    Context 'Environment Variables' {
        It 'Should backup and restore PATH correctly' {
            # Arrange
            $originalPath = $env:PATH
            $backupManager = New-BackupManager

            # Act
            $backupManager.BackupEnvironmentVariable("PATH")
            $env:PATH = "TestPath"
            $backupManager.RestoreEnvironmentVariable("PATH")

            # Assert
            $env:PATH | Should -Be $originalPath
        }

        It 'Should handle new environment variables' {
            # Arrange
            $backupManager = New-BackupManager
            $testVarName = "TEST_VAR_$(Get-Random)"

            # Act
            $backupManager.BackupEnvironmentVariable($testVarName)
            [Environment]::SetEnvironmentVariable($testVarName, "test", "User")
            $backupManager.RestoreEnvironmentVariable($testVarName)

            # Assert
            [Environment]::GetEnvironmentVariable($testVarName, "User") | 
            Should -BeNullOrEmpty
        }
    }

    Context 'File System State' {
        It 'Should track file system changes' {
            # Arrange
            $testPath = "TestDrive:\test.txt"
            $stateManager = New-StateManager

            # Act
            $stateManager.StartTracking()
            Set-Content -Path $testPath -Value "test"
            $changes = $stateManager.GetChanges()

            # Assert
            $changes.CreatedFiles | Should -Contain $testPath
        }

        It 'Should restore file system state' {
            # Arrange
            $testPath = "TestDrive:\test.txt"
            $stateManager = New-StateManager

            # Act
            $stateManager.StartTracking()
            Set-Content -Path $testPath -Value "test"
            $stateManager.RestoreState()

            # Assert
            Test-Path $testPath | Should -Be $false
        }
    }
}