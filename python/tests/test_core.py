import base64
import contextlib
import io
import json
import os
from pathlib import Path
import socket
import ssl
import subprocess
import tempfile
import threading
import unittest
import urllib.error
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch, Mock
from github_test_button.authentication import auth_status, credential
from github_test_button.cli import main
from github_test_button.diagnostics import dns_check, network_check
from github_test_button.github_api import Client
from github_test_button.git_tools import tool_check
from github_test_button.models import Check, classify_error, classify_http, report
from github_test_button.reporting import exit_code, render
from github_test_button.repository import inspect_repository, WriteTest, STATES
from github_test_button.utilities import redact, repo_name

CONTRACTS = Path(__file__).parents[2] / "contracts"
if not CONTRACTS.is_dir():
    CONTRACTS = Path(__file__).parent / "contracts"


class Handler(BaseHTTPRequestHandler):
    calls = []
    def log_message(self, *_):
        pass
    def do_GET(self):
        Handler.calls.append((self.path, dict(self.headers)))
        code = int(self.path.strip("/")) if self.path.strip("/").isdigit() else 200
        self.send_response(code)
        if self.path == "/403":
            self.send_header("X-RateLimit-Remaining", "0")
        self.end_headers()
        self.wfile.write(b"broken" if self.path == "/malformed" else b'{"login":"fixture"}')


class TransportTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        threading.Thread(target=cls.server.serve_forever, daemon=True).start()
        cls.base = "http://127.0.0.1:" + str(cls.server.server_port)
    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
    def setUp(self):
        Handler.calls.clear()
        self.client = Client(timeout=.2, retries=0, base=self.base)
    def test_http_success(self):
        check, data = self.client.request("/200")
        self.assertEqual(check.status, "CONNECTED")
        self.assertEqual(data["login"], "fixture")
    def test_malformed_json(self):
        self.assertEqual(self.client.request("/malformed")[0].status, "API_UNAVAILABLE")
    def test_rate_limit(self):
        self.assertEqual(self.client.request("/403")[0].status, "RATE_LIMITED")
    def test_rate_limit_no_retry(self):
        self.client.retries = 1
        self.client.request("/429")
        self.assertEqual(len(Handler.calls), 1)
    def test_auth_rejection_no_retry(self):
        self.client.retries = 1
        self.assertEqual(self.client.request("/401")[0].status, "AUTHENTICATION_EXPIRED")
        self.assertEqual(len(Handler.calls), 1)
    def test_server_failure_bounded_retry(self):
        self.client.retries = 1
        self.assertEqual(self.client.request("/503")[0].status, "API_UNAVAILABLE")
        self.assertEqual(len(Handler.calls), 2)
    def test_token_never_sent_to_other_host(self):
        self.client.token = "fixture-secret"
        self.client.request("/200")
        self.assertNotIn("Authorization", Handler.calls[-1][1])
    def test_token_never_sent_over_plain_http(self):
        self.client.token = "fixture-secret"
        with patch.object(self.client.opener, "open", side_effect=socket.timeout()) as opener:
            self.client.request("http://api.github.com/user")
            self.assertIsNone(opener.call_args.args[0].get_header("Authorization"))
    def test_html_probe_accept_header(self):
        self.client.request("/200", expect_json=False)
        self.assertIn("text/html", Handler.calls[-1][1]["Accept"])
        self.assertNotIn("github+json", Handler.calls[-1][1]["Accept"])
    def test_secondary_rate_limit_body(self):
        error = urllib.error.HTTPError("https://api.github.com", 403, "Forbidden", {}, io.BytesIO(b'{"message":"You have exceeded a secondary rate limit"}'))
        with patch.object(self.client.opener, "open", side_effect=error):
            self.assertEqual(self.client.request("/403")[0].status, "RATE_LIMITED")
    def test_timeout(self):
        with patch.object(self.client.opener, "open", side_effect=socket.timeout()):
            self.assertEqual(self.client.request("/200")[0].status, "TIMEOUT")
    def test_tls_failure(self):
        with patch.object(self.client.opener, "open", side_effect=urllib.error.URLError(ssl.SSLError())):
            self.assertEqual(self.client.request("/200")[0].status, "TLS_FAILURE")
    def test_dns_failure(self):
        with patch.object(self.client.opener, "open", side_effect=urllib.error.URLError(socket.gaierror())):
            self.assertEqual(self.client.request("/200")[0].status, "DNS_FAILURE")
    def test_network_failure(self):
        with patch.object(self.client.opener, "open", side_effect=ConnectionRefusedError()):
            self.assertEqual(self.client.request("/200")[0].status, "NETWORK_UNAVAILABLE")


