# Activate a project environment, creating it with uv on first use.
function ca {
    param([string]$envName = '.venv')
    $activate = Join-Path $envName 'Scripts\Activate.ps1'
    if (-not (Test-Path -LiteralPath $activate -PathType Leaf)) {
        uv venv -- $envName
        if ($LASTEXITCODE -ne 0) { throw "uv could not create $envName" }
    }
    . $activate
}
function caz {
    param([Parameter(Mandatory)][string]$envName)
    z $envName
    ca
}
