# Android runtime acceptance

The signed `GTB-Android-universal.apk` installed and ran on emulator-5580 (Android17/API37, x86_64). Twelve scoped runtime checks passed; zero GTB runtime checks failed. See `android-runtime.json` for individual evidence and artifact SHA-256.

The main button displayed progress and completed genuine GitHub diagnostics in5024ms, including HTTP200 API access in873ms, HTTPS in1659ms, published status in377ms, and public rate limits. Authentication remained UNAUTHENTICATED and all desktop tools were UNSUPPORTED_ON_PLATFORM without causing a connection failure. Repository lookup read product metadata, files, latest commit and releases in3212ms; write verification remained false.

The application rendered dark/light surfaces, persisted Dark Mode through force-stop/relaunch, and displayed Romanian/German settings and navigation after selection. JSON and TXT exports returned successful saved-path acknowledgements. Their private files were not independently pulled. The Android native share chooser opened; its full JSON text payload was captured from the actual UI hierarchy, parsed, and saved as `android-live.json`. No report was transmitted to an external recipient.

Screenshots are actual `adb screencap` output: `assets/screenshots/android-connected.png` and `android-dark.png`. GUI hierarchies are preserved as `android-*.xml`.

No physical ARM64 device was available. The universal x86_64 emulator run is separate from ARM64 build/ABI/signature verification. Other Android API levels were not executed. Before GTB installation, the emulator displayed a System UI startup ANR; it recovered after selecting Wait, and GTB acceptance subsequently passed. Initial Android build failure from a missing Kotlin class brace was repaired before these binaries were produced.
