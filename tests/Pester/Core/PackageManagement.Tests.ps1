Describe 'Package Management' {
    Context 'Package Installation Strategy' {
        It 'Should use Winget when available and appropriate' {
            # Arrange
            Mock Get-Command { $true } -ParameterFilter { $Name -eq 'winget' }
            Mock Install-WingetPackage { $true }
            Mock Install-ChocolateyPackage { $true }

            # Act
            $result = Install-Package -Name "TestPackage" -PreferWinget

            # Assert
            Should -Invoke Install-WingetPackage -Times 1
            Should -Not -Invoke Install-ChocolateyPackage
        }

        It 'Should fallback to Chocolatey when Winget fails' {
            # Arrange
            Mock Install-WingetPackage { throw "Winget failed" }
            Mock Install-ChocolateyPackage { $true }

            # Act
            $result = Install-Package -Name "TestPackage" -PreferWinget

            # Assert
            Should -Invoke Install-ChocolateyPackage -Times 1
        }

        It 'Should handle package not found in any source' {
            # Arrange
            Mock Install-WingetPackage { throw "Package not found" }
            Mock Install-ChocolateyPackage { throw "Package not found" }

            # Act & Assert
            { Install-Package -Name "NonexistentPackage" } | Should -Throw
        }
    }

    Context 'Version Management' {
        It 'Should install specific versions when requested' {
            # Arrange
            Mock Install-ChocolateyPackage { $true }
            
            # Act
            Install-Package -Name "TestPackage" -Version "1.2.3"

            # Assert
            Should -Invoke Install-ChocolateyPackage -ParameterFilter {
                $Version -eq "1.2.3"
            }
        }

        It 'Should handle version conflicts' {
            # Arrange
            Mock Get-InstalledPackageVersion { return "2.0.0" }
            Mock Install-ChocolateyPackage { $true }

            # Act & Assert
            { Install-Package -Name "TestPackage" -Version "1.0.0" -PreventDowngrade } | 
            Should -Throw "Downgrade prevented"
        }
    }
}