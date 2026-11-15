# System readiness — 2026-11-15

Scoped discovery for GTB-001 read the machine capability Markdown registry and graph/routing/history/causal records. The read-only capability recommendation identified existing Flutter/Dart, Android SDK, Gradle and JDK21. Historical integration evidence was not treated as a current GTB build. E:\GENESIS-10 was unavailable; no unrelated project was executed.

Current checks:

| Component | Observed result |
|---|---|
| PowerShell | 7.6.9 |
| Git | 2.56.0.windows.3 |
| GitHub CLI | 2.103.2 |
| Codex CLI | 0.169.0, optional only |
| Python | 3.10.0 at the existing Python310 installation |
| Flutter | 3.47.8 stable at C:\flutter |
| Dart | 3.13.7 bundled with Flutter |
| Visual Studio | Community 2026 18.11.4; Windows toolchain doctor passes |
| Android | SDK build tools36.0.0, platform37; licenses accepted |
| Java for Android | Existing Microsoft OpenJDK21.0.8 selected in Flutter configuration |
| Storage | C: approximately265GB free at initial check |
| Device discovery | Windows and Edge; no connected Android device at initial check |

Flutter doctor reported a missing Chrome executable, irrelevant to these Windows/Android targets. Current compilation and runtime outcomes are recorded separately in platform build reports. GTB source and build work remain under C:\xampp\GITHUB-TEST-BUTTON.
