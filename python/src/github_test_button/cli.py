import argparse
import json
from pathlib import Path
import sys
from . import __version__
from .authentication import auth_status
from .diagnostics import diagnose
from .git_tools import tool_check
from .models import report
from .repository import inspect_repository, WriteTest
from .reporting import render, exit_code
from .utilities import repo_name, redact


class Parser(argparse.ArgumentParser):
    def error(self, message):
        self.print_usage(sys.stderr)
        self.exit(4, "gtb: " + message + "\n")


def parser():
    p = Parser(description="GITHUB TEST BUTTON — public diagnostics are read-only; writes require explicit scope and confirmation.")
    sub = p.add_subparsers(dest="command")
    for name in ("status", "test", "report", "doctor"):
        item = sub.add_parser(name)
        item.add_argument("--json", action="store_true")
        item.add_argument("--timeout", type=float, default=8)
        item.add_argument("--output", type=Path, help="Save JSON with --json, otherwise TXT")
        if name == "test":
            item.add_argument("--all", action="store_true", help="Complete read-only suite (already the default); never enables writes")
    auth = sub.add_parser("auth").add_subparsers(dest="action", required=True).add_parser("status")
    auth.add_argument("--json", action="store_true")
    repo = sub.add_parser("repo").add_subparsers(dest="action", required=True)
    for name in ("check", "capabilities"):
        item = repo.add_parser(name)
        item.add_argument("repository")
        item.add_argument("--json", action="store_true")
    write = sub.add_parser("write-test", description="Creates a unique branch containing only GTB-VERIFY.txt, or a new private repository. Never deletes remote data. Your default branch is unchanged.")
    group = write.add_mutually_exclusive_group(required=True)
    group.add_argument("--repo", help="Explicit owned test repository OWNER/REPO")
    group.add_argument("--new", action="store_true", help="Create a uniquely named private test repository under your own account")
    group.add_argument("--resume", help="Previously created GTB write-test local directory")
    write.add_argument("--confirm", action="store_true", help="Authorize the described remote creation/push")
    write.add_argument("--json", action="store_true")
    sub.add_parser("version")
    sub.add_parser("help")
    return p


def main(argv=None):
    p = parser()
    args = p.parse_args(argv)
    if args.command in (None, "help"):
        p.print_help()
        return 0
    if args.command == "version":
        print(__version__)
        return 0
    try:
        if hasattr(args, "timeout") and not 0.1 <= args.timeout <= 60:
            raise ValueError("Timeout must be between 0.1 and 60 seconds")
        if args.command in ("test", "status", "report"):
            value = diagnose(timeout=args.timeout)
        elif args.command == "doctor":
            value = report([tool_check(name) for name in ("git", "gh", "codex", "pwsh")])
        elif args.command == "auth":
            check, account = auth_status()
            value = report([check], account=account)
        elif args.command == "repo":
            value = inspect_repository(repo_name(args.repository))
        else:
            value = WriteTest(args.repo, args.new, args.confirm, args.resume).execute()
        output = render(value, args.json)
        if getattr(args, "output", None):
            args.output.write_text(output + "\n", encoding="utf-8")
        try:
            print(output)
        except UnicodeEncodeError:
            print(output.encode(sys.stdout.encoding or "ascii", errors="replace").decode(sys.stdout.encoding or "ascii"))
        if args.command == "write-test":
            return 0 if value["status"] == "CONNECTED" else 2 if value["status"] in ("UNAUTHENTICATED", "AUTHENTICATION_EXPIRED") else 3 if value["status"] == "ACCESS_DENIED" else 5
        return exit_code(value, args.command == "auth", args.command == "repo")
    except ValueError as exc:
        print("gtb: " + redact(str(exc)), file=sys.stderr)
        return 4
    except KeyboardInterrupt:
        print("gtb: cancelled", file=sys.stderr)
        return 5
    except Exception:
        print("gtb: unexpected internal error; no credentials were included in this message", file=sys.stderr)
        return 6


if __name__ == "__main__":
    raise SystemExit(main())
