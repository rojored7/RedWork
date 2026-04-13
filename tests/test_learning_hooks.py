"""
Tests for the learning observation hook (post-tool-observe.sh).
"""

import json
import os
import subprocess
import pytest
from pathlib import Path

from conftest import FRAMEWORK_ROOT, to_posix

HOOK_PATH = FRAMEWORK_ROOT / ".claude" / "hooks" / "post-tool-observe.sh"


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


def run_hook(hook_path: Path, input_data: dict, cwd: str = ".") -> tuple:
    input_data.setdefault("cwd", to_posix(cwd))
    result = subprocess.run(
        [GIT_BASH, to_posix(str(hook_path))],
        input=json.dumps(input_data),
        capture_output=True,
        text=True,
        timeout=10,
        cwd=cwd,
    )
    return result.returncode, result.stdout, result.stderr


class TestPostToolObserveHook:
    @pytest.fixture
    def project_dir(self, tmp_path):
        learning_dir = tmp_path / ".learning"
        learning_dir.mkdir()
        return tmp_path

    def test_hook_always_exits_zero(self, project_dir):
        rc, _, _ = run_hook(HOOK_PATH, {
            "tool_name": "Write",
            "tool_input": {"file_path": "test.py"},
        }, cwd=str(project_dir))
        assert rc == 0

    def test_hook_creates_observation(self, project_dir):
        run_hook(HOOK_PATH, {
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/app/models.py"},
            "tool_result": "File written",
        }, cwd=str(project_dir))

        obs_file = project_dir / ".learning" / "observations.jsonl"
        assert obs_file.exists()

        with open(obs_file) as f:
            lines = f.readlines()
        assert len(lines) >= 1

        record = json.loads(lines[0])
        assert record["tool"] == "Write"
        assert "models.py" in record["input"]

    def test_hook_skips_without_learning_dir(self, tmp_path):
        """No .learning/ dir means hook does nothing."""
        rc, stdout, _ = run_hook(HOOK_PATH, {
            "tool_name": "Read",
            "tool_input": {"file_path": "foo.py"},
        }, cwd=str(tmp_path))
        assert rc == 0

        obs_file = tmp_path / ".learning" / "observations.jsonl"
        assert not obs_file.exists()

    def test_hook_captures_bash_command(self, project_dir):
        run_hook(HOOK_PATH, {
            "tool_name": "Bash",
            "tool_input": {"command": "python -m pytest tests/ -v"},
        }, cwd=str(project_dir))

        obs_file = project_dir / ".learning" / "observations.jsonl"
        with open(obs_file) as f:
            record = json.loads(f.readline())
        assert record["tool"] == "Bash"
        assert "pytest" in record["input"]

    def test_hook_captures_grep_pattern(self, project_dir):
        run_hook(HOOK_PATH, {
            "tool_name": "Grep",
            "tool_input": {"pattern": "def test_.*"},
        }, cwd=str(project_dir))

        obs_file = project_dir / ".learning" / "observations.jsonl"
        with open(obs_file) as f:
            record = json.loads(f.readline())
        assert record["tool"] == "Grep"
        assert "def test_" in record["input"]

    def test_hook_handles_malformed_input(self, project_dir):
        """Malformed JSON should not crash the hook."""
        result = subprocess.run(
            [GIT_BASH, to_posix(str(HOOK_PATH))],
            input="not valid json",
            capture_output=True,
            text=True,
            timeout=10,
            cwd=str(project_dir),
        )
        assert result.returncode == 0

    def test_multiple_observations_append(self, project_dir):
        for i in range(3):
            run_hook(HOOK_PATH, {
                "tool_name": "Edit",
                "tool_input": {"file_path": f"file{i}.py"},
            }, cwd=str(project_dir))

        obs_file = project_dir / ".learning" / "observations.jsonl"
        with open(obs_file) as f:
            lines = [l for l in f.readlines() if l.strip()]
        assert len(lines) == 3
