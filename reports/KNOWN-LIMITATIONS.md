# Known limitations — initial engineering beta

The release classification is **GTB BETA READY WITH LIMITATIONS**. All mandatory distributions are real builds; the following eight grouped limitations remain open.

1. **Mobile authentication:** OAuth registration and secure integration are pending. Android public diagnostics and public repository lookup work independently. No authenticated Android session is claimed.
2. **Android execution coverage:** the universal release is tested on an API37 x86_64 emulator. The ARM64-only package is build/metadata/signature verified, but no physical ARM64 device or lower supported API was exercised. Phone/tablet layout fixtures are not physical-device tests.
3. **Windows deployment coverage:** installation, execution and uninstall were tested in an isolated directory on the development host. No clean Windows machine was available. The installer is not Authenticode-signed.
4. **Windows repository UI automation:** main diagnostics, authentication display, reports and settings were exercised. Automated text insertion into the repository field did not complete reliably with the computer-use helper; that particular Windows end-to-end lookup remains unverified. The same Dart repository core passed real API inspection and widget error tests.
5. **Remote-write coverage:** the installed CLI's existing-repository path completed a real push and exact content/commit readback. New private-repository mode and GUI write paths have controlled failure/success tests but were not additionally executed remotely. Desktop GUI failure recovery preserves the workspace and provides guidance; CLI offers validated `--resume`.
6. **Presentation completeness:** primary controls support English, Romanian and German. Technical diagnostic messages remain English. Account avatar URLs appear in diagnostic metadata; the dashboard currently presents text identity rather than rendering avatars.
7. **Other Python environments:** Windows clean-wheel execution is verified, and GitHub Actions exercises Windows/Linux unit/package checks. Live network behavior on Linux, macOS and enterprise proxy configurations has not been verified here.
8. **Hosted release automation:** routine CI builds are configured and observed separately. The signed release workflow requires owner-managed GitHub signing secrets; these were deliberately not uploaded. The initial release uses locally verified signed APKs. Split ARM64 and universal APK version codes differ; prefer the same APK flavor for upgrades.

Earlier HTTP406, analyzer/style, phone-overflow, native-share syntax, Gradle download, ARM64 packaging and CI output-directory failures were repaired. Their original evidence remains where available; they are not reported as current successful tests.
