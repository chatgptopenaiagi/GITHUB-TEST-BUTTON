# Android build evidence

Date: 2026-11-15. Flutter 3.47.8 / Dart 3.13.7; Microsoft OpenJDK21.0.8; cached Gradle9.3.1 binary distribution; Android build-tools36.0.0.

Final result: PASS for ARM64 and universal release APK generation, aapt metadata/ABI validation and apksigner verification. Runtime evidence is recorded separately in android-runtime.json.

| Property | ARM64 | Universal |
|---|---|---|
| Package | dev.gtb.github_test_button | dev.gtb.github_test_button |
| Version name | 0.1.0-beta.1 | 0.1.0-beta.1 |
| Version code | 2001 (Flutter ABI split offset) | 1 |
| Minimum Android API | 24 | 24 |
| Target Android API | 36 | 36 |
| ABIs | arm64-v8a only | armeabi-v7a, arm64-v8a, x86_64 |
| Signature | APK v2, RSA4096 | APK v2, RSA4096 |

Application label: GITHUB TEST BUTTON. Permissions: INTERNET and AndroidX's app-scoped DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION (signature protection). No contacts, storage/photos, camera, microphone, SMS or device-identifier permissions.

Signing certificate SHA256: `423e51524b6893ca275468e089f4a3d68cd94d1d0f55d8f66da6d521cf3182ae`. A distinct GTB release key was generated; the APK is not debug signed. The private key and passwords remain in ignored local files, with Windows ACLs restricted to the current user and SYSTEM. Keep a secure backup for future updates. CI release signing requires explicitly configured owner-managed secrets; no key was uploaded automatically.

Final ARM64 command uses `flutter build apk --release --target-platform android-arm64 --split-per-abi`; output `app-arm64-v8a-release.apk` copied to the required product name. ARM64 final compilation passed in 28.9 seconds; universal compilation passed in 104.5 seconds.

Preserved repaired build issues:

1. Generated Gradle wrapper requested an uncached `all` distribution; the attempted download did not progress. Changed only the GTB wrapper to the same-version installed `bin` distribution.
2. Native Android share handler lacked a final class brace. Kotlin compiler rejected it; corrected before both distributed APKs.
3. Plain `--target-platform android-arm64` retained plugin libraries for other ABIs. Mandatory architecture verification rejected the first package. `--split-per-abi` produced the final verified ARM64-only artifact.
4. SDK XML3/XML4 warning appeared; it did not prevent final compilation or package validation.

The available runtime is an x86_64 API37 emulator, using the universal APK. No physical ARM64 device was available; metadata/build/signature validation is distinct from ARM64 hardware execution. Standard Flutter ABI split version-code offsets mean the universal variant is not an in-place upgrade from the ARM64 variant; use the same variant for future updates.

Logs: android-build-log.txt, android-build-final-log.txt, android-build-verified-log.txt, android-build-arm64-final-log.txt. Metadata and signing receipts are adjacent to this report.
- GTB-Android-arm64.apk: 18412509 bytes; SHA256 fa2c52284eace24a863959d68912a7efd00fa22c6353272d51a3d82d2f6a4370
- GTB-Android-universal.apk: 52426823 bytes; SHA256 ac939a2471e96378ba142e45458be5e58ae2a957e4faa371e11050493017e386
