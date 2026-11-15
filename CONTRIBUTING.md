# Contributing

Use a dedicated checkout. Keep runtime code independent of developer machine paths. Changes to diagnostic meanings require matching contract fixtures and Python/Dart tests. Never replace a real failed test with a fabricated success.

Run `scripts/Test-All.ps1` and the affected platform build before submitting a change. Include the commands and actual outcomes. Keep remote mutation tests opt-in, target only a repository you control, and retain test branch/repository URLs. Never put credentials, keystores, personal data, or generated binary builds in source commits.
