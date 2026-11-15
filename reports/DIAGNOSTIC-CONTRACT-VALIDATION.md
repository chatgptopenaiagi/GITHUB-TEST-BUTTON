# Diagnostic contract validation

Recorded at 2026-11-15T15:02:08.896436+00:00

Result: PASS

All four recorded live reports (Dart core, Python wheel, installed Windows GUI, Android emulator) validate against diagnostic-v1.schema.json with Draft 2020-12 and date-time format validation. Fourteen equivalent operation identifiers have matching status classifications. The schema permits separate product version syntax (Dart 0.1.0-beta.1; Python PEP 440 0.1.0b1). These are two separate implementations; neither is a shared executable runtime.

| Check | Dart | Python |
|---|---|---|
| dns.github.com | CONNECTED | CONNECTED |
| dns.api.github.com | CONNECTED | CONNECTED |
| dns.www.githubstatus.com | CONNECTED | CONNECTED |
| github.https | CONNECTED | CONNECTED |
| github.api | CONNECTED | CONNECTED |
| github.public_account | CONNECTED | CONNECTED |
| github.service | CONNECTED | CONNECTED |
| github.rate_limit | CONNECTED | CONNECTED |
| authentication | CONNECTED | CONNECTED |
| tool.git | CONNECTED | CONNECTED |
| tool.gh | CONNECTED | CONNECTED |
| tool.codex | CONNECTED | CONNECTED |
| tool.pwsh | CONNECTED | CONNECTED |
| repository_write | NOT_TESTED | NOT_TESTED |

network: Dart observes local interfaces (CONNECTED_WITH_LIMITATIONS); Python additionally verifies TCP to 1.1.1.1:443 (CONNECTED). This evidence scope differs and is not included in equivalent-operation comparisons.

The shared HTTP vectors contain ten cases and error vectors six cases. Python executes those within two unit-test methods; Flutter tests execute the same shared vectors. Do not add vector case counts to unit-test totals. The machine-readable evidence includes SHA-256 values for the shared contract files, Python test copies and the copies included in the source distribution; each triple matches.

Schema validation and live agreement are recorded observations, not proof of every future network outcome. Android-specific tool/authentication differences are expected; runtime scope is detailed separately. See contract-validation.json for exact hashes and input timestamps; python-unit-tests.txt and the Flutter test receipt for independent suite counts.
