"""
Tests for the secret scanner (scripts/security/scan-secrets.sh).

All scanner tests use run_scanner_with_files() which creates files directly
in WSL /tmp (since WSL bash cannot access Windows temp paths).
"""

import base64
import os
import subprocess
from pathlib import Path

import pytest

from conftest import FRAMEWORK_ROOT, to_posix

SCANNER = FRAMEWORK_ROOT / "scripts" / "security" / "scan-secrets.sh"
PATTERNS_FILE = FRAMEWORK_ROOT / "scripts" / "security" / "secret-patterns.txt"


def _find_git_bash() -> str:
    """Find Git Bash executable (not WSL bash)."""
    candidates = [
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files\Git\bin\bash.exe",
        r"C:\Program Files (x86)\Git\usr\bin\bash.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    # Fallback to PATH bash
    return "bash"


GIT_BASH = _find_git_bash()


def _scan(files: dict, patterns_file: str = None) -> tuple:
    """Create temp files and run scan-secrets.sh using Git Bash."""
    import tempfile

    # Create a real Windows temp dir and populate it
    tmp_dir = Path(tempfile.mkdtemp(prefix="rw_scan_"))
    try:
        for name, content in files.items():
            (tmp_dir / name).write_text(content, encoding="utf-8")

        env = os.environ.copy()
        if patterns_file:
            env["PATTERNS_FILE"] = patterns_file

        scanner_path = to_posix(str(SCANNER))
        target_path = to_posix(str(tmp_dir))

        result = subprocess.run(
            [GIT_BASH, scanner_path, target_path],
            capture_output=True, text=True, env=env, timeout=120,
        )
        return result.returncode, result.stdout, result.stderr
    finally:
        import shutil
        shutil.rmtree(str(tmp_dir), ignore_errors=True)


# ============================================================================
# PATTERNS FILE (static checks - no bash needed)
# ============================================================================

class TestPatternsFile:

    def test_patterns_file_exists(self):
        assert PATTERNS_FILE.exists()

    def test_patterns_file_has_minimum_50_patterns(self):
        lines = [l for l in PATTERNS_FILE.read_text(encoding="utf-8").splitlines()
                 if l.strip() and not l.strip().startswith("#")]
        assert len(lines) >= 50, f"Expected 50+, found {len(lines)}"

    def test_patterns_file_has_categories(self):
        content = PATTERNS_FILE.read_text(encoding="utf-8")
        for cat in ["AWS", "Private Keys", "Passwords", "Database URLs", "Tokens"]:
            assert cat in content

    def test_patterns_have_pipe_delimited_format(self):
        lines = [l for l in PATTERNS_FILE.read_text(encoding="utf-8").splitlines()
                 if l.strip() and not l.strip().startswith("#")]
        for line in lines:
            parts = line.split("|", 2)
            assert len(parts) == 3 and parts[0].strip() and parts[1].strip()


# ============================================================================
# DETECTION TESTS
# ============================================================================

class TestDetection:

    def test_detects_aws_access_key(self):
        code, out, _ = _scan({"bad.py": 'k = "AKIAIOSFODNN7EXAMPLE"\n'})
        assert code == 1
        assert "SECRET DETECTED" in out

    def test_detects_private_key_header(self):
        code, _, _ = _scan({"bad.py": "-----BEGIN RSA PRIVATE KEY-----\ndata\n"})
        assert code == 1

    def test_detects_generic_password(self):
        code, _, _ = _scan({"c.py": 'password = "super_secret_pwd_123"\n'})
        assert code == 1

    def test_detects_database_url(self):
        code, _, _ = _scan({"c.py": 'u = "postgres://admin:secret@db:5432/x"\n'})
        assert code == 1

    def test_detects_github_token(self):
        code, _, _ = _scan({"c.py": 't = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijk"\n'})
        assert code == 1

    def test_detects_stripe_live_key(self):
        code, _, _ = _scan({"c.py": 'k = "sk_live_abcdefghijklmnopqrstuvwx"\n'})
        assert code == 1

    def test_detects_jwt_token(self):
        code, _, _ = _scan({"c.py": 't = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U"\n'})
        assert code == 1

    def test_detects_slack_webhook(self):
        code, _, _ = _scan({"c.py": 'u = "https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX"\n'})
        assert code == 1

    def test_detects_openai_key(self):
        code, _, _ = _scan({"c.py": 'k = "sk-abcdefghijklmnopqrstuvwxyz123456"\n'})
        assert code == 1

    def test_detects_gcp_api_key(self):
        code, _, _ = _scan({"c.py": 'k = "AIzaSyB_abcdefghijklmnopqrstuvwxyz12345"\n'})
        assert code == 1

    def test_detects_gitlab_token(self):
        code, _, _ = _scan({"c.py": 't = "glpat-xxxxxxxxxxxxxxxxxxxx"\n'})
        assert code == 1

    def test_detects_sendgrid_key(self):
        code, _, _ = _scan({"c.py": 'k = "SG.abcdefghijklmnopqrstuv.abcdefghijklmnopqrstuvwxyz0123456789abcdefghijk"\n'})
        assert code == 1


# ============================================================================
# CLEAN FILES PASS
# ============================================================================

class TestClean:

    def test_clean_file_passes(self):
        code, out, _ = _scan({"clean.py": 'import os\nDB = os.environ["DB"]\n'})
        assert code == 0, f"Clean file should pass. Output: {out}"
        assert "SCAN PASSED" in out

    def test_empty_directory_passes(self):
        code, _, _ = _scan({})
        assert code == 0

    def test_env_var_reference_not_flagged(self):
        code, _, _ = _scan({"c.py": 'import os\nk = os.environ.get("API_KEY")\n'})
        assert code == 0

    def test_comments_not_flagged(self):
        code, _, _ = _scan({"c.py": "# Configure your API key via env\n"})
        assert code == 0


# ============================================================================
# EXIT CODES
# ============================================================================

class TestExitCodes:

    def test_exit_0_on_clean(self):
        code, _, _ = _scan({"ok.py": "x = 1\n"})
        assert code == 0

    def test_exit_1_on_secret(self):
        code, _, _ = _scan({"bad.py": 'k = "AKIAIOSFODNN7EXAMPLE"\n'})
        assert code == 1

    def test_exit_2_on_missing_directory(self):
        scanner_path = to_posix(str(SCANNER))
        r = subprocess.run(
            [GIT_BASH, scanner_path, "/tmp/nonexistent_abc_xyz_999"],
            capture_output=True, text=True, timeout=30,
        )
        assert r.returncode == 2

    def test_exit_2_on_missing_patterns(self):
        code, _, _ = _scan({"t.py": "x = 1\n"}, patterns_file="/tmp/no_such_patterns.txt")
        assert code == 2


# ============================================================================
# OUTPUT FORMAT
# ============================================================================

class TestOutput:

    def test_output_contains_category(self):
        _, out, _ = _scan({"bad.py": 'k = "AKIAIOSFODNN7EXAMPLE"\n'})
        assert "AWS_ACCESS_KEY" in out

    def test_output_contains_summary(self):
        _, out, _ = _scan({"ok.py": "x = 1\n"})
        assert "---" in out

    def test_output_shows_finding_count(self):
        _, out, _ = _scan({"bad.py": 'k = "AKIAIOSFODNN7EXAMPLE"\n'})
        assert "potential secret(s) found" in out
