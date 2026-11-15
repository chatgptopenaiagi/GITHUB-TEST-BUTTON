# GitHub release verification

Published: [GTB v0.1.0-beta.1](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON/releases/tag/v0.1.0-beta.1), public prerelease of `chatgptopenaiagi/GITHUB-TEST-BUTTON` at2026-11-15T15:13:55Z.

Release source commit: `d8b8550c24a0b0a6068923fcabb8322eb8b16e86`. The tag was pushed before publication and verified. Final classification: **GTB BETA READY WITH LIMITATIONS**.

All six local distributions passed artifact validation. Windows installer execution and Android universal emulator execution have separate reports. Android ARM64-only architecture/signature and clean Python wheel installation were independently checked. The release is classified as beta with limitations, including no physical ARM64 or clean Windows machine test.

All eight release assets were downloaded and compared with local SHA-256 hashes: **8 matched,0 mismatches**. Anonymous REST API readback independently confirmed eight assets, `draft=false` and `prerelease=true`. The complete byte-level receipt is `release-verification.json` at the repository root; the reproducible command is `scripts/Verify-PublishedRelease.ps1`.

Assets: GTB-Windows-Setup.exe, GTB-Windows-Portable.zip, GTB-Android-arm64.apk, GTB-Android-universal.apk, github_test_button-0.1.0b1-py3-none-any.whl, github_test_button-0.1.0b1.tar.gz, SHA256SUMS.txt and release-manifest.json.

The upload took approximately10minutes. GitHub kept the release as a draft while transferring the larger binaries, then published it after all uploads completed. No incomplete release was presented as complete. The subsequent source commit contains the publication audit only; the release tag remains fixed at its reviewed source commit.

All platform CI workflows passed for source commit a1ee1d8428e1cc2159795078a977942442bffeac before publication. The following release-preparation commit contains documentation, evidence and validation helpers; application source is unchanged.
