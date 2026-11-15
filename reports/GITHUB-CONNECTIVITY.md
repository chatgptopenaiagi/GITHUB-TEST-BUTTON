# Genuine GitHub connectivity

On2026-11-15 the installed Python wheel, Dart core and installed Windows GUI independently performed real HTTPS/API checks. Final reports show successful GitHub DNS, website HTTPS, REST API, public account lookup and service-status retrieval. Existing GitHub CLI credentials verified the publisher identity without exposing credentials.

Evidence: `python-wheel-test.json`, `dart-live.json`, `windows-gui-export.json`. The Dart network-interface check is deliberately limited evidence; the Python external TCP check probes1.1.1.1:443. These differing platform observations are not falsely equated.

The first Python website probe returned HTTP406 because an API-specific Accept header was sent to the HTML site. The transport was corrected, a regression test added, the wheel rebuilt, and strict live installation tests then passed. Initial evidence remains in `python-wheel-initial-http406.json`; it is superseded by the final wheel report.
