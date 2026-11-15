from dataclasses import dataclass, field, asdict
import platform
from . import __version__
from .utilities import utcnow, redact


@dataclass
class Check:
    id: str
    status: str
    message: str
    duration_ms: float = 0
    details: dict = field(default_factory=dict)

    def to_dict(self):
        return redact(asdict(self))


def report(checks, duration_ms=0, **extra):
    return redact({"application": "GITHUB TEST BUTTON", "version": __version__, "schema_version": "1.0", "platform": platform.system().lower(), "timestamp": utcnow(), "duration_ms": round(duration_ms, 2), "checks": [c.to_dict() if isinstance(c, Check) else c for c in checks], "repository_write": {"status": "NOT_TESTED"}, **extra})


def classify_http(code, headers=None):
    headers = {k.lower(): str(v) for k, v in (headers or {}).items()}
    if 200 <= code < 300:
        return "CONNECTED"
    if code == 429 or (code == 403 and (headers.get("x-ratelimit-remaining") == "0" or "retry-after" in headers)):
        return "RATE_LIMITED"
    if code == 401:
        return "AUTHENTICATION_EXPIRED"
    if code in (403, 404):
        return "ACCESS_DENIED"
    if code >= 500:
        return "API_UNAVAILABLE"
    return "UNKNOWN_ERROR"


def classify_error(kind):
    return {"dns": "DNS_FAILURE", "tls": "TLS_FAILURE", "timeout": "TIMEOUT", "network": "NETWORK_UNAVAILABLE", "malformed": "API_UNAVAILABLE"}.get(kind, "UNKNOWN_ERROR")
