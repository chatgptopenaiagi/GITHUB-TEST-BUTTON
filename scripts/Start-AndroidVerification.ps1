param([string]$AndroidSdk, [string]$JavaHome, [string]$SystemImage='system-images;android-37.0;google_apis_playstore;x86_64')
. "$PSScriptRoot/Common.ps1"
if(!$AndroidSdk){$AndroidSdk=Join-Path $env:LOCALAPPDATA 'Android/Sdk'}
if(!$JavaHome){$JavaHome='C:\Program Files\Android\openjdk\jdk-21.0.8'}
$env:JAVA_HOME=$JavaHome
$env:ANDROID_AVD_HOME="$ProjectRoot/.verify/avd"
New-Item -ItemType Directory -Force $env:ANDROID_AVD_HOME|Out-Null
$manager=Resolve-Tool 'avdmanager' @("$AndroidSdk/cmdline-tools/latest/bin/avdmanager.bat")
$emulator=Resolve-Tool 'emulator' @("$AndroidSdk/emulator/emulator.exe")
if(!(Test-Path "$env:ANDROID_AVD_HOME/GTB_API37.ini")){
    'no'| & $manager create avd --name GTB_API37 --package $SystemImage --path "$env:ANDROID_AVD_HOME/GTB_API37.avd" --device pixel_7
    if($LASTEXITCODE -ne 0){throw 'GTB verification AVD creation failed. Install the requested official system image first.'}
}
Start-Process -FilePath $emulator -ArgumentList '-avd','GTB_API37','-no-window','-no-snapshot','-no-audio','-gpu','swiftshader','-port','5580','-feature','-Vulkan' -WindowStyle Hidden -RedirectStandardOutput "$ProjectRoot/.verify/emulator.stdout.log" -RedirectStandardError "$ProjectRoot/.verify/emulator.stderr.log" -PassThru | Select-Object Id
Write-Output 'Dedicated target: emulator-5580. Check adb -s emulator-5580 shell getprop sys.boot_completed before installing the universal APK. Stop only this target with adb -s emulator-5580 emu kill.'
