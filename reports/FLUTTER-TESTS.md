# Flutter application verification

GTB 0.1.0-beta.1 uses independent Dart diagnostics for Windows and Android. It does not invoke Python. Source is in `flutter/lib`; `tool/live_probe.dart` exercises the same core without a GUI.

## Executed tests

50 automated tests passed on the Windows development machine: 42 core, shared-contract, local HTTP server and controlled write workflow tests, and 8 widget tests. See `flutter-tests.log`. A final targeted run of all 8 write workflow tests passed after the sanitized error truncation repair; see `flutter-write-tests.log`. Static analysis completed with **No issues found** (`flutter-analyze.log`).

Failure tests include malformed JSON, DNS errors, TLS classification, timeouts with one bounded retry, HTTP authorization and rate-limit responses without retries, private repository uncertainty, commit and push failure, wrong remote content and commit hashes, unsafe state transitions and write confirmation boundaries. Shared contract vectors are loaded directly from `contracts/test-vectors.json`.

Widget tests verify phone (390×844), tablet (768×1024), desktop (1280×900), loading state and disabled main action, connection result rendering, dark/light preference persistence, repository error rendering, and export controls. An initial narrow-screen header overflow was detected and repaired before the passing run. Initial scaffold test and style lint errors were also repaired.

These tests are controlled fixtures, not proof of real remote writes or native package execution. Native launch, button execution, APK signing and installer acceptance have separate packaging/runtime reports. Root performed the real Dart core probe and stores the observed report in `dart-live.json`.

## Implemented behavior

The main button is read-only and runs bounded DNS/HTTPS/API/public-profile/status/rate-limit diagnostics with progress and account/tool checks. Desktop authentication delegates to the existing GitHub CLI and never exports a token. Android uses direct Dart HTTPS networking and reports desktop tools as unsupported rather than failed. Repo inspection reads metadata, files, latest commit and releases; advertised permissions remain distinct from verified writes.

The separate desktop write action requires a target and explicit authorization, uses a unique branch and generated file, creates a local commit before remote creation, and verifies both remote content and commit SHA. New test repositories are private. No automatic deletion exists. Failure preserves the local directory and state.

Reports support sanitized JSON/TXT export, clipboard copying and Android text sharing. Preferences and a ten-entry connection history are local. English, Romanian and German main controls, light/dark/system appearance and text scaling are available.

## Beta boundaries

Mobile OAuth authentication is pending account-owner registration and a secure token exchange design; no client secret or invented client ID is embedded. Mobile Git workflow verification is unsupported. Technical diagnostic explanations are English in all interface languages. Failed write workspaces are preserved with recovery guidance; no automatic resume or remote repository cleanup is performed. Widget export coverage verifies control rendering; actual filesystem export and native sharing require separate runtime evidence.
