[CmdletBinding()]
param(
    [switch]$Coverage,
    [string]$TestName,
    [string]$Path
)

$config = New-PesterConfiguration

if ($Path) {
    $config.Run.Path = $Path
}
elseif ($TestName) {
    $config.Run.Path = "./tests"
    $config.Filter.FullName = $TestName
}
else {
    $config.Run.Path = "./tests"
}

$config.Output.Verbosity = 'Detailed'

if ($Coverage) {
    $config.CodeCoverage.Enabled = $true
    $config.CodeCoverage.Path = @(
        './WindowsSetup.psm1'
        './lib/**/*.ps1'
    )
    $config.CodeCoverage.OutputFormat = 'JaCoCo'
    $config.CodeCoverage.OutputPath = './coverage.xml'
}

Invoke-Pester -Configuration $config