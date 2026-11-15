# Security and privacy

Standard diagnostics contact GitHub HTTPS/API and GitHub Status. The Python CLI also makes an independent TCP connection to 1.1.1.1:443; failure of that optional probe is not treated as proof GitHub is down. Reports are local until the user explicitly copies, exports, or shares them. The app does not upload arbitrary files or perform telemetry polling.

Tokens, cookies, passwords, and private keys are excluded from reports. Remote URLs must have embedded credentials removed. Local tool paths, account names, public IP-resolution results, and repository metadata can still be identifying; review exports before sharing.

Windows/CLI authentication uses existing approved credentials through GitHub CLI. Do not paste tokens into repository fields. Android public checks need only Internet permission. No contacts, photos, microphone, camera, or device identifier permissions are needed.

Write tests generate their own verification payload. They must target an explicitly selected repository or a newly requested private repository, preserve an existing default branch, and record what was created. Failed pushes preserve local committed data. Repository deletion is outside normal diagnostics.

Release maintainers must securely back up the Android signing material in `.private/gtb-release.p12` and the ignored `flutter/android/key.properties`. Neither belongs in Git, diagnostic exports or release assets. Losing the signing key prevents seamless upgrades under the same Android identity.
