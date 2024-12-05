BeforeAll {
    Import-Module $PSScriptRoot/../../WindowsSetup.psd1 -Force
}

Describe 'Installation Stress Tests' {
    It 'Should handle multiple concurrent operations' {
        # Arrange
        $numberOfJobs = 3
        $jobs = @()
        
        # Act
        for ($i = 0; $i -lt $numberOfJobs; $i++) {
            $jobs += Start-Job -ScriptBlock {
                Import-Module WindowsSetup
                Start-Installation -Profile 'Minimal' -Simulate
            }
        }
        
        $results = $jobs | Wait-Job | Receive-Job
        
        # Assert
        $results | Should -Not -Contain $false
    }

    It 'Should handle interrupted installations' {
        # Arrange
        Mock Start-Sleep { throw "Simulated interruption" }
        
        # Act & Assert
        { Start-Installation -Profile 'Minimal' -Simulate } | Should -Throw
        Test-CleanupState | Should -Be $true
    }
}