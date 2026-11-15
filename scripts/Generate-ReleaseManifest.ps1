. "$PSScriptRoot/Common.ps1"
$artifacts=@(Get-ChildItem "$ProjectRoot/dist" -Recurse -File | Where-Object Extension -in @('.exe','.zip','.apk','.whl','.gz') | ForEach-Object{Assert-Artifact $_.FullName})
if(!$artifacts.Count){throw 'No distributable artifacts found'}
$manifest=[ordered]@{application='GITHUB TEST BUTTON';version='0.1.0-beta.1';generated_at=[DateTime]::UtcNow.ToString('o');artifacts=$artifacts;note='Hashes verify byte identity; runtime evidence is recorded separately in reports.'}
$manifest|ConvertTo-Json -Depth 6|Set-Content "$ProjectRoot/release-manifest.json" -Encoding utf8
$artifacts|ForEach-Object{"$($_.sha256)  $($_.name)"}|Set-Content "$ProjectRoot/dist/SHA256SUMS.txt" -Encoding ascii
