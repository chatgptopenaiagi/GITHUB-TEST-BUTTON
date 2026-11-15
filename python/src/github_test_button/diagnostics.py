import queue
import socket
import threading
import time
from .models import Check, report
from .github_api import Client
from .authentication import credential, auth_status
from .git_tools import tool_check


def dns_check(host, timeout=8):
    started = time.monotonic()
    results = queue.Queue()
    def lookup():
        try:
            results.put((True, sorted({x[4][0] for x in socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)})))
        except OSError:
            results.put((False, []))
    threading.Thread(target=lookup, daemon=True).start()
    try:
        success, addresses = results.get(timeout=timeout)
        return Check("dns." + host, "CONNECTED" if success else "DNS_FAILURE", "DNS resolution verified" if success else "DNS resolution failed", (time.monotonic() - started) * 1000, {"addresses": addresses})
    except queue.Empty:
        return Check("dns." + host, "TIMEOUT", "DNS lookup timed out", (time.monotonic() - started) * 1000)


def network_check(timeout=8):
    started = time.monotonic()
    try:
        with socket.create_connection(("1.1.1.1", 443), timeout=timeout):
            return Check("network", "CONNECTED", "External TCP connectivity verified to 1.1.1.1:443", (time.monotonic() - started) * 1000)
    except OSError:
        return Check("network", "CONNECTED_WITH_LIMITATIONS", "Independent TCP probe failed; firewall policy may block this target. GitHub checks determine actual reachability.", (time.monotonic() - started) * 1000)


def diagnose(timeout=8, public_account="octocat", progress=None):
    started = time.monotonic()
    checks = []
    def add(check):
        checks.append(check)
        if progress:
            progress(check)
    add(network_check(timeout))
    for host in ("github.com", "api.github.com", "www.githubstatus.com"):
        add(dns_check(host, timeout))
    public = Client(timeout=timeout)
    add(public.request("https://github.com", "github.https", expect_json=False)[0])
    check, data = public.request("/", "github.api")
    if check.status == "CONNECTED" and (not isinstance(data, dict) or "current_user_url" not in data):
        check.status, check.message = "API_UNAVAILABLE", "Unexpected GitHub API response"
    add(check)
    check, data = public.request("/users/" + public_account, "github.public_account")
    if check.status == "CONNECTED":
        if not isinstance(data, dict) or not isinstance(data.get("login"), str):
            check.status, check.message = "API_UNAVAILABLE", "Unexpected public account response"
        else:
            check.details["login"] = data["login"]
    add(check)
    check, data = public.request("https://www.githubstatus.com/api/v2/summary.json", "github.service")
    if check.status == "CONNECTED":
        if not isinstance(data, dict) or not isinstance(data.get("status"), dict):
            check.status, check.message = "API_UNAVAILABLE", "Unexpected service-status response"
        else:
            check.details.update({"published_status": data["status"], "incidents": data.get("incidents", []), "components": data.get("components", []), "retrieved_at": report([])["timestamp"]})
            check.message = str(data["status"].get("description", "Status retrieved"))
            if data["status"].get("indicator") != "none":
                check.status = "CONNECTED_WITH_LIMITATIONS"
    add(check)
    token, provider = credential()
    authenticated = Client(token, timeout=timeout)
    check, account = auth_status(authenticated, provider)
    add(check)
    check, data = authenticated.request("/rate_limit", "github.rate_limit")
    if check.status == "CONNECTED":
        if not isinstance(data, dict) or not isinstance(data.get("resources"), dict):
            check.status, check.message = "API_UNAVAILABLE", "Unexpected rate-limit response"
        else:
            check.details["resources"] = data["resources"]
    add(check)
    for name in ("git", "gh", "codex", "pwsh"):
        add(tool_check(name))
    add(Check("repository_write", "NOT_TESTED", "Use the separate explicitly confirmed write-test command"))
    return report(checks, (time.monotonic() - started) * 1000, account=account)
