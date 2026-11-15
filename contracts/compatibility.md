# Diagnostic contract 1.0

Dart and Python have separate runtimes. Both emit application, version, schema_version (1.0), platform, UTC timestamp, duration_ms and a checks array. Each check has id, status, message, duration_ms and details. Optional report fields may be added. Status meanings and HTTP/error classifiers are exercised from test-vectors.json in both runtimes.

CONNECTED means the stated operation completed; it never implies write access. NOT_TESTED means no operation was attempted. Tool discovery is separate from an actual version command; version execution is not repository engineering verification. Missing optional tools do not break public connectivity. 404 means inaccessible or absent, never proof a private repository does not exist. 401 means configured credentials were rejected, not proof of a specific expiration cause. 403 is ACCESS_DENIED unless rate-limit headers identify limiting; 429 is RATE_LIMITED. 5xx and malformed expected JSON are API_UNAVAILABLE. No authentication or rate-limit retries; at most one retry for transient read failures. Service status is published GitHub information independent from local reachability.

Check identifiers: network, dns.github.com, dns.api.github.com, dns.www.githubstatus.com, github.https, github.api, github.public_account, github.service, github.rate_limit, authentication, tool.git, tool.gh, tool.codex, tool.pwsh, repository, repository_write. Platform-specific extensions are allowed.

The write state sequence is NOT_INITIALIZED → DIRECTORY_CREATED → GIT_INITIALIZED → FILES_CREATED → FILES_STAGED → COMMIT_CREATED → REMOTE_READY → PUSH_COMPLETED → REMOTE_VERIFIED. A failed transition leaves the prior state and preserves the local workspace. Read-only reports always mark repository_write NOT_TESTED.
