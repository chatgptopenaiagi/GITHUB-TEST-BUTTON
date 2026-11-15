# Windows build evidence

Date: 2026-11-15. Platform: Windows x64. Flutter 3.47.8 / Dart 3.13.7, installed Visual Studio Community 2026 C++ tools. Inno Setup 7.1.1, official distribution signature checked before installation.

- Initial release compilation passed in 101.6 seconds.
- Final incremental compilation passed in 34.8 seconds after the last error-redaction fix.
- A packaging retry was required because the first GUI acceptance process held msvcp140.dll open. The GTB process was stopped; the existing successfully compiled output was packaged with `Build-Windows.ps1 -SkipBuild`. Final installer compilation passed in 7.2 seconds.
- Portable ZIP includes executable, Flutter DLL, plugin DLL, data/app.so, ICU data, Flutter assets and Microsoft Visual C++ redistributable DLLs copied from installed VS redistributables.
- The per-user Inno installer creates a Start Menu entry and standard uninstaller.
- GTB installer and application are not Authenticode signed. No signing certificate was fabricated.
- Runtime/installation verification is recorded separately by the acceptance tester. This build report does not claim clean-machine compatibility.

Logs: windows-build-log.txt, windows-build-final-log.txt, windows-package-final-log.txt. Artifact receipt: windows-artifacts.json. Dart source input hashes: flutter-build-source-hashes.json.
- GTB-Windows-Setup.exe: 11076316 bytes; SHA256 9aa109913557d9612e4b772fe4336b238b59f4721bbb794c53a883ebe56def6d
- GTB-Windows-Portable.zip: 12999041 bytes; SHA256 c9c3e53267003f4d24ec601e30a77d2d5302c586024dc5398381ee4ebb0cf2c5
