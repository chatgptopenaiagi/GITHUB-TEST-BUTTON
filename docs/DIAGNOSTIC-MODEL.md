# Diagnostic model

The canonical machine-readable definitions are in `contracts/diagnostic-v1.schema.json`, `status-codes.json` and `test-vectors.json`.

- Green: the specific check completed successfully.
- Yellow: operation is limited, authentication unavailable, or rate limiting prevents a full result.
- Red: the specific tested operation failed.
- Gray: not tested or unsupported on this platform.

`CONNECTED` only establishes the operation named by the check. It cannot imply write permissions. `NOT_TESTED` is distinct from failure. API reachability, local network evidence and GitHub's published service health are separate checks.

Configured credentials rejected with HTTP401 receive `AUTHENTICATION_EXPIRED`; the accompanying explanation must not imply that expiry, rather than revocation or invalidity, has been proven. HTTP404 on a repository can mean absent or inaccessible. HTTP403 requires rate-limit evidence before being treated as rate limiting; HTTP429 is rate limited.

Each check contains `id`, `status`, `message`, `duration_ms` and `details`. Report timestamps are UTC. Status classifications are tested in both implementations using common fixtures. Network requests have bounded timeouts and limited retries; authentication failures and rate limits are not retried blindly.
