# GitHub release verification

Release target: `v0.1.0-beta.1`, public prerelease of `chatgptopenaiagi/GITHUB-TEST-BUTTON`.

All six local distributions passed artifact validation. Windows installer execution and Android universal emulator execution have separate reports. Android ARM64-only architecture/signature and clean Python wheel installation were independently checked. The release is classified as beta with limitations, including no physical ARM64 or clean Windows machine test.

Publication and downloaded-byte verification are recorded in the final revision of this report and `release-verification.json`. Local artifact presence alone does not establish a published release.

All platform CI workflows passed for source commit a1ee1d8428e1cc2159795078a977942442bffeac before publication. The following release-preparation commit contains documentation, evidence and validation helpers; application source is unchanged.
