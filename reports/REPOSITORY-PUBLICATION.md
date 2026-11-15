# Repository publication

Before creation, authenticated `gh repo view` could not resolve the requested repository. The local project was initialized, files staged, and an initial commit created before remote creation/push.

- Owner: `chatgptopenaiagi`
- Repository: [GITHUB-TEST-BUTTON](https://github.com/chatgptopenaiagi/GITHUB-TEST-BUTTON)
- Visibility: public, verified through GitHub CLI/API
- Initial commit: `670490b94e82e591151bb7fc502a98d22ad20c09`
- Branch: `main`
- Initial remote commit and README blob read back through REST API

Release source tag: `v0.1.0-beta.1`, commit `d8b8550c24a0b0a6068923fcabb8322eb8b16e86`. All platform workflows passed on runtime-source commit `a1ee1d8428e1cc2159795078a977942442bffeac`; the release-preparation commit added evidence/documentation without changing application code. Subsequent audit commits do not move the release tag. See `github-readiness.json` and `release-verification.json`. No unrelated repository was changed.
