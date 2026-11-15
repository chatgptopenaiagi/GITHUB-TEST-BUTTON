# Python wheel build and verification

GTB Python 0.1.0b1 is built and installed successfully on the Windows development machine using Python 3.10.0. Runtime code has no third-party dependencies or hard-coded development directories. The wheel is correctly tagged `py3-none-any`, with the `gtb` entry point. Linux/macOS runtime compatibility is designed but not locally executed.

Artifacts:

| Artifact | Bytes | SHA-256 |
|---|---:|---|
| dist/python/github_test_button-0.1.0b1-py3-none-any.whl | 16481 | 8d2972f2763c35eb4fce23a1b11ff583f8c47fb3ed28781237c40f9ef539ce9f |
| dist/python/github_test_button-0.1.0b1.tar.gz | 20576 | e9d710f04f073f44993735dbe578dafafce6218c8c9aa8ca546b096dcb51f8f5 |

The dedicated `python/.venv-build` contains build 1.6.1, setuptools 84.2.1 and wheel 0.48.0. Initial builds used PEP 517 transient isolated environments; the final rebuild reused this dedicated virtual environment with `python -m build --no-isolation --outdir ../dist/python`. No system Python packages were changed. The wheel was force-installed without dependencies into the separate `python/.venv-verify` environment. Acceptance ran from a disposable working directory with PYTHONPATH/PYTHONHOME removed; isolated Python import resolved to this environment's site-packages.

61 automated unittest methods passed, with zero failures and zero skips, both against source and the installed wheel. These are the same 61 tests executed twice; count them once. They cover ten shared HTTP vectors, six error vectors, local mock HTTP responses, malformed/scalar JSON, DNS/TLS/timeouts, bounded retries, authentication, rate limits, redaction, private-repository uncertainty, CLI output/exit codes, report files, confirmed write-state progression, commit/push failure, remote readback mismatch, tampered resume branch/origin/push URL, completed-resume revalidation, and an actual local Git commit. No remote repositories are created by these tests.

Ten separate installed-wheel acceptance checks passed: isolated import, help, version, live status, live JSON suite, authenticated identity, product repository inspection, tool doctor, invalid arguments, and write-without-confirmation refusal. Live status and test both returned exit 0. DNS, github.com HTTPS, GitHub API, public account lookup, GitHub service status, rate limits, existing authentication and the four installed tool version commands returned CONNECTED. Repository writes remained NOT_TESTED during this read-only acceptance.

The parent mission separately executed the authorized existing-product-repository write test and independently read back its commit. That evidence is in `real-write-test.json` and `independent-write-readback.json`; it is not included in the ten read-only wheel acceptance checks. New-private-repository creation is covered by controlled fixtures but was not separately executed live.

An initial live request to github.com returned HTTP 406 because the HTML probe used the REST API media type. This was repaired by selecting Accept headers according to target/content type and adding a regression test. The first acceptance harness accepted partial exit 5 too broadly; its initial output is preserved in `python-wheel-initial-verification.json`, with the failing response in `python-wheel-initial-http406.json`. The final harness requires exit 0 and explicitly checks successful HTTPS/API/DNS statuses. Final evidence supersedes the initial permissive result without erasing it.

The initial attempt to install source in editable mode used pip 21.2.3, which did not support this pyproject editable install. Source tests were subsequently run using scoped PYTHONPATH; final wheel tests require no editable installation. This was a test-environment setup issue, not a released-package dependency.

Evidence: `python-build-evidence.json`, `python-build.txt`, `python-unit-tests.txt`, `python-wheel-unit-tests.txt`, `python-wheel-verification.json`, and the per-command `python-wheel-*.json/.txt` records. Shared schema validation and archived fixture hashes are in `contract-validation.json`.
