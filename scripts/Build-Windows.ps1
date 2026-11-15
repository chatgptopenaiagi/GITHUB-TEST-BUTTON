param([switch]$SkipBuild, [string]$InnoCompiler, [string]$VcRuntimeDirectory)
. "$PSScriptRoot/Common.ps1"
Push-Location "$ProjectRoot/flutter"
try {
    if(!$SkipBuild){Invoke-Flutter @('pub','get'); Invoke-Flutter @('build','windows','--release')}
    $bundle="$ProjectRoot/flutter/build/windows/x64/runner/Release"
    Assert-Artifact "$bundle/github_test_button.exe" | Out-Null
    Assert-Artifact "$bundle/flutter_windows.dll" | Out-Null
    Assert-Artifact "$bundle/data/icudtl.dat" | Out-Null
    if(!$VcRuntimeDirectory){
        $vswhere=Resolve-Tool 'vswhere' @("${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe")
        $vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
        $VcRuntimeDirectory=Get-ChildItem "$vs/VC/Redist/MSVC" -Directory | Where-Object Name -Match '^\d' | Sort-Object Name -Descending | ForEach-Object { Get-ChildItem "$($_.FullName)/x64" -Directory -Filter 'Microsoft.VC*.CRT' } | Select-Object -First 1 -ExpandProperty FullName
    }
    if(!$VcRuntimeDirectory){throw 'MSVC redistributable DLL directory unavailable'}
    Copy-Item "$VcRuntimeDirectory/*.dll" $bundle -Force
    New-Item -ItemType Directory -Force "$ProjectRoot/dist/windows" | Out-Null
    Compress-Archive -Path "$bundle/*" -DestinationPath "$ProjectRoot/dist/windows/GTB-Windows-Portable.zip" -Force
    $iscc=Resolve-Tool 'ISCC.exe' @($InnoCompiler, "$ProjectRoot/.tools/InnoSetup/ISCC.exe",'C:\Program Files\Inno Setup 7\ISCC.exe','C:\Program Files (x86)\Inno Setup 6\ISCC.exe')
    Invoke-Checked $iscc @("/DSourceDir=$bundle", "/DOutputDir=$ProjectRoot/dist/windows", "$ProjectRoot/installer/GTB.iss")
    @((Assert-Artifact "$ProjectRoot/dist/windows/GTB-Windows-Setup.exe"),(Assert-Artifact "$ProjectRoot/dist/windows/GTB-Windows-Portable.zip")) | ConvertTo-Json -Depth 4 | Set-Content "$ProjectRoot/reports/windows-artifacts.json" -Encoding utf8
} finally {Pop-Location}
