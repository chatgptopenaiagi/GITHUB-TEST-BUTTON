"""Read existing credentials in memory only. Never export token material."""
import os
import shutil
import subprocess
from .models import Check
from .github_api import Client
from .utilities import run


def credential():
    for name in ("GH_TOKEN", "GITHUB_TOKEN"):
        if os.environ.get(name):
            return os.environ[name], "environment"
    gh = shutil.which("gh")
    if gh:
        try:
            result = run([gh, "auth", "token", "--hostname", "github.com"], timeout=10)
            if result.returncode == 0 and result.stdout.strip():
                return result.stdout.strip(), "GitHub CLI credential store"
        except (OSError, subprocess.TimeoutExpired):
            pass
    return None, "none"


def auth_status(client=None, provider=None):
    if client is None:
        token, provider = credential()
        client = Client(token)
    if not client.token:
        return Check("authentication", "UNAUTHENTICATED", "Authentication is not configured. Public GitHub diagnostics remain available.", details={"provider": provider or "none"}), None
    check, data = client.request("/user", "authentication")
    check.details["provider"] = provider or "configured credential"
    if check.status == "AUTHENTICATION_EXPIRED":
        check.message = "Configured credentials were rejected; they may be expired, revoked or invalid"
    if check.status == "CONNECTED" and isinstance(data, dict) and isinstance(data.get("login"), str):
        account = {k: data.get(k) for k in ("login", "html_url", "avatar_url", "public_repos", "followers")}
        check.message = "Authenticated account identity verified"
        check.details["account"] = account
        return check, account
    if check.status == "CONNECTED":
        check.status, check.message = "API_UNAVAILABLE", "Account API response is missing an identity"
    return check, None
