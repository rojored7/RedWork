"""
Tests for the factory-loop retry controller (scripts/lib/retry_controller.py)
and the run-gates.sh wave gate.

Contract:
- record_attempt(fail) increments; at FRAMEWORK_MAX_RETRIES it is exhausted.
- record_attempt(pass) resets the counter.
- get_next_action() priority: needs_human > exhausted > blocked wave >
  failed agent > next agent > done.
- run-gates.sh: 0 pass (clears flag), 1 fail retryable, 2 exhausted
  (creates needs_human.flag), 3 unknown wave.
"""

import json
import os
import subprocess
from pathlib import Path

import pytest

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.lib.retry_controller import (
    DEFAULT_MAX_RETRIES,
    RetryController,
    get_next_action,
)
from scripts.lib.state_manager import StateManager
from tests.conftest import FRAMEWORK_ROOT, GIT_BASH, to_posix

RUN_GATES = FRAMEWORK_ROOT / "scripts" / "workflow" / "run-gates.sh"


@pytest.fixture
def project(tmp_path):
    (tmp_path / ".project-state").mkdir()
    return tmp_path


class TestRetryCounting:
    def test_first_fail_is_attempt_1(self, project):
        rc = RetryController(str(project))
        result = rc.record_attempt("wave_3", passed=False)
        assert result["attempt"] == 1
        assert result["exhausted"] is False

    def test_exhaustion_at_max_retries(self, project):
        rc = RetryController(str(project))
        for i in range(DEFAULT_MAX_RETRIES - 1):
            result = rc.record_attempt("wave_3", passed=False)
            assert result["exhausted"] is False
        result = rc.record_attempt("wave_3", passed=False)
        assert result["exhausted"] is True
        assert rc.can_retry("wave_3") is False
        assert "wave_3" in rc.exhausted_gates()

    def test_pass_resets_counter(self, project):
        rc = RetryController(str(project))
        rc.record_attempt("wave_3", passed=False)
        rc.record_attempt("wave_3", passed=False)
        result = rc.record_attempt("wave_3", passed=True)
        assert result["passed"] is True
        assert rc.attempts("wave_3") == 0
        assert rc.can_retry("wave_3") is True
        assert rc.exhausted_gates() == []

    def test_max_retries_env_override(self, project, monkeypatch):
        monkeypatch.setenv("FRAMEWORK_MAX_RETRIES", "1")
        rc = RetryController(str(project))
        result = rc.record_attempt("wave_5", passed=False)
        assert result["exhausted"] is True

    def test_attempts_recorded_in_metrics(self, project):
        rc = RetryController(str(project))
        rc.record_attempt("wave_3", passed=False)
        rc.record_attempt("wave_3", passed=True)
        metrics_file = project / ".project-state" / "metrics.jsonl"
        assert metrics_file.exists()
        events = [json.loads(l) for l in metrics_file.read_text().splitlines() if l]
        statuses = [e.get("status") for e in events if e.get("agent") == "gate:wave_3"]
        assert "retry_fail" in statuses
        assert "success" in statuses


class TestNextAction:
    def test_needs_human_flag_wins(self, project):
        (project / ".project-state" / "needs_human.flag").touch()
        action = get_next_action(str(project))
        assert action["action"] == "escalate_human"

    def test_exhausted_gate_escalates(self, project):
        rc = RetryController(str(project))
        for _ in range(DEFAULT_MAX_RETRIES):
            rc.record_attempt("wave_3", passed=False)
        action = get_next_action(str(project))
        assert action["action"] == "escalate_human"
        assert "wave_3" in action["exhausted_gates"]

    def test_blocked_wave_requests_gate_retry(self, project):
        (project / ".project-state" / "wave_3_blocked.flag").touch()
        action = get_next_action(str(project))
        assert action["action"] == "retry_gate"
        assert action["wave"] == "3"
        assert action["gate_id"] == "wave_3"

    def test_failed_agent_is_rerun(self, project):
        sm = StateManager(str(project))
        sm.initialize("test")
        sm.agent_start("00b")
        sm.agent_fail("00b", "boom")
        action = get_next_action(str(project))
        assert action["action"] == "run_agent"
        assert action["agent_id"] == "00b"

    def test_fresh_project_starts_at_00b(self, project):
        sm = StateManager(str(project))
        sm.initialize("test")
        action = get_next_action(str(project))
        assert action["action"] == "run_agent"
        assert action["agent_id"] == "00b"

    def test_uninitialized_project_escalates(self, tmp_path):
        action = get_next_action(str(tmp_path))
        assert action["action"] == "escalate_human"


