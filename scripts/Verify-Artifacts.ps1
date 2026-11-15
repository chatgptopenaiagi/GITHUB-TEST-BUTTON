. "$PSScriptRoot/Common.ps1"
$required=@('windows/GTB-Windows-Setup.exe','windows/GTB-Windows-Portable.zip','android/GTB-Android-arm64.apk','python/github_test_button-0.1.0b1-py3-none-any.whl')
$records=@($required|ForEach-Object{Assert-Artifact "$ProjectRoot/dist/$_"})
$exeBytes=[IO.File]::ReadAllBytes("$ProjectRoot/dist/windows/GTB-Windows-Setup.exe")
if($exeBytes[0] -ne 0x4d -or $exeBytes[1] -ne 0x5a){throw 'Installer is not a Windows PE executable'}
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Test-ZipEntries([string]$Path,[string[]]$Names){
    $zip=[IO.Compression.ZipFile]::OpenRead($Path)
    try{foreach($name in $Names){if(!($zip.Entries|Where-Object{$_.FullName.Replace('\','/') -eq $name -and $_.Length -gt 0})){throw "Required archive entry missing: $name in $Path"}}}finally{$zip.Dispose()}
}
Test-ZipEntries "$ProjectRoot/dist/windows/GTB-Windows-Portable.zip" @('github_test_button.exe','flutter_windows.dll','vcruntime140.dll','vcruntime140_1.dll','msvcp140.dll','data/icudtl.dat','data/app.so','data/flutter_assets/AssetManifest.bin')
$wheel="$ProjectRoot/dist/python/github_test_button-0.1.0b1-py3-none-any.whl"
Test-ZipEntries $wheel @('github_test_button/cli.py','github_test_button-0.1.0b1.dist-info/METADATA','github_test_button-0.1.0b1.dist-info/WHEEL','github_test_button-0.1.0b1.dist-info/entry_points.txt')
$zip=[IO.Compression.ZipFile]::OpenRead($wheel)
try{
    $reader=[IO.StreamReader]::new($zip.GetEntry('github_test_button-0.1.0b1.dist-info/WHEEL').Open());$wheelInfo=$reader.ReadToEnd();$reader.Dispose()
    $reader=[IO.StreamReader]::new($zip.GetEntry('github_test_button-0.1.0b1.dist-info/entry_points.txt').Open());$entryInfo=$reader.ReadToEnd();$reader.Dispose()
    if($wheelInfo -notmatch 'Tag: py3-none-any' -or $entryInfo -notmatch 'gtb\s*=\s*github_test_button.cli:'){throw 'Wheel compatibility tag or console entry mismatch'}
}finally{$zip.Dispose()}
$apk="$ProjectRoot/dist/android/GTB-Android-arm64.apk"
Test-ZipEntries $apk @('AndroidManifest.xml','classes.dex','lib/arm64-v8a/libflutter.so','lib/arm64-v8a/libapp.so')
$zip=[IO.Compression.ZipFile]::OpenRead($apk)
try{if($zip.Entries|Where-Object{$_.FullName -match '^lib/(?!arm64-v8a/)'} ){throw 'ARM64 APK contains unexpected architectures'}}finally{$zip.Dispose()}
if(!$env:ANDROID_HOME){$env:ANDROID_HOME=Join-Path $env:LOCALAPPDATA 'Android/Sdk'}
$bt=Get-ChildItem "$env:ANDROID_HOME/build-tools" -Directory | Sort-Object Name -Descending | Select-Object -First 1
if(!$bt){throw 'Android build tools required for package/signature verification'}
if(Test-Path 'C:\Program Files\Android\openjdk\jdk-21.0.8'){$env:JAVA_HOME='C:\Program Files\Android\openjdk\jdk-21.0.8'}
$env:PATH="$env:JAVA_HOME/bin;$env:PATH"
$metadata=& "$($bt.FullName)/aapt.exe" dump badging $apk
if($LASTEXITCODE -ne 0 -or ($metadata -join "`n") -notmatch "package: name='dev.gtb.github_test_button'"){throw 'Android metadata mismatch'}
if(($metadata -join "`n") -notmatch "uses-permission: name='android.permission.INTERNET'"){throw 'Missing Android network permission'}
Invoke-Checked "$($bt.FullName)/apksigner.bat" @('verify','--verbose',$apk)
$records | ConvertTo-Json -Depth 5
& "$PSScriptRoot/Generate-ReleaseManifest.ps1"
if($LASTEXITCODE -ne 0){throw 'Manifest generation failed'}