class ContractTests(unittest.TestCase):
    def test_shared_http_vectors(self):
        vectors = json.loads((CONTRACTS / "test-vectors.json").read_text())
        for row in vectors["http"]:
            with self.subTest(row=row):
                self.assertEqual(classify_http(row["code"], row["headers"]), row["expected"])
    def test_shared_error_vectors(self):
        vectors = json.loads((CONTRACTS / "test-vectors.json").read_text())
        for row in vectors["errors"]:
            self.assertEqual(classify_error(row["kind"]), row["expected"])
    def test_report_structure(self):
        result = report([Check("fixture", "CONNECTED", "ok")])
        schema = json.loads((CONTRACTS / "diagnostic-v1.schema.json").read_text())
        self.assertTrue(set(schema["required"]).issubset(result))
        self.assertEqual(result["repository_write"]["status"], "NOT_TESTED")
    def test_sdist_contract_fixtures_match(self):
        for name in ("test-vectors.json", "diagnostic-v1.schema.json", "status-codes.json"):
            self.assertEqual(json.loads((CONTRACTS / name).read_text()), json.loads((Path(__file__).parent / "contracts" / name).read_text()))
    def test_redaction(self):
        data = {"Authorization": "Bearer secret", "nested": ["https://me:password@github.com/repo", "ghp_12345678901234567890", "https://site?access_token=abc&x=1"], "password": "x"}
        result = json.dumps(redact(data))
        for secret in ("Bearer secret", "me:password", "ghp_12345678901234567890", "=abc"):
            self.assertNotIn(secret, result)
    def test_env_redaction(self):
        with patch.dict(os.environ, {"GH_TOKEN": "custom-sensitive-value"}):
            self.assertNotIn("custom-sensitive-value", redact("failure custom-sensitive-value"))
    def test_remote_userinfo_redaction(self):
        self.assertEqual(redact("https://secret@github.com/repo"), "https://[REDACTED]@github.com/repo")
        self.assertEqual(redact("ssh://user:secret@github.com/repo"), "ssh://[REDACTED]@github.com/repo")
    def test_repo_argument_injection(self):
        for value in ("-x/y", "a/b;rm", "a/b/c", "a/..", "https://github.com/a/b"):
            with self.assertRaises(ValueError):
                repo_name(value)
    def test_dns_success(self):
        with patch("socket.getaddrinfo", return_value=[(2, 1, 6, "", ("1.2.3.4", 443))]):
            self.assertEqual(dns_check("fixture").details["addresses"], ["1.2.3.4"])
    def test_dns_unavailable(self):
        with patch("socket.getaddrinfo", side_effect=socket.gaierror()):
            self.assertEqual(dns_check("fixture").status, "DNS_FAILURE")
    def test_independent_network_probe_not_definitive(self):
        with patch("socket.create_connection", side_effect=OSError()):
            self.assertEqual(network_check().status, "CONNECTED_WITH_LIMITATIONS")


class AuthAndRepositoryTests(unittest.TestCase):
    def test_unauthenticated(self):
        self.assertEqual(auth_status(Client())[0].status, "UNAUTHENTICATED")
    def test_auth_success(self):
        client = Mock(token="fixture")
        client.request.return_value = (Check("authentication", "CONNECTED", "ok"), {"login": "person", "html_url": "https://github.com/person"})
        self.assertEqual(auth_status(client)[1]["login"], "person")
    def test_auth_invalid_identity(self):
        client = Mock(token="fixture")
        client.request.return_value = (Check("authentication", "CONNECTED", "ok"), {})
        self.assertEqual(auth_status(client)[0].status, "API_UNAVAILABLE")
    def test_auth_scalar_json(self):
        client = Mock(token="fixture")
        client.request.return_value = (Check("authentication", "CONNECTED", "ok"), 42)
        self.assertEqual(auth_status(client)[0].status, "API_UNAVAILABLE")
    def test_auth_expired(self):
        client = Mock(token="fixture")
        client.request.return_value = (Check("authentication", "AUTHENTICATION_EXPIRED", "HTTP 401"), None)
        self.assertIsNone(auth_status(client)[1])
    def test_missing_gh(self):
        with patch.dict(os.environ, {}, clear=True), patch("shutil.which", return_value=None):
            self.assertEqual(credential(), (None, "none"))
    def test_missing_tool(self):
        with patch("shutil.which", return_value=None):
            self.assertEqual(tool_check("git").status, "TOOL_NOT_INSTALLED")
    def test_tool_present_but_not_functional(self):
        with patch("shutil.which", return_value="fixture"), patch("github_test_button.git_tools.run", side_effect=OSError()):
            self.assertFalse(tool_check("git").details["verified"])
    def test_repo_missing_or_private(self):
        client = Mock()
        client.request.return_value = (Check("repository", "ACCESS_DENIED", "Resource absent or inaccessible"), None)
        self.assertEqual(len(inspect_repository("person/private", client)["checks"]), 1)
    def test_repo_read_does_not_verify_write(self):
        client = Mock()
        client.request.side_effect = [(Check("repository", "CONNECTED", "ok"), {"full_name": "person/repo", "permissions": {"push": True}})] + [(Check("repository.fixture", "CONNECTED", "ok"), [])] * 3
        result = inspect_repository("person/repo", client)
        self.assertEqual(result["checks"][0]["details"]["write_verification"], "NOT_TESTED")


