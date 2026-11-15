"""Safe reporting and bounded process helpers."""
import os
import re
import subprocess
from datetime import datetime, timezone


def utcnow():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def redact(value):
    if isinstance(value, dict):
        return {str(k): ("[REDACTED]" if re.search(r"token|password|secret|authorization|cookie|private.key", str(k), re.I) else redact(v)) for k, v in value.items()}
    if isinstance(value, list):
        return [redact(v) for v in value]
    if not isinstance(value, str):
        return value
    text = re.sub(r"(?i)((?:https?|ssh)://)[^\s/@]+@", r"\1[REDACTED]@", value)
    text = re.sub(r"\b(?:gh[pousr]_[A-Za-z0-9_]+|github_pat_[A-Za-z0-9_]+)\b", "[REDACTED]", text)
    text = re.sub(r"(?i)(?:Bearer|token)\s+[A-Za-z0-9_.\-]+", "[REDACTED]", text)
    text = re.sub(r"(?i)([?&](?:access_token|token|password|secret)=)[^&\s]+", r"\1[REDACTED]", text)
    for name in ("GH_TOKEN", "GITHUB_TOKEN"):
        secret = os.environ.get(name)
        if secret:
            text = text.replace(secret, "[REDACTED]")
    return text


def run(args, cwd=None, timeout=20, input_text=None, env=None):
    options = dict(cwd=cwd, timeout=timeout, input=input_text, text=True, encoding="utf-8", errors="replace", capture_output=True, shell=False, env=env)
    if os.name == "nt":
        options["creationflags"] = subprocess.CREATE_NO_WINDOW
    return subprocess.run(args, **options)


def repo_name(value):
    if not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,38})/[A-Za-z0-9_.-]{1,100}", value) or value.split("/")[1] in (".", ".."):
        raise ValueError("Use OWNER/REPOSITORY without URL, spaces or command options.")
    return value
