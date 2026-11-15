import shutil
import subprocess
import time
from .models import Check
from .utilities import run, redact


def tool_check(name):
    path = shutil.which(name)
    if not path:
        return Check("tool." + name, "TOOL_NOT_INSTALLED", f"{name} is optional for public diagnostics", details={"detected": False, "verified": False})
    started = time.monotonic()
    try:
        result = run([path, "--version"], timeout=10)
        status = "CONNECTED" if result.returncode == 0 else "CONNECTED_WITH_LIMITATIONS"
        version = (result.stdout or result.stderr).strip().splitlines()
        return Check("tool." + name, status, version[0] if version else "Executable returned no version", (time.monotonic() - started) * 1000, {"path": path, "detected": True, "verified": result.returncode == 0})
    except subprocess.TimeoutExpired:
        return Check("tool." + name, "TIMEOUT", "Version command timed out", details={"path": path, "detected": True, "verified": False})
    except OSError:
        return Check("tool." + name, "CONNECTED_WITH_LIMITATIONS", "Executable found but could not run", details={"path": path, "detected": True, "verified": False})
