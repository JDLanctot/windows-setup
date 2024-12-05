BeforeAll {
    Import-Module $PSScriptRoot/../../WindowsSetup.psd1 -Force
}

Describe 'Release Verification' {
    It 'Should have valid module manifest' {
        # Arrange
        $manifestPath = "./WindowsSetup.psd1"
        
        # Act
        $manifest = Test-ModuleManifest $manifestPath -ErrorAction SilentlyContinue
        
        # Assert
        $manifest | Should -Not -BeNullOrEmpty
        $manifest.Version | Should -Not -BeNullOrEmpty
    }

    It 'Should export required functions' {
        # Arrange
        $requiredFunctions = @(
            'Start-Installation'
            'Install-Component'
            'Test-InstallationState'
        )
        
        # Act
        $exportedFunctions = Get-Command -Module WindowsSetup
        
        # Assert
        foreach ($function in $requiredFunctions) {
            $exportedFunctions.Name | Should -Contain $function
        }
    }
}