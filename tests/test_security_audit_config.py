"""
Tests for AgentShield configuration audit (audit-claude-config.sh).
"""

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

from conftest import FRAMEWORK_ROOT, to_posix

AUDIT_SCRIPT = FRAMEWORK_ROOT / "scripts" / "security" / "audit-claude-config.sh"
FIXTURES_DIR = Path(__file__).parent / "fixtures" / "security" / "audit"


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


def run_audit(target_dir: str, extra_args: list[str] = None) -> tuple:
    cmd = [GIT_BASH, to_posix(str(AUDIT_SCRIPT)), to_posix(target_dir)]
    if extra_args:
        cmd.extend(extra_args)
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=30,
        cwd=target_dir,
        env={**os.environ, "HOME": to_posix(target_dir)},
    )
    return result.returncode, result.stdout, result.stderr


class TestAuditDetectsDangerousSettings:
    @pytest.fixture
    def project_dir(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_settings.json"),
            str(claude_dir / "settings.json"),
        )
        return tmp_path

    def test_detects_skip_permissions(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "CRITICAL" in stdout
        assert "Skip permissions" in stdout or "dangerouslySkipPermissions" in stdout

    def test_detects_wildcard_tools(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "allowedTools" in stdout or "Wildcard" in stdout

    def test_detects_excessive_timeout(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "timeout" in stdout.lower() or "MEDIUM" in stdout


class TestAuditDetectsDangerousHooks:
    @pytest.fixture
    def project_dir(self, tmp_path):
        hooks_dir = tmp_path / ".claude" / "hooks"
        hooks_dir.mkdir(parents=True)
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_hook.sh"),
            str(hooks_dir / "dangerous_hook.sh"),
        )
        return tmp_path

    def test_detects_eval(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "CRITICAL" in stdout or "HIGH" in stdout

    def test_detects_curl_pipe_bash(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "curl" in stdout.lower() or "Remote code" in stdout

    def test_detects_base64_decode(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "base64" in stdout.lower() or "obfuscat" in stdout.lower()


class TestAuditDetectsInjection:
    @pytest.fixture
    def project_dir(self, tmp_path):
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_claude.md"),
            str(tmp_path / "CLAUDE.md"),
        )
        return tmp_path

    def test_detects_system_tags(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "CRITICAL" in stdout or "injection" in stdout.lower()

    def test_detects_ignore_instructions(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "override" in stdout.lower() or "ignore" in stdout.lower() or "HIGH" in stdout


class TestAuditDetectsMCPRisks:
    @pytest.fixture
    def project_dir(self, tmp_path):
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_mcp.json"),
            str(tmp_path / ".mcp.json"),
        )
        return tmp_path

    def test_detects_npx_auto_install(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "npx" in stdout.lower() or "supply chain" in stdout.lower() or "HIGH" in stdout

    def test_detects_hardcoded_key(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "CRITICAL" in stdout or "secret" in stdout.lower() or "API" in stdout

    def test_detects_shell_server(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "bash" in stdout.lower() or "shell" in stdout.lower() or "HIGH" in stdout


class TestAuditCleanConfigs:
    @pytest.fixture
    def project_dir(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        hooks_dir = claude_dir / "hooks"
        hooks_dir.mkdir(parents=True)
        shutil.copy2(
            str(FIXTURES_DIR / "clean_settings.json"),
            str(claude_dir / "settings.json"),
        )
        shutil.copy2(
            str(FIXTURES_DIR / "clean_hook.sh"),
            str(hooks_dir / "clean_hook.sh"),
        )
        shutil.copy2(
            str(FIXTURES_DIR / "clean_claude.md"),
            str(tmp_path / "CLAUDE.md"),
        )
        return tmp_path

    def test_clean_config_no_critical(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "CRITICAL" not in stdout
        assert "HIGH" not in stdout

    def test_clean_config_exits_zero(self, project_dir):
        rc, _, _ = run_audit(str(project_dir))
        assert rc == 0


class TestAuditOutputModes:
    @pytest.fixture
    def project_dir(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_settings.json"),
            str(claude_dir / "settings.json"),
        )
        return tmp_path

    def test_json_output(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir), ["--json"])
        data = json.loads(stdout)
        assert "total_findings" in data
        assert data["total_findings"] > 0
        assert data["status"] == "FAIL"

    def test_ci_mode_exits_nonzero(self, project_dir):
        rc, _, _ = run_audit(str(project_dir), ["--ci"])
        assert rc == 1

    def test_ci_mode_clean_exits_zero(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        shutil.copy2(
            str(FIXTURES_DIR / "clean_settings.json"),
            str(claude_dir / "settings.json"),
        )
        rc, _, _ = run_audit(str(tmp_path), ["--ci"])
        assert rc == 0


class TestAuditSummary:
    @pytest.fixture
    def project_dir(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        shutil.copy2(
            str(FIXTURES_DIR / "dangerous_settings.json"),
            str(claude_dir / "settings.json"),
        )
        return tmp_path

    def test_summary_shows_counts(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        assert "Summary" in stdout
        assert "Total findings:" in stdout

    def test_summary_shows_severity_breakdown(self, project_dir):
        rc, stdout, _ = run_audit(str(project_dir))
        # Should have at least one severity level
        has_severity = any(
            sev in stdout for sev in ["CRITICAL:", "HIGH:", "MEDIUM:", "LOW:"]
        )
        assert has_severity
