# GITHUB TEST BUTTON — GTB-001

Engineering classification: **GTB BETA READY WITH LIMITATIONS**.

All three mandatory distributions were produced and independently checked. The Windows GUI executed from the installer deployment; the signed Android universal APK executed on a dedicated emulator; the pure Python wheel installed into a clean virtual environment and executed from outside the source tree. The ARM64-only APK passed ABI, metadata and signature validation. It has not run on physical ARM64 hardware.

| Deliverable | Actual location |
|---|---|
| Windows native executable |flutter/build/windows/x64/runner/Release/github_test_button.exe|
| Windows installer |dist/windows/GTB-Windows-Setup.exe|
| Windows portable bundle |dist/windows/GTB-Windows-Portable.zip|
| ARM64 Android package |dist/android/GTB-Android-arm64.apk|
| Universal Android package |dist/android/GTB-Android-universal.apk|
| Python wheel |dist/python/github_test_button-0.1.0b1-py3-none-any.whl|
| Python source distribution |dist/python/github_test_button-0.1.0b1.tar.gz|

Local project root: `C:\xampp\GITHUB-TEST-BUTTON`.

Account: `chatgptopenaiagi`. Product repository: https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON . Published prerelease: https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/releases/tag/v0.1.0-beta.1 . All eight uploaded assets were downloaded and matched local SHA-256 values; anonymous API readback confirmed public prerelease status. Final verification is recorded in GITHUB-RELEASE.md and release-verification.json. Release tag source: `d8b8550c24a0b0a6068923fcabb8322eb8b16e86`.

Genuine GitHub API and existing-CLI authentication passed in Python and Windows. Public Android API/repository checks passed. The actual CLI write-test commit `1a02583cc866df5d81e281456526c79f321dbc22` was independently read back from its unique verification branch. The ordinary button never performed writes.

Test totals:111 distinct automated tests,10 Windows GUI checks,4 installer checks,12 Android runtime checks,10 wheel acceptance checks,4 live schema validations. Current local failures:0. Open grouped limitations:8, fully described in KNOWN-LIMITATIONS.md. These counts exclude repeated tests and individual diagnostic rows inside one acceptance scenario.

Windows installer is unsigned by Authenticode. Android is release-signed with an isolated RSA4096 key; only public certificate information is distributed. Mobile OAuth is pending registration/integration. Hosted release signing secrets are not configured. No credentials or private signing material were committed or attached.
