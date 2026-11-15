# Python CLI

Requires Python3.10 or newer. The wheel is pure Python and has no third-party runtime dependencies. Optional local Git and GitHub CLI enable repository engineering.

```console
python -m venv gtb-env
# Windows: gtb-env\Scripts\activate
# Unix: source gtb-env/bin/activate
python -m pip install github_test_button-0.1.0b1-py3-none-any.whl
gtb --help
gtb version
gtb status
gtb test --all --json
gtb doctor
gtb auth status --json
gtb repo check OWNER/REPO --json
gtb repo capabilities OWNER/REPO
gtb report --json --output gtb-report.json
gtb report --output gtb-report.txt
```

`status`, `test` and `report` perform fresh read-only diagnostics; `report` is not a cache of an earlier run. `--all` remains read-only. `doctor` detects and executes tool version queries. `--timeout` controls each network timeout (0.1–60seconds); at most one retry applies to selected transient read failures. A full multi-step run can take longer than one timeout.

The independent network probe uses TCP to `1.1.1.1:443`; a blocked probe alone does not establish GitHub failure. GitHub-specific DNS/HTTPS/API results remain authoritative for the requested operation. Existing `GH_TOKEN`/`GITHUB_TOKEN` values or GitHub CLI credentials can provide authentication in memory; they are never included in report exports.

## Explicit write operations

```console
gtb write-test --repo OWNER/REPO --confirm --json
gtb write-test --new --confirm --json
gtb write-test --resume PATH_TO_RECORDED_TEST_DIRECTORY --confirm --json
```

Existing-repository mode creates a unique orphan test branch with only the generated marker. New mode creates a uniquely named private repository. These commands have real remote effects. The target must belong to the authenticated personal account. The local journal preserves progress and supports a validated retry; remote resources are never automatically removed.

## Exit codes

| Code | Meaning |
|---|---|
| 0 | Requested mandatory checks passed; optional unauthenticated/tool states may remain |
| 1 | Required connectivity check failed |
| 2 | Explicit authentication operation requires unavailable/rejected credentials |
| 3 | Repository/explicit operation access denied |
| 4 | Invalid arguments or confirmation/scope missing |
| 5 | Partial result, rate limitation, interrupted or incomplete write operation |
| 6 | Unexpected internal error |

Always inspect individual JSON checks when automating. A zero read-only exit code never proves push access. The package's own tests cover Windows execution and mocked portable behavior; actual Unix validation is reported separately by CI.
