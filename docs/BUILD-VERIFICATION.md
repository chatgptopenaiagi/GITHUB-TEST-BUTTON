# Building and verifying GTB

Use PowerShell7 from the repository root. Builds use existing tools on PATH or explicit overrides and stop on failed commands. Development convenience fallbacks may identify the original machine's SDK locations; runtime application code has no dependency on that project path.

```powershell
./scripts/Test-Environment.ps1
./scripts/Build-PythonWheel.ps1
./scripts/Test-All.ps1
./scripts/Build-Windows.ps1
# First signing setup only; preserve and securely back up its output:
./scripts/Initialize-AndroidSigning.ps1
./scripts/Build-Android.ps1 -Universal
./scripts/Verify-Artifacts.ps1
./scripts/Generate-ReleaseManifest.ps1
```

Windows needs Flutter/Dart, Visual Studio C++ desktop tooling and Windows SDK, and Inno Setup. The complete Flutter release directory and app-local C++ redistributable DLLs are included. Android needs the SDK/build tools and a compatible JDK; the validated local combination uses JDK21. Python uses an isolated virtual environment and standard packaging tooling. See script parameters for overrides.

Android release builds require the ignored signing properties or `GTB_KEYSTORE`, `GTB_STORE_PASSWORD`, `GTB_KEY_PASSWORD` and `GTB_KEY_ALIAS`. Keep signing material outside source control. CI's routine Android job deliberately produces a development verification APK; the manually dispatched release workflow requires owner-managed signing secrets and assembles a draft only.

Before publication, verify all mandatory artifact formats, the Windows GUI launch, Android package/signing metadata, an installed wheel, shared contract tests, source identity and hashes. `Publish-GitHub.ps1` defaults to a draft and requires a reviewed release decision for a public prerelease. Never treat a build exit code as runtime evidence.

Actual results are recorded in [Windows build](../reports/WINDOWS-BUILD.md), [Android build](../reports/ANDROID-BUILD.md), [Python wheel](../reports/PYTHON-WHEEL-BUILD.md), [contract validation](../reports/DIAGNOSTIC-CONTRACT-VALIDATION.md), and [functional tests](../reports/FUNCTIONAL-TESTS.md). The final manifest identifies the bytes published. Compiler reproducibility is supported by scripts and pinned Flutter dependencies; byte-identical rebuilds are not asserted.
