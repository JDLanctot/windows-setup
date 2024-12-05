BeforeAll {
    Import-Module $PSScriptRoot/../../WindowsSetup.psd1 -Force
}

Describe 'Installation Performance' {
    It 'Should complete minimal installation within acceptable time' {
        # Arrange
        $maxDuration = [TimeSpan]::FromMinutes(5)
        
        # Act
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Start-Installation -Profile 'Minimal' -Simulate
        $stopwatch.Stop()
        
        # Assert
        $result | Should -Be $true
        $stopwatch.Elapsed | Should -BeLessThan $maxDuration
    }

    It 'Should maintain acceptable memory usage' {
        # Arrange
        $maxMemoryMB = 500
        
        # Act
        $before = [System.GC]::GetTotalMemory($true)
        Start-Installation -Profile 'Standard' -Simulate
        [System.GC]::Collect()
        $after = [System.GC]::GetTotalMemory($true)
        
        # Assert
        $memoryUsedMB = ($after - $before) / 1MB
        $memoryUsedMB | Should -BeLessThan $maxMemoryMB
    }
}