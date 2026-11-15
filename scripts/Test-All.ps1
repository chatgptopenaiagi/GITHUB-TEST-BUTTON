param([string]$Python)
. "$PSScriptRoot/Common.ps1"
$py=Resolve-Tool 'python' @($Python,"$ProjectRoot/.venv/Scripts/python.exe")
Push-Location $ProjectRoot
try {
    $env:PYTHONPATH="$ProjectRoot/python/src"
    Invoke-Checked $py @('-m','unittest','discover','-s','python/tests','-v')
    Push-Location flutter
    try {Invoke-Flutter @('analyze');Invoke-Flutter @('test')} finally {Pop-Location}
} finally {Pop-Location}
