"""Run installed-wheel acceptance from a clean working directory; no writes to GitHub."""
import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import subprocess
import tempfile


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--gtb", required=True)
    p.add_argument("--python", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()
    output = Path(args.output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    environment = os.environ.copy()
    environment.pop("PYTHONPATH", None)
    environment.pop("PYTHONHOME", None)
    checks = []
    def execute(name, arguments, expected=(0,), json_result=False):
        process = subprocess.run([args.gtb, *arguments], cwd=working, env=environment, text=True, encoding="utf-8", errors="replace", capture_output=True, timeout=180)
        artifact = output / ("python-wheel-" + name + (".json" if json_result else ".txt"))
        artifact.write_text(process.stdout or process.stderr, encoding="utf-8")
        valid = process.returncode in expected
        if json_result:
            try:
                data = json.loads(process.stdout)
                valid = valid and data.get("schema_version") == "1.0"
                if name == "test":
                    mandatory = ("github.api", "github.https", "dns.github.com", "dns.api.github.com")
                    valid = valid and all(next(c for c in data["checks"] if c["id"] == identifier)["status"] == "CONNECTED" for identifier in mandatory)
            except (ValueError, StopIteration, KeyError):
                valid = False
        checks.append({"name": name, "exit_code": process.returncode, "passed": valid, "evidence": artifact.name})
    with tempfile.TemporaryDirectory(prefix="gtb-wheel-acceptance-") as working:
        inspect = subprocess.run([args.python, "-I", "-c", "import github_test_button; print(github_test_button.__file__)"], cwd=working, env=environment, text=True, capture_output=True)
        checks.append({"name": "isolated_import", "exit_code": inspect.returncode, "passed": inspect.returncode == 0 and "site-packages" in inspect.stdout, "installed_module": inspect.stdout.strip()})
        execute("help", ["--help"])
        execute("version", ["version"])
        execute("status", ["status"], (0,))
        execute("test", ["test", "--json"], (0,), True)
        execute("auth", ["auth", "status", "--json"], (0,), True)
        execute("repository", ["repo", "check", "chatgptopenaiagi/GITHUB-TEST-BUTTON", "--json"], (0,), True)
        execute("doctor", ["doctor", "--json"], (0,), True)
        execute("invalid", ["nonexistent-command"], (4,))
        execute("write_requires_confirmation", ["write-test", "--repo", "chatgptopenaiagi/GITHUB-TEST-BUTTON"], (4,))
    result = {"timestamp": datetime.now(timezone.utc).isoformat(), "platform": os.name, "tests_run": len(checks), "passed": sum(c["passed"] for c in checks), "failed": sum(not c["passed"] for c in checks), "remote_write_performed": False, "checks": checks}
    (output / "python-wheel-verification.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if result["failed"] == 0 else 1


if __name__ == "__main__":
    raise SystemExit(main())