class CliTests(unittest.TestCase):
    def capture(self, args):
        output = io.StringIO()
        with contextlib.redirect_stdout(output), contextlib.redirect_stderr(output):
            code = main(args)
        return code, output.getvalue()
    def test_help(self):
        self.assertIn("write-test", self.capture(["help"])[1])
    def test_version(self):
        self.assertEqual(self.capture(["version"]), (0, "0.1.0b1\n"))
    def test_invalid_args_exit4(self):
        with contextlib.redirect_stderr(io.StringIO()), self.assertRaises(SystemExit) as ctx:
            main(["invalid"])
        self.assertEqual(ctx.exception.code, 4)
    def test_invalid_timeout(self):
        self.assertEqual(self.capture(["test", "--timeout", "0"])[0], 4)
    def test_json(self):
        with patch("github_test_button.cli.diagnose", return_value=report([Check("github.api", "CONNECTED", "ok")])):
            code, output = self.capture(["test", "--json"])
            self.assertEqual(code, 0)
            self.assertEqual(json.loads(output)["schema_version"], "1.0")
    def test_json_export(self):
        with tempfile.TemporaryDirectory() as directory, patch("github_test_button.cli.diagnose", return_value=report([])):
            target = Path(directory) / "report.json"
            self.assertEqual(self.capture(["report", "--json", "--output", str(target)])[0], 0)
            self.assertEqual(json.loads(target.read_text())["application"], "GITHUB TEST BUTTON")
    def test_unicode(self):
        self.assertIn("Română", render(report([Check("x", "CONNECTED", "Română — Prüfung")])) )
    def test_auth_exit2(self):
        self.assertEqual(exit_code(report([Check("authentication", "UNAUTHENTICATED", "x")]), auth_required=True), 2)
    def test_explicit_auth_failure_exit_codes(self):
        for status, expected in (("TIMEOUT", 1), ("API_UNAVAILABLE", 1), ("ACCESS_DENIED", 3), ("RATE_LIMITED", 5), ("UNKNOWN_ERROR", 5)):
            self.assertEqual(exit_code(report([Check("authentication", status, "x")]), auth_required=True), expected)
    def test_optional_auth_does_not_fail(self):
        self.assertEqual(exit_code(report([Check("authentication", "UNAUTHENTICATED", "x"), Check("tool.git", "TOOL_NOT_INSTALLED", "x")])), 0)
    def test_network_exit1(self):
        self.assertEqual(exit_code(report([Check("github.api", "TIMEOUT", "x")])), 1)
    def test_permission_exit3(self):
        self.assertEqual(exit_code(report([Check("repository", "ACCESS_DENIED", "x")]), repo_required=True), 3)
    def test_limited_exit5(self):
        self.assertEqual(exit_code(report([Check("github.api", "RATE_LIMITED", "x")])), 5)


