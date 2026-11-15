# GITHUB TEST BUTTON Python CLI

Independent Python 3.10+ package with no runtime dependencies. Windows, Linux and macOS use the same standard-library diagnostic core. No Flutter, Codex, PowerShell or Git is required for public diagnostics.

```console
python -m pip install github_test_button-0.1.0b1-py3-none-any.whl
gtb test --json
gtb status
gtb test --all
gtb doctor
gtb auth status
gtb repo check OWNER/REPO
gtb repo capabilities OWNER/REPO --json
gtb report --json --output report.json
gtb report --output report.txt
gtb write-test --repo OWNER/TEST-REPO --confirm
gtb write-test --new --confirm
gtb write-test --resume PREVIOUS_LOCAL_DIRECTORY --confirm
```

All standard diagnostics are read-only. `--all` does not enable writes. `report` runs a fresh read-only suite. The independent network probe connects to 1.1.1.1:443; failure of that probe alone does not prove GitHub inaccessible. DNS and all HTTPS probes have timeouts, one retry at most for transient read failures, and no retries on authentication or rate limiting. CLI timeout is configurable from 0.1 to 60 seconds per attempt; sequential suite duration can exceed one timeout.

Authentication uses existing GH_TOKEN/GITHUB_TOKEN or the GitHub CLI credential store in memory; nothing is persisted by GTB. Public diagnostics work without authentication. Authenticated checks use GitHub.com only; no credential-bearing redirects are followed. HTTP 404 means missing or inaccessible and cannot establish private repository nonexistence. A rejected credential is classified AUTHENTICATION_EXPIRED without claiming a specific expiration cause.

Write tests require Git and GitHub CLI, an authenticated owner account, explicit scope and --confirm. Existing mode creates a unique orphan test branch containing only a generated marker, preserving all other branches. New mode creates a unique private repository. Each successful transition is saved under an owned temporary directory printed in the result. Push failures preserve the commit; --resume continues after resolving the cause. No global Git identity/authentication settings are changed. Remote branches and repositories are never deleted automatically. API-reported push permissions are distinct from a passed write test.

Exit codes: 0 mandatory requested checks passed; 1 network/API failure; 2 required authentication unavailable/rejected; 3 repository permission denied; 4 invalid arguments; 5 partial/limited result or write failure; 6 unexpected internal error. Optional missing tools and unconfigured authentication do not fail public connectivity.

```console
python -m venv .venv
.venv/Scripts/python -m pip install build
.venv/Scripts/python -m unittest discover -s tests -v
.venv/Scripts/python -m build
```

Set PYTHONPATH=src for source tests, or install the package into the test environment first. Failure tests use local fixtures/mock HTTP servers; routine tests create no remote repositories. GitHub API behavior references: https://docs.github.com/en/rest/using-the-rest-api/rate-limits-for-the-rest-api and https://docs.github.com/en/rest/using-the-rest-api/troubleshooting-the-rest-api.