class TestRunGatesScript:
    """run-gates.sh integration via Git Bash. Uses wave 6 (no post-wave
    script) as the trivially-passing gate and a stub failing hook for
    the failure path."""

    def _run(self, cwd, *args, env_extra=None):
        env = os.environ.copy()
        env["REDWORK_SCRIPTS"] = to_posix(str(FRAMEWORK_ROOT / "scripts"))
        if env_extra:
            env.update(env_extra)
        result = subprocess.run(
            [GIT_BASH, to_posix(str(RUN_GATES)), *args],
            cwd=str(cwd),
            capture_output=True,
            text=True,
            timeout=120,
            env=env,
        )
        return result.returncode, result.stdout, result.stderr

    def _stub_scripts(self, project, hook_exit: int) -> Path:
        """Minimal scripts tree: real retry_controller + stub wave-3 hook."""
        scripts = project / "stub-scripts"
        (scripts / "hooks").mkdir(parents=True)
        (scripts / "lib").mkdir()
        (scripts / "workflow").mkdir()
        for lib in ("retry_controller.py", "state_manager.py", "metrics.py"):
            src = FRAMEWORK_ROOT / "scripts" / "lib" / lib
            (scripts / "lib" / lib).write_text(
                src.read_text(encoding="utf-8"), encoding="utf-8"
            )
        hook = scripts / "hooks" / "post-wave-3-backend.sh"
        hook.write_text(f"#!/bin/bash\nexit {hook_exit}\n", encoding="utf-8", newline="\n")
        return scripts

    def test_unknown_wave_exits_3(self, tmp_path):
        (tmp_path / ".project-state").mkdir()
        code, out, _ = self._run(tmp_path, "9")
        assert code == 3, f"Expected 3, got {code}: {out}"

    def test_wave_without_hook_passes(self, tmp_path):
        (tmp_path / ".project-state").mkdir()
        code, out, _ = self._run(tmp_path, "6")
        assert code == 0, f"Expected 0, got {code}: {out}"

    def test_pass_clears_blocked_flag(self, tmp_path):
        state = tmp_path / ".project-state"
        state.mkdir()
        flag = state / "wave_6_blocked.flag"
        flag.touch()
        code, out, _ = self._run(tmp_path, "6")
        assert code == 0, f"Expected 0, got {code}: {out}"
        assert not flag.exists(), "PASS must clear wave_6_blocked.flag"

    def test_fail_creates_flag_and_counts(self, tmp_path):
        (tmp_path / ".project-state").mkdir()
        scripts = self._stub_scripts(tmp_path, hook_exit=1)
        env = {"REDWORK_SCRIPTS": to_posix(str(scripts))}
        code, out, _ = self._run(tmp_path, "3", env_extra=env)
        assert code == 1, f"Expected 1, got {code}: {out}"
        assert (tmp_path / ".project-state" / "wave_3_blocked.flag").exists()
        retry_state = json.loads(
            (tmp_path / ".project-state" / "retry_state.json").read_text()
        )
        assert retry_state["gates"]["wave_3"]["attempts"] == 1

    def test_exhaustion_creates_needs_human(self, tmp_path):
        (tmp_path / ".project-state").mkdir()
        scripts = self._stub_scripts(tmp_path, hook_exit=1)
        env = {
            "REDWORK_SCRIPTS": to_posix(str(scripts)),
            "FRAMEWORK_MAX_RETRIES": "2",
        }
        code1, _, _ = self._run(tmp_path, "3", env_extra=env)
        assert code1 == 1
        code2, out, _ = self._run(tmp_path, "3", env_extra=env)
        assert code2 == 2, f"Expected 2 (exhausted), got {code2}: {out}"
        assert (tmp_path / ".project-state" / "needs_human.flag").exists()

    def test_fix_then_pass_unblocks(self, tmp_path):
        (tmp_path / ".project-state").mkdir()
        scripts = self._stub_scripts(tmp_path, hook_exit=1)
        env = {"REDWORK_SCRIPTS": to_posix(str(scripts))}
        code, _, _ = self._run(tmp_path, "3", env_extra=env)
        assert code == 1
        # "fix" the wave: hook now passes
        hook = scripts / "hooks" / "post-wave-3-backend.sh"
        hook.write_text("#!/bin/bash\nexit 0\n", encoding="utf-8", newline="\n")
        code, out, _ = self._run(tmp_path, "3", env_extra=env)
        assert code == 0, f"Expected 0 after fix, got {code}: {out}"
        assert not (tmp_path / ".project-state" / "wave_3_blocked.flag").exists()
        retry_state = json.loads(
            (tmp_path / ".project-state" / "retry_state.json").read_text()
        )
        assert retry_state["gates"]["wave_3"]["attempts"] == 0
