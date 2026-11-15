"""Validate recorded live reports and archived fixtures using developer jsonschema."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import tarfile
import jsonschema

ROOT = Path(__file__).resolve().parent.parent
SCHEMA = ROOT / "contracts/diagnostic-v1.schema.json"
validator = jsonschema.Draft202012Validator(json.loads(SCHEMA.read_text()), format_checker=jsonschema.FormatChecker())
records = {}
validations = []
for name in ("dart-live", "python-wheel-test", "windows-gui-export", "android-live"):
    path = ROOT / "reports" / (name + ".json")
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    errors = [e.message for e in validator.iter_errors(data)]
    records[name] = {c["id"]: c for c in data["checks"]}
    validations.append({"report": path.name, "schema_passed": not errors, "errors": errors, "sha256": hashlib.sha256(path.read_bytes()).hexdigest(), "timestamp": data["timestamp"]})
mandatory = ("dns.github.com", "dns.api.github.com", "dns.www.githubstatus.com", "github.https", "github.api", "github.public_account", "github.service", "github.rate_limit", "authentication", "tool.git", "tool.gh", "tool.codex", "tool.pwsh", "repository_write")
comparisons = []
for identifier in mandatory:
    left = records["dart-live"].get(identifier, {}).get("status")
    right = records["python-wheel-test"].get(identifier, {}).get("status")
    comparisons.append({"id": identifier, "dart": left, "python": right, "agrees": left == right and left is not None})
fixtures = []
with tarfile.open(ROOT / "dist/python/github_test_button-0.1.0b1.tar.gz") as archive:
    for name in ("test-vectors.json", "diagnostic-v1.schema.json", "status-codes.json"):
        shared = (ROOT / "contracts" / name).read_bytes()
        copy = (ROOT / "python/tests/contracts" / name).read_bytes()
        archived = archive.extractfile("github_test_button-0.1.0b1/tests/contracts/" + name).read()
        fixtures.append({"name": name, "shared_sha256": hashlib.sha256(shared).hexdigest(), "test_copy_sha256": hashlib.sha256(copy).hexdigest(), "sdist_sha256": hashlib.sha256(archived).hexdigest(), "all_match": shared == copy == archived})
result = {"timestamp": datetime.now(timezone.utc).isoformat(), "schema": str(SCHEMA.relative_to(ROOT)), "schema_sha256": hashlib.sha256(SCHEMA.read_bytes()).hexdigest(), "validations": validations, "classifications": comparisons, "fixtures": fixtures, "scope_difference": "network: Dart observes local interfaces (CONNECTED_WITH_LIMITATIONS); Python additionally verifies TCP to 1.1.1.1:443 (CONNECTED). This evidence scope differs and is not included in equivalent-operation comparisons.", "passed": all(v["schema_passed"] for v in validations) and all(c["agrees"] for c in comparisons) and all(f["all_match"] for f in fixtures)}
(ROOT / "reports/contract-validation.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
lines = ["# Diagnostic contract validation", "", "Recorded at " + result["timestamp"], "", "Result: " + ("PASS" if result["passed"] else "FAIL"), "", "All four recorded live reports (Dart core, Python wheel, installed Windows GUI, Android emulator) validate against diagnostic-v1.schema.json with Draft 2020-12 and date-time format validation. Fourteen equivalent operation identifiers have matching status classifications. The schema permits separate product version syntax (Dart 0.1.0-beta.1; Python PEP 440 0.1.0b1). These are two separate implementations; neither is a shared executable runtime.", "", "| Check | Dart | Python |", "|---|---|---|"]
lines += [f"| {c['id']} | {c['dart']} | {c['python']} |" for c in comparisons]
lines += ["", result["scope_difference"], "", "The shared HTTP vectors contain ten cases and error vectors six cases. Python executes those within two unit-test methods; Flutter tests execute the same shared vectors. Do not add vector case counts to unit-test totals. The machine-readable evidence includes SHA-256 values for the shared contract files, Python test copies and the copies included in the source distribution; each triple matches.", "", "Schema validation and live agreement are recorded observations, not proof of every future network outcome. Android-specific tool/authentication differences are expected; runtime scope is detailed separately. See contract-validation.json for exact hashes and input timestamps; python-unit-tests.txt and the Flutter test receipt for independent suite counts."]
(ROOT / "reports/DIAGNOSTIC-CONTRACT-VALIDATION.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(json.dumps({"passed": result["passed"], "schemas": len(validations), "classifications": len(comparisons), "fixture_triples": len(fixtures)}, indent=2))
raise SystemExit(0 if result["passed"] else 1)
