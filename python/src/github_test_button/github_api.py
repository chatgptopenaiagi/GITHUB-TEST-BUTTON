"""HTTPS transport: bounded reads, safe headers and no credential-bearing redirects."""
import json
import socket
import ssl
import time
import urllib.error
import urllib.parse
import urllib.request
from .models import Check, classify_http, classify_error


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class Client:
    def __init__(self, token=None, timeout=8, retries=1, base="https://api.github.com"):
        self.token = token
        self.timeout = timeout
        self.retries = min(max(retries, 0), 1)
        self.base = base.rstrip("/")
        self.opener = urllib.request.build_opener(NoRedirect())

    def request(self, target, identifier="github.api", expect_json=True):
        url = target if "://" in target else self.base + target
        parsed_url = urllib.parse.urlsplit(url)
        accept = "application/vnd.github+json" if parsed_url.netloc == "api.github.com" else "application/json" if expect_json else "text/html, */*;q=0.8"
        headers = {"User-Agent": "GITHUB-TEST-BUTTON/0.1.0b1", "Accept": accept}
        if self.token and parsed_url.scheme == "https" and parsed_url.netloc == "api.github.com":
            headers["Authorization"] = "Bearer " + self.token
        started = time.monotonic()
        data = None
        for attempt in range(self.retries + 1):
            code = None
            safe_headers = {}
            try:
                with self.opener.open(urllib.request.Request(url, headers=headers), timeout=self.timeout) as response:
                    code = response.status
                    safe_headers = {k.lower(): v for k, v in response.headers.items() if k.lower() in ("x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset", "x-ratelimit-resource", "retry-after")}
                    raw = response.read(2_000_001)
                    if len(raw) > 2_000_000:
                        raise ValueError("Response exceeds diagnostic limit")
                    data = json.loads(raw) if expect_json else None
                    status, message = classify_http(code, safe_headers), "HTTPS request verified"
            except urllib.error.HTTPError as exc:
                code = exc.code
                safe_headers = {k.lower(): v for k, v in exc.headers.items() if k.lower() in ("x-ratelimit-limit", "x-ratelimit-remaining", "x-ratelimit-reset", "retry-after")}
                status = classify_http(code, safe_headers)
                if code == 403:
                    try:
                        error_body = json.loads(exc.read(8192))
                        if isinstance(error_body, dict) and "rate limit" in str(error_body.get("message", "")).lower():
                            status = "RATE_LIMITED"
                    except (ValueError, OSError):
                        pass
                message = "Resource absent or inaccessible; private resources may return 404" if code == 404 else f"HTTP {code}"
                exc.close()
            except (json.JSONDecodeError, UnicodeDecodeError, ValueError):
                status, message = "API_UNAVAILABLE", "Expected API response was malformed or too large"
            except (TimeoutError, socket.timeout):
                status, message = "TIMEOUT", "Request timed out"
            except ssl.SSLError:
                status, message = "TLS_FAILURE", "TLS certificate or handshake verification failed"
            except urllib.error.URLError as exc:
                reason = exc.reason
                kind = "dns" if isinstance(reason, socket.gaierror) else "tls" if isinstance(reason, ssl.SSLError) else "timeout" if isinstance(reason, (TimeoutError, socket.timeout)) else "network"
                status, message = classify_error(kind), f"Connection failed ({kind})"
            except OSError:
                status, message = "NETWORK_UNAVAILABLE", "Network connection unavailable"
            if status not in ("TIMEOUT", "API_UNAVAILABLE", "NETWORK_UNAVAILABLE") or attempt == self.retries:
                break
            time.sleep(0.2)
        return Check(identifier, status, message, round((time.monotonic() - started) * 1000, 2), {"url": url, "http_status": code, "headers": safe_headers, "attempts": attempt + 1}), data
