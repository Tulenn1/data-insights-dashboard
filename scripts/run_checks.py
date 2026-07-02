"""
Runs ruff linter + formatter check, then pytest.
Usage: python scripts/run_checks.py
"""

import subprocess
import sys
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent

checks = [
    ("Ruff check", ["ruff", "check", "."]),
    ("Ruff format", ["ruff", "format", "--check", "."]),
    ("Pytest", ["pytest", "tests/", "-v", "--tb=short"]),
]

all_ok = True
for name, cmd in checks:
    print(f"\n─── {name} ───")
    result = subprocess.run(cmd, cwd=PROJECT, capture_output=True, text=True)
    if result.returncode == 0:
        print("✅ Passed")
    else:
        print("❌ Failed")
        print(result.stdout or result.stderr)
        all_ok = False

sys.exit(0 if all_ok else 1)
