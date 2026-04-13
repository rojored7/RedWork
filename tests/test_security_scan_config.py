"""
Tests for the configuration security scanner (scripts/security/scan-config.sh).

Validates settings.json and hook scripts for injection risks.
"""

import json
import os
import subprocess
from pathlib import Path

import pytest

from conftest import FRAMEWORK_ROOT, to_posix

CONFIG_SCANNER = FRAMEWORK_ROOT / "scripts" / "security" / "scan-config.sh"


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


def run_config_scanner(target_dir: str) -> tuple:
    result = subprocess.run(
        [GIT_BASH, to_posix(str(CONFIG_SCANNER)), to_posix(target_dir)],
        capture_output=True,
        text=True,
        timeout=30,
    )
    return result.returncode, result.stdout, result.stderr


class TestConfigScannerExists:

    def test_scanner_exists(self):
        assert CONFIG_SCANNER.exists()

    def test_scanner_is_executable_content(self):
        content = CONFIG_SCANNER.read_text(encoding="utf-8")
        assert content.startswith("#!/bin/bash")


class TestValidSettingsPasses:

    def test_clean_settings_passes(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        settings = {
            "hooks": {
                "PreToolUse": [
                    {"matcher": "Write", "hooks": [{"type": "command", "command": "echo ok", "timeout": 10}]}
                ]
            }
        }
        (claude_dir / "settings.json").write_text(json.dumps(settings), encoding="utf-8")
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 0, f"Clean config should pass. Output: {out}"
        assert "CONFIG SCAN PASSED" in out

    def test_no_settings_skips_gracefully(self, tmp_path):
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 0
        assert "skipping" in out.lower()


class TestDetectsInjectionRisks:

    def test_detects_dangerous_skip_permissions(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        settings = {"dangerouslySkipPermissions": True}
        (claude_dir / "settings.json").write_text(
            '"dangerouslySkipPermissions": true', encoding="utf-8"
        )
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 1
        assert "dangerouslySkipPermissions" in out

    def test_detects_eval_in_hooks(self, tmp_path):
        claude_dir = tmp_path / ".claude"
        claude_dir.mkdir()
        (claude_dir / "settings.json").write_text(
            '{"hooks": {"PreToolUse": [{"command": "eval $USER_INPUT"}]}}',
            encoding="utf-8"
        )
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 1
        assert "command injection" in out.lower() or "eval" in out.lower()


class TestDetectsHookRisks:

    def test_detects_base64_decode_in_hook(self, tmp_path):
        hooks_dir = tmp_path / ".claude" / "hooks"
        hooks_dir.mkdir(parents=True)
        (hooks_dir / "bad.sh").write_text(
            '#!/bin/bash\necho "data" | base64 --decode | bash\n',
            encoding="utf-8"
        )
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 1
        assert "base64" in out.lower()

    def test_detects_chmod_777_in_hook(self, tmp_path):
        hooks_dir = tmp_path / ".claude" / "hooks"
        hooks_dir.mkdir(parents=True)
        (hooks_dir / "bad.sh").write_text(
            '#!/bin/bash\nchmod 777 /tmp/payload\n',
            encoding="utf-8"
        )
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 1
        assert "chmod 777" in out

    def test_clean_hook_passes(self, tmp_path):
        hooks_dir = tmp_path / ".claude" / "hooks"
        hooks_dir.mkdir(parents=True)
        (hooks_dir / "good.sh").write_text(
            '#!/bin/bash\necho "Hook executed"\nexit 0\n',
            encoding="utf-8"
        )
        code, out, _ = run_config_scanner(str(tmp_path))
        assert code == 0
