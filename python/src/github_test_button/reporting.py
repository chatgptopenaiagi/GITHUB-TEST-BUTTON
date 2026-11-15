import json
from .utilities import redact


def render(value, json_output=False):
    value = redact(value)
    if json_output:
        return json.dumps(value, indent=2, ensure_ascii=False)
    if "checks" not in value:
        return "\n".join(f"{key}: {entry}" for key, entry in value.items())
    rows = [f"GITHUB TEST BUTTON {value['version']}", f"{value['platform']} | {value['timestamp']}", ""]
    rows.extend(f"{check['id']}: {check['status']} — {check['message']}" for check in value["checks"])
    rows.extend(["", f"Duration: {value['duration_ms']:.0f} ms", "CONNECTED verifies only the named operation. Write access is separate."])
    return "\n".join(rows)


def exit_code(value, auth_required=False, repo_required=False):
    checks = value.get("checks", [{"id": "write", "status": value.get("status", "UNKNOWN_ERROR")}])
    if auth_required:
        statuses = {c["status"] for c in checks if c["id"] == "authentication"}
        if statuses & {"UNAUTHENTICATED", "AUTHENTICATION_EXPIRED"}:
            return 2
        if statuses & {"NETWORK_UNAVAILABLE", "DNS_FAILURE", "TLS_FAILURE", "API_UNAVAILABLE", "TIMEOUT"}:
            return 1
        if "ACCESS_DENIED" in statuses:
            return 3
        if statuses - {"CONNECTED"}:
            return 5
    if repo_required and any(c["status"] == "ACCESS_DENIED" for c in checks):
        return 3
    mandatory = [c for c in checks if not c["id"].startswith("tool.") and c["id"] not in ("authentication", "repository_write", "network")]
    if any(c["status"] in ("NETWORK_UNAVAILABLE", "DNS_FAILURE", "TLS_FAILURE", "API_UNAVAILABLE", "TIMEOUT") for c in mandatory):
        return 1
    if any(c["status"] not in ("CONNECTED", "NOT_TESTED", "UNAUTHENTICATED", "TOOL_NOT_INSTALLED", "UNSUPPORTED_ON_PLATFORM") for c in mandatory):
        return 5
    return 0
