import base64
import json
import os
import re
from pathlib import Path
import shutil
import subprocess
import tempfile
import uuid
from .authentication import credential, auth_status
from .github_api import Client
from .models import Check, report
from .utilities import repo_name, run, utcnow, redact


def inspect_repository(name, client=None):
    name = repo_name(name)
    client = client or Client(credential()[0])
    check, data = client.request("/repos/" + name, "repository")
    checks = [check]
    if check.status == "CONNECTED":
        if not isinstance(data, dict) or not data.get("full_name"):
            check.status, check.message = "API_UNAVAILABLE", "Unexpected repository response"
            return report(checks)
        check.details.update({k: data.get(k) for k in ("full_name", "private", "description", "default_branch", "clone_url", "html_url", "permissions")})
        check.details["write_verification"] = "NOT_TESTED"
        for endpoint, identifier in (("/contents", "repository.files"), ("/commits?per_page=1", "repository.commits"), ("/releases?per_page=5", "repository.releases")):
            item, content = client.request("/repos/" + name + endpoint, identifier)
            if item.status == "CONNECTED":
                if not isinstance(content, list):
                    item.status, item.message = "API_UNAVAILABLE", "Unexpected repository response"
                elif identifier.endswith("files"):
                    item.details["files"] = [{"name": c.get("name"), "type": c.get("type")} for c in content[:100] if isinstance(c, dict)]
                elif identifier.endswith("commits"):
                    item.details["latest_commit"] = content[0].get("sha") if content else None
                else:
                    item.details["releases"] = [{"tag_name": c.get("tag_name"), "html_url": c.get("html_url"), "prerelease": c.get("prerelease")} for c in content if isinstance(c, dict)]
            checks.append(item)
    return report(checks, sum(c.duration_ms for c in checks))


STATES = ["NOT_INITIALIZED", "DIRECTORY_CREATED", "GIT_INITIALIZED", "FILES_CREATED", "FILES_STAGED", "COMMIT_CREATED", "REMOTE_READY", "PUSH_COMPLETED", "REMOTE_VERIFIED"]