class WriteTests(unittest.TestCase):
    def test_confirmation_required(self):
        with self.assertRaises(ValueError):
            WriteTest("person/repo").execute()
    def test_state_order(self):
        with self.assertRaises(RuntimeError):
            WriteTest("person/repo").advance("PUSH_COMPLETED")
    def test_missing_git(self):
        with patch("shutil.which", return_value=None):
            self.assertEqual(WriteTest("person/repo", confirm=True).execute()["status"], "TOOL_NOT_INSTALLED")
    def run_fixture(self, fail=None, mismatch=False, new=False):
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        working = Path(temporary.name) / "work"
        working.mkdir()
        test = WriteTest(None if new else "person/repo", new=new, confirm=True)
        calls = []
        def command(args):
            calls.append(args)
            if fail and fail in args:
                raise RuntimeError("fixture " + fail + " failure")
            if args[-2:] == ["rev-parse", "HEAD"]:
                return "a" * 40
            if args[-3:] == ["remote", "get-url", "origin"]:
                return test.result["url"] + ".git"
            if args[-4:] == ["remote", "get-url", "--push", "origin"]:
                return test.result["url"] + ".git"
            if args[-2:] == ["branch", "--show-current"]:
                return test.result["branch"]
            if args[-3:] == ["ls-tree", "--name-only", "HEAD"]:
                return "GTB-VERIFY.txt"
            if args[-2:] == ["show", "HEAD:GTB-VERIFY.txt"]:
                return test.result["marker"].strip()
            return ""
        test.command = command
        client = Mock()
        def request(path, identifier):
            if "/contents/" in path:
                return Check(identifier, "CONNECTED", "ok"), {"content": base64.b64encode(("mismatch" if mismatch else test.result["marker"]).encode()).decode()}
            if "/commits/" in path:
                return Check(identifier, "CONNECTED", "ok"), {"sha": "a" * 40}
            return Check(identifier, "CONNECTED", "ok"), {"permissions": {"push": True}}
        client.request.side_effect = request
        with patch("shutil.which", return_value="fixture"), patch("github_test_button.repository.credential", return_value=("fixture", "test")), patch("github_test_button.repository.Client", return_value=client), patch("github_test_button.repository.auth_status", return_value=(Check("authentication", "CONNECTED", "ok"), {"login": "person"})), patch("tempfile.mkdtemp", return_value=str(working)):
            result = test.execute()
        return result, calls
    def test_write_success_readback(self):
        result, calls = self.run_fixture()
        self.assertEqual(result["transitions"], STATES)
        self.assertEqual(result["status"], "CONNECTED")
        self.assertFalse(any("--force" in args for args in calls))
    def test_commit_failure_preserves_state(self):
        result, _ = self.run_fixture(fail="commit")
        self.assertEqual(result["state"], "FILES_STAGED")
    def test_push_failure_preserves_commit(self):
        result, _ = self.run_fixture(fail="push")
        self.assertEqual(result["state"], "REMOTE_READY")
        self.assertEqual(result["commit"], "a" * 40)
    def test_readback_mismatch_not_success(self):
        result, _ = self.run_fixture(mismatch=True)
        self.assertEqual(result["state"], "PUSH_COMPLETED")
        self.assertEqual(result["status"], "UNKNOWN_ERROR")
    def test_new_repo_private_and_commit_first(self):
        result, calls = self.run_fixture(new=True)
        create = next(i for i, c in enumerate(calls) if "create" in c)
        commit = next(i for i, c in enumerate(calls) if "commit" in c)
        self.assertGreater(create, commit)
        self.assertIn("--private", calls[create])
        self.assertEqual(result["status"], "CONNECTED")
    def test_local_actual_git_commit(self):
        import shutil
        if not shutil.which("git"):
            self.skipTest("Git unavailable")
        with tempfile.TemporaryDirectory() as directory:
            subprocess.run(["git", "init", "-b", "gtb-fixture", directory], check=True, capture_output=True)
            Path(directory, "marker.txt").write_text("fixture", encoding="utf-8")
            subprocess.run(["git", "-C", directory, "add", "marker.txt"], check=True, capture_output=True)
            subprocess.run(["git", "-C", directory, "-c", "user.name=GTB Test", "-c", "user.email=gtb@localhost", "commit", "-m", "fixture"], check=True, capture_output=True)
            self.assertEqual(len(subprocess.check_output(["git", "-C", directory, "rev-parse", "HEAD"]).strip()), 40)
    def test_tampered_origin_rejected(self):
        test = WriteTest("person/repo", confirm=True)
        test.result["url"] = "https://github.com/person/repo"
        test.command = Mock(return_value="https://github.com/attacker/repo.git")
        with self.assertRaisesRegex(RuntimeError, "Origin"):
            test.verify_push_scope("git")
    def test_tampered_resume_branch_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            state = {"schema_version": "1.0", "state": "REMOTE_READY", "target": "person/repo", "branch": "--all", "local_directory": directory}
            Path(directory, "gtb-state.json").write_text(json.dumps(state))
            with self.assertRaisesRegex(ValueError, "branch"):
                WriteTest(confirm=True, resume=directory)
    def test_tampered_pushurl_rejected(self):
        test = WriteTest("person/repo", confirm=True)
        test.result["url"] = "https://github.com/person/repo"
        test.command = Mock(side_effect=[test.result["url"] + ".git", "https://github.com/attacker/repo.git"])
        with self.assertRaisesRegex(RuntimeError, "Push URL"):
            test.verify_push_scope("git")
    def test_completed_resume_rechecks_remote(self):
        result, _ = self.run_fixture()
        test = WriteTest(confirm=True, resume=result["local_directory"])
        client = Mock()
        client.request.side_effect = [(Check("repository", "CONNECTED", "ok"), {"permissions": {"push": True}}), (Check("repository_write", "ACCESS_DENIED", "missing"), None)]
        with patch("shutil.which", return_value="fixture"), patch("github_test_button.repository.credential", return_value=("fixture", "test")), patch("github_test_button.repository.Client", return_value=client), patch("github_test_button.repository.auth_status", return_value=(Check("authentication", "CONNECTED", "ok"), {"login": "person"})):
            self.assertEqual(test.execute()["status"], "UNKNOWN_ERROR")
        self.assertEqual(client.request.call_count, 2)


if __name__ == "__main__":
    unittest.main()
