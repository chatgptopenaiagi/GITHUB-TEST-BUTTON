# GTB v0.1.0-beta.1

**GITHUB TEST BUTTON — initial engineering beta with documented limitations.**

Includes a complete Windows installer and portable distribution, an independently networked Android application (ARM64 and universal APKs), and a pure Python wheel/source distribution. Public diagnostics are read-only. The separate write workflow verifies generated content and commit readback after explicit confirmation.

Validated locally:61 Python unit tests,50 Flutter core/widget tests,10 clean-wheel acceptance checks,10 installed Windows GUI checks,4 installer lifecycle checks and12 Android emulator checks. Real GitHub authentication, repository access, a unique test-branch push and independent API readback succeeded. Four real diagnostic reports validate against the shared schema. Android runtime evidence and current CI outcomes are recorded in the repository reports.

Download the artifact for your platform and check `SHA256SUMS.txt`. Windows includes its runtime DLLs/data and needs no Python. Android package `dev.gtb.github_test_button` supports API24+; the release key certificate SHA-256 is `423e51524b6893ca275468e089f4a3d68cd94d1d0f55d8f66da6d521cf3182ae`.

Important boundaries: Android mobile authentication is pending; physical ARM64 testing and clean-machine Windows testing remain unperformed. Windows installer is unsigned by Authenticode. Technical messages are English; some end-to-end write/UI scenarios remain fixture-only. See [known limitations](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/blob/main/reports/KNOWN-LIMITATIONS.md) and [verification](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/blob/main/docs/BUILD-VERIFICATION.md).

This is a prerelease, not a production-readiness claim. No personal access token, OAuth secret, or Android private signing key is distributed.