class WriteTest:
    """A unique orphan branch contains only a generated marker, never user files."""
    def __init__(self, target=None, new=False, confirm=False, resume=None):
        self.target = repo_name(target) if target else None
        self.new, self.confirm = new, confirm
        self.directory = Path(resume).resolve() if resume else None
        self.result = {"schema_version": "1.0", "state": STATES[0], "target": target or "", "transitions": [STATES[0]], "status": "NOT_TESTED"}
        if self.directory:
            self.result = json.loads((self.directory / "gtb-state.json").read_text(encoding="utf-8"))
            if self.result.get("state") not in STATES or self.result.get("schema_version") != "1.0":
                raise ValueError("Invalid GTB resume state")
            self.target = repo_name(self.result["target"])
            if target and target != self.target:
                raise ValueError("Resume target does not match the explicitly selected repository")
            if not re.fullmatch(r"gtb-verify-[a-f0-9]{12}", self.result.get("branch", "")):
                raise ValueError("Invalid resume branch")
            if not re.fullmatch(r"GTB verification [a-f0-9]{32}\n", self.result.get("marker", "")):
                raise ValueError("Invalid resume marker")
            if STATES.index(self.result["state"]) >= 5 and not re.fullmatch(r"[a-f0-9]{40,64}", self.result.get("commit", "")):
                raise ValueError("Invalid resume commit")
            self.new = self.result.get("new_repository", False)
            if Path(self.result["local_directory"]).resolve() != self.directory:
                raise ValueError("Resume directory does not match state")

    def save(self):
        if self.directory and self.directory.exists():
            (self.directory / "gtb-state.json").write_text(json.dumps(redact(self.result), indent=2), encoding="utf-8")

    def advance(self, state):
        if STATES.index(state) != STATES.index(self.result["state"]) + 1:
            raise RuntimeError("Invalid write-test state transition")
        self.result["state"] = state
        self.result["transitions"].append(state)
        self.save()

    def command(self, args):
        environment = os.environ.copy()
        environment.update(GIT_TERMINAL_PROMPT="0", GH_PROMPT_DISABLED="1")
        outcome = run(args, cwd=self.directory, timeout=60, env=environment)
        if outcome.returncode:
            raise RuntimeError("Command failed: " + redact((outcome.stderr or outcome.stdout).strip())[:1200])
        return outcome.stdout.strip()

    def verify_push_scope(self, git):
        if self.command([git, "remote", "get-url", "origin"]) != self.result["url"] + ".git":
            raise RuntimeError("Origin does not match the confirmed target")
        if self.command([git, "branch", "--show-current"]) != self.result["branch"]:
            raise RuntimeError("Local branch does not match the test branch")
        if self.command([git, "rev-parse", "HEAD"]) != self.result["commit"]:
            raise RuntimeError("Local commit differs from the recorded test commit")
        if self.command([git, "ls-tree", "--name-only", "HEAD"]) != "GTB-VERIFY.txt":
            raise RuntimeError("Test commit contains unexpected files")
        if self.command([git, "show", "HEAD:GTB-VERIFY.txt"]) != self.result["marker"].strip():
            raise RuntimeError("Committed marker does not match test state")

    def execute(self):
        if not self.confirm:
            raise ValueError("Write tests require --confirm and an explicit --repo or --new scope")
        git, gh = shutil.which("git"), shutil.which("gh")
        if not git or not gh:
            self.result.update(status="TOOL_NOT_INSTALLED", message="Git and GitHub CLI are required for the explicit write test")
            return self.result
        token, provider = credential()
        client = Client(token)
        auth, account = auth_status(client, provider)
        if auth.status != "CONNECTED":
            self.result.update(status=auth.status, message=auth.message)
            return self.result
        try:
            if not self.target:
                if not self.new:
                    raise ValueError("Choose --repo OWNER/REPO or --new")
                self.target = account["login"] + "/GTB-VERIFY-" + utcnow().replace("-", "").replace(":", "").split(".")[0].replace("Z", "") + "-" + uuid.uuid4().hex[:6]
                self.result["target"] = self.target
            if self.target.split("/")[0].lower() != account["login"].lower():
                raise PermissionError("Write tests are restricted to a repository owned by the authenticated user")
            self.result["url"] = "https://github.com/" + self.target
            if not self.new:
                check, metadata = client.request("/repos/" + self.target, "repository")
                if check.status != "CONNECTED" or not isinstance(metadata, dict) or not metadata.get("permissions", {}).get("push"):
                    self.result.update(status="ACCESS_DENIED", message="Repository push permission was not confirmed by API")
                    return self.result
            index = STATES.index(self.result["state"])
            if index == 0:
                self.directory = Path(tempfile.mkdtemp(prefix="gtb-write-"))
                self.result.update(local_directory=str(self.directory), new_repository=self.new, branch="gtb-verify-" + uuid.uuid4().hex[:12], marker="GTB verification " + uuid.uuid4().hex + "\n")
                self.advance("DIRECTORY_CREATED")
            if STATES.index(self.result["state"]) < 2:
                self.command([git, "init", "-b", self.result["branch"]])
                self.advance("GIT_INITIALIZED")
            if STATES.index(self.result["state"]) < 3:
                (self.directory / "GTB-VERIFY.txt").write_bytes(self.result["marker"].encode("utf-8"))
                self.advance("FILES_CREATED")
            if STATES.index(self.result["state"]) < 4:
                self.command([git, "add", "--", "GTB-VERIFY.txt"])
                self.advance("FILES_STAGED")
            if STATES.index(self.result["state"]) < 5:
                self.command([git, "-c", "user.name=GTB Verification", "-c", "user.email=gtb-test@localhost", "commit", "-m", "GTB explicit write verification"])
                self.result["commit"] = self.command([git, "rev-parse", "HEAD"])
                self.advance("COMMIT_CREATED")
            if STATES.index(self.result["state"]) < 6:
                if self.new:
                    if self.result.get("creation_attempted"):
                        check, metadata = client.request("/repos/" + self.target, "repository")
                        if check.status != "CONNECTED":
                            raise RuntimeError("Previous creation attempt is unresolved. Verify the recorded repository before retrying; no duplicate creation attempted.")
                    else:
                        self.result["creation_attempted"] = True
                        self.save()
                        self.command([gh, "repo", "create", self.target, "--private", "--description", "Explicit GITHUB TEST BUTTON verification repository"])
                existing = self.command([git, "remote"])
                if "origin" not in existing.splitlines():
                    self.command([git, "remote", "add", "origin", self.result["url"] + ".git"])
                elif self.command([git, "remote", "get-url", "origin"]) != self.result["url"] + ".git":
                    raise RuntimeError("Origin does not match the confirmed target")
                self.advance("REMOTE_READY")
            if STATES.index(self.result["state"]) < 7:
                self.verify_push_scope(git)
                self.command([git, "-c", "credential.helper=", "-c", "credential.helper=!gh auth git-credential", "push", "--set-upstream", "origin", self.result["branch"]])
                self.advance("PUSH_COMPLETED")
            if STATES.index(self.result["state"]) < 8:
                check, data = client.request("/repos/" + self.target + "/contents/GTB-VERIFY.txt?ref=" + self.result["branch"], "repository_write")
                if check.status != "CONNECTED" or not isinstance(data, dict) or base64.b64decode(data.get("content", "")).decode("utf-8") != self.result["marker"]:
                    raise RuntimeError("Remote content readback did not match the generated marker")
                check, data = client.request("/repos/" + self.target + "/commits/" + self.result["branch"], "repository_write")
                if check.status != "CONNECTED" or not isinstance(data, dict) or data.get("sha") != self.result["commit"]:
                    raise RuntimeError("Remote commit readback did not match the local commit")
                self.advance("REMOTE_VERIFIED")
            self.result.update(status="CONNECTED", message="Unique test branch push, commit and content readback verified. Nothing was deleted.")
        except PermissionError as exc:
            self.result.update(status="ACCESS_DENIED", message=str(exc))
        except (OSError, ValueError, RuntimeError, subprocess.TimeoutExpired) as exc:
            self.result.update(status="TIMEOUT" if isinstance(exc, subprocess.TimeoutExpired) else "UNKNOWN_ERROR", message=redact(str(exc)), retry="Use --resume LOCAL_DIRECTORY --confirm after resolving the reported problem")
        self.save()
        return redact(self.result)
