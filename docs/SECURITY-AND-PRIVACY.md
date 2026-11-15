# Security and privacy

Standard diagnostics contact GitHub HTTPS/API and GitHub Status. Reports are local until the user explicitly copies, exports, or shares them. The app does not upload arbitrary files or perform telemetry polling.

Tokens, cookies, passwords, and private keys are excluded from reports. Remote URLs must have embedded credentials removed. Local tool paths, account names, public IP-resolution results, and repository metadata can still be identifying; review exports before sharing.

Windows/CLI authentication uses existing approved credentials through GitHub CLI. Do not paste tokens into repository fields. Android public checks need only Internet permission. No contacts, photos, microphone, camera, or device identifier permissions are needed.

Write tests generate their own verification payload. They must target an explicitly selected repository or a newly requested private repository, preserve an existing default branch, and record what was created. Failed pushes preserve local committed data. Repository deletion is outside normal diagnostics.
