param([switch]$Universal, [string]$JavaHome, [string]$AndroidSdk)
. "$PSScriptRoot/Common.ps1"
if($JavaHome){$env:JAVA_HOME=$JavaHome}
elseif(!$env:JAVA_HOME -and (Test-Path 'C:\Program Files\Android\openjdk\jdk-21.0.8')){$env:JAVA_HOME='C:\Program Files\Android\openjdk\jdk-21.0.8'}
if($AndroidSdk){$env:ANDROID_HOME=$AndroidSdk}
elseif(!$env:ANDROID_HOME){$env:ANDROID_HOME=Join-Path $env:LOCALAPPDATA 'Android\Sdk'}
if(!(Test-Path "$ProjectRoot/flutter/android/key.properties") -and !$env:GTB_KEYSTORE){throw 'Release signing requires android/key.properties or GTB_KEYSTORE, GTB_STORE_PASSWORD, GTB_KEY_PASSWORD and GTB_KEY_ALIAS. See docs/BUILD-VERIFICATION.md.'}
Push-Location "$ProjectRoot/flutter"
try {
    Invoke-Flutter @('pub','get')
    Invoke-Flutter @('build','apk','--release','--target-platform','android-arm64')
    New-Item -ItemType Directory -Force "$ProjectRoot/dist/android" | Out-Null
    Copy-Item 'build/app/outputs/flutter-apk/app-release.apk' "$ProjectRoot/dist/android/GTB-Android-arm64.apk" -Force
    if($Universal){
        Invoke-Flutter @('build','apk','--release','--target-platform','android-arm,android-arm64,android-x64')
        Copy-Item 'build/app/outputs/flutter-apk/app-release.apk' "$ProjectRoot/dist/android/GTB-Android-universal.apk" -Force
    }
    $bt=Get-ChildItem "$env:ANDROID_HOME/build-tools" -Directory | Sort-Object Name -Descending | Select-Object -First 1
    if(!$bt){throw 'Android build-tools missing'}
    $env:PATH="$env:JAVA_HOME/bin;$env:PATH"
    foreach($apk in Get-ChildItem "$ProjectRoot/dist/android/*.apk"){
        $metadata=& "$($bt.FullName)/aapt.exe" dump badging $apk.FullName
        if($LASTEXITCODE -ne 0){throw 'aapt failed'}
        $metadata|Set-Content "$ProjectRoot/reports/$($apk.BaseName)-metadata.txt" -Encoding utf8
        Invoke-Checked "$($bt.FullName)/apksigner.bat" @('verify','--verbose','--print-certs',$apk.FullName)
        if(($metadata -join "`n") -notmatch "package: name='dev.gtb.github_test_button'"){throw 'Package identity mismatch'}
        if($apk.Name -match 'arm64' -and (($metadata|Select-String '^native-code:').Line -ne "native-code: 'arm64-v8a'")){throw 'ARM64 architecture mismatch'}
    }
    @(Get-ChildItem "$ProjectRoot/dist/android/*.apk"|ForEach-Object{Assert-Artifact $_.FullName}) | ConvertTo-Json -Depth 4 | Set-Content "$ProjectRoot/reports/android-artifacts.json" -Encoding utf8
} finally {Pop-Location}
