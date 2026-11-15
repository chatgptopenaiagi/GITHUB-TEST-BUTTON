param([string]$Python)
. "$PSScriptRoot/Common.ps1"
$py=Resolve-Tool 'python' @($Python)
$venv="$ProjectRoot/.build/python"
Invoke-Checked $py @('-m','venv',$venv)
$vpy=Join-Path $venv 'Scripts/python.exe'
Invoke-Checked $vpy @('-m','pip','install','build')
Invoke-Checked $vpy @('-m','build',"$ProjectRoot/python",'--outdir',"$ProjectRoot/dist/python")
$wheels=@(Get-ChildItem "$ProjectRoot/dist/python/*.whl")
if(!$wheels.Count){throw 'No wheel produced'}
$wheels|ForEach-Object{Assert-Artifact $_.FullName}|ConvertTo-Json -Depth 4|Set-Content "$ProjectRoot/reports/python-artifacts.json" -Encoding utf8
