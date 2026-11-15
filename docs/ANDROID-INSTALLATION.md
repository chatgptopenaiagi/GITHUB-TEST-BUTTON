# Android installation

Download `GTB-Android-arm64.apk` from the official project release for an ARM64 device. The optional universal APK also contains other supported Android architectures. Compare the file SHA-256 with the release checksums, transfer the APK to the device, and use Android's normal package installer under your device's installation policy.

The application label is **GITHUB TEST BUTTON** and the package identifier is `dev.gtb.github_test_button`. This beta requires Android API24 or newer and targets API36. The release signing certificate fingerprint is recorded with build evidence. Keep future upgrades on the same signing identity and APK flavor: Flutter's ARM64 split uses version code2001 while the universal APK uses1, so switching from the split to this universal build is not an in-place upgrade.

Press **TEST GITHUB CONNECTION** for public diagnostics. Android networking runs directly on the device; no Windows computer, Python, Git, PowerShell, GitHub CLI or Codex is needed. Missing desktop tools are classified as not applicable. Internet is the only requested runtime capability for normal diagnostics.

Authenticated mobile access is pending registered OAuth configuration and validation. The app does not ask for GitHub passwords or contain the publisher's credentials. This limitation does not prevent public repository inspection.

Compilation, signature validation, emulator execution and physical-device testing are separate evidence categories. Read [Android build evidence](../reports/ANDROID-BUILD.md) for the actual tested environment. A universal APK emulator test does not establish physical ARM64 execution.
