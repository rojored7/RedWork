"""
Tests for security-related additions to pre-write-validate.sh and pre-bash-validate.sh.

Validates that the hooks block secrets in file content and commands.
"""

import json
import os
import subprocess
from pathlib import Path

import pytest

from conftest import FRAMEWORK_ROOT, to_posix

PRE_WRITE_HOOK = FRAMEWORK_ROOT / ".claude" / "hooks" / "pre-write-validate.sh"
PRE_BASH_HOOK = FRAMEWORK_ROOT / ".claude" / "hooks" / "pre-bash-validate.sh"


def _find_git_bash() -> str:
    candidates = [
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files\Git\bin\bash.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return "bash"


GIT_BASH = _find_git_bash()


def run_hook(hook_path: Path, input_data: dict, cwd: str = None) -> tuple:
    """Run a hook script with JSON input on stdin using Git Bash."""
    result = subprocess.run(
        [GIT_BASH, to_posix(str(hook_path))],
        input=json.dumps(input_data),
        capture_output=True,
        text=True,
        cwd=str(cwd) if cwd else str(FRAMEWORK_ROOT),
        timeout=10,
    )
    return result.returncode, result.stdout, result.stderr


def python3_available() -> bool:
    """Check if python3 is usable from Git Bash (hooks depend on it)."""
    try:
        r = subprocess.run(
            [GIT_BASH, "-c", "python3 -c 'print(1)'"],
            capture_output=True, text=True, timeout=5,
        )
        return r.returncode == 0 and "1" in r.stdout
    except Exception:
        return False


SKIP_NO_PYTHON3 = pytest.mark.skipif(
    not python3_available(),
    reason="python3 not available in Git Bash"
)


# ============================================================================
# PRE-WRITE: SECRET DETECTION
# ============================================================================

@SKIP_NO_PYTHON3
class TestPreWriteBlocksSecrets:

    def _make_write_input(self, file_path, content):
        return {"tool_input": {"file_path": file_path, "content": content}}

    def test_blocks_aws_key_in_content(self):
        inp = self._make_write_input("app/config.py", 'key = "AKIAIOSFODNN7EXAMPLE"')
        code, _, stderr = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 2
        assert "AWS Access Key" in stderr

    def test_blocks_private_key_in_content(self):
        inp = self._make_write_input("app/keys.py", "-----BEGIN RSA PRIVATE KEY-----")
        code, _, stderr = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 2
        assert "Private key" in stderr

    def test_blocks_stripe_key_in_content(self):
        inp = self._make_write_input("app/pay.py", 'k = "sk_live_abcdefghijklmnopqrstuvwx"')
        code, _, stderr = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 2
        assert "Stripe" in stderr

    def test_blocks_github_token_in_content(self):
        inp = self._make_write_input("app/gh.py", 't = "ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijk"')
        code, _, stderr = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 2
        assert "GitHub" in stderr

    def test_blocks_gitlab_token_in_content(self):
        inp = self._make_write_input("app/gl.py", 't = "glpat-xxxxxxxxxxxxxxxxxxyyyy"')
        code, _, stderr = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 2
        assert "GitLab" in stderr

    def test_allows_clean_content(self):
        inp = self._make_write_input("app/clean.py", 'import os\nkey = os.environ["KEY"]')
        code, _, _ = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 0

    def test_skips_test_security_files(self):
        inp = self._make_write_input(
            "tests/test_security_scan.py",
            'k = "AKIAIOSFODNN7EXAMPLE"'
        )
        code, _, _ = run_hook(PRE_WRITE_HOOK, inp)
        assert code == 0, "Security test files should be exempt from secret scanning"


# ============================================================================
# PRE-BASH: SECRET DETECTION
# ============================================================================

@SKIP_NO_PYTHON3
class TestPreBashBlocksSecrets:

    def _make_bash_input(self, command):
        return {"tool_input": {"command": command}}

    def test_blocks_aws_key_in_command(self):
        inp = self._make_bash_input('export AWS_KEY=AKIAIOSFODNN7EXAMPLE')
        code, _, stderr = run_hook(PRE_BASH_HOOK, inp)
        assert code == 2
        assert "AWS" in stderr

    def test_blocks_stripe_key_in_command(self):
        inp = self._make_bash_input('curl -H "Authorization: Bearer sk_live_abcdefghijklmnopqrstuvwx"')
        code, _, stderr = run_hook(PRE_BASH_HOOK, inp)
        assert code == 2
        assert "Stripe" in stderr

    def test_allows_clean_command(self):
        inp = self._make_bash_input('python -m pytest tests/ -v')
        code, _, _ = run_hook(PRE_BASH_HOOK, inp)
        assert code == 0

    def test_allows_env_var_reference(self):
        inp = self._make_bash_input('export AWS_KEY=$AWS_ACCESS_KEY_ID')
        code, _, _ = run_hook(PRE_BASH_HOOK, inp)
        assert code == 0


# ============================================================================
# PRE-COMMIT SECURITY HOOK EXISTS
# ============================================================================

class TestPreCommitSecurityHook:

    def test_pre_commit_security_script_exists(self):
        hook = FRAMEWORK_ROOT / "scripts" / "security" / "pre-commit-security.sh"
        assert hook.exists()

    def test_pre_commit_references_scan_secrets(self):
        hook = FRAMEWORK_ROOT / "scripts" / "security" / "pre-commit-security.sh"
        content = hook.read_text(encoding="utf-8")
        assert "scan-secrets.sh" in content

    def test_install_workflow_hooks_includes_security(self):
        hook_installer = FRAMEWORK_ROOT / "scripts" / "install-workflow-hooks.sh"
        content = hook_installer.read_text(encoding="utf-8")
        assert "scan-secrets.sh" in content or "security" in content
