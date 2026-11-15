"""Bounded pre-publication scan. Outputs file names, never matched secret values."""
import json
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(__file__).resolve().parents[1]
paths = subprocess.check_output(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=root
).decode("utf-8").split("\0")
rules = {
    "private_key": re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    "github_credential": re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{60,})\b"),
    "credential_url": re.compile(rb"https?://[^\s/\"'<>]+:[^\s/\"'<>]+@"),
}
findings = []
count = 0
for name in sorted(set(paths)):
    if not name:
        continue
    path = root / name
    if not path.is_file():
        continue
    # Fixtures deliberately exercise redaction using synthetic credentials.
    if "/tests/" in "/" + name or "/test/" in "/" + name:
        continue
    if path.suffix.lower() in {".png", ".ico", ".jpg", ".zip", ".whl", ".apk", ".exe"}:
        continue
    if path.stat().st_size > 2_000_000:
        continue
    count += 1
    data = path.read_bytes()
    for rule, expression in rules.items():
        if expression.search(data):
            findings.append({"file": name, "rule": rule})
    if path.name == "key.properties" or path.suffix.lower() in {".jks", ".keystore", ".p12"}:
        findings.append({"file": name, "rule": "signing_material"})
result = {"checked_text_files": count, "findings": findings,
          "scope": "Tracked and nonignored source text; synthetic test fixtures excluded. Pattern scan is not a security audit."}
print(json.dumps(result, indent=2))
sys.exit(bool(findings))
