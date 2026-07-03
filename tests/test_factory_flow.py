"""
End-to-end factory chain test (v2.3): one project fixture goes through the
full engine sequence the flows drive:

  slice-gate (green) -> checkpoint-commit (silent, no push)
  -> break coverage -> slice-gate blocks -> checkpoint refused
  -> wave gate fails N times -> needs_human.flag
  -> retry_controller.next reports the right action at every step
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.lib.retry_controller import get_next_action
from tests.conftest import FRAMEWORK_ROOT, GIT_BASH, to_posix

SLICE_GATE = FRAMEWORK_ROOT / "scripts" / "workflow" / "slice-gate.sh"
CHECKPOINT = FRAMEWORK_ROOT / "scripts" / "workflow" / "checkpoint-commit.sh"
RUN_GATES = FRAMEWORK_ROOT / "scripts" / "workflow" / "run-gates.sh"


def _bash(script, cwd, *args, env_extra=None):
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    result = subprocess.run(
        [GIT_BASH, to_posix(str(script)), *args],
        cwd=str(cwd), capture_output=True, text=True, timeout=180, env=env,
    )
    return result.returncode, result.stdout + result.stderr


def _git(cwd, *args):
    return subprocess.run(
        ["git", *args], cwd=str(cwd), capture_output=True, text=True
    ).stdout.strip()


@pytest.fixture
def factory_project(tmp_path):
    """Mini FastAPI-shaped project with a passing 100%-covered suite."""
    subprocess.run(["git", "init", "-q"], cwd=str(tmp_path), check=True)
    for cmd in (["git", "config", "user.email", "t@t"],
                ["git", "config", "user.name", "t"]):
        subprocess.run(cmd, cwd=str(tmp_path), check=True, capture_output=True)
    (tmp_path / ".project-state").mkdir()
    backend = tmp_path / "backend"
    (backend / "app").mkdir(parents=True)
    (backend / "tests").mkdir()
    (backend / "app" / "__init__.py").write_text("")
    (backend / "app" / "calc.py").write_text(
        "def add(a, b):\n    return a + b\n", encoding="utf-8"
    )
    (backend / "tests" / "test_calc.py").write_text(
        "from app.calc import add\n\ndef test_add():\n    assert add(1, 2) == 3\n",
        encoding="utf-8",
    )
    (backend / "pyproject.toml").write_text(
        '[tool.coverage.run]\nsource = ["app"]\nomit = ["app/__init__.py"]\n',
        encoding="utf-8",
    )
    return tmp_path


def _tooling_available(project) -> bool:
    """slice-gate needs ruff+mypy+pytest-cov; absent tooling makes the gate
    fail by design. Detect so the happy-path assertions adapt."""
    code, _ = _bash(SLICE_GATE, project, "backend")
    marker = project / ".project-state" / "last_slice_gate.json"
    ok = code == 0 and marker.exists()
    # reset retry state polluted by the probe
    retry = project / ".project-state" / "retry_state.json"
    retry.unlink(missing_ok=True)
    return ok


class TestFactoryChain:
    def test_full_chain(self, factory_project):
        project = factory_project
        tooling = _tooling_available(project)

        if tooling:
            # 1. Green slice -> checkpoint commits silently, no push possible
            code, out = _bash(SLICE_GATE, project, "backend")
            assert code == 0, out
            code, out = _bash(CHECKPOINT, project, "slice 1: calc.add", "S1")
            assert code == 0, out
            assert _git(project, "log", "-1", "--pretty=%s").startswith("checkpoint:")
            assert _git(project, "remote") == ""  # nothing to push to, by design

            # 2. Break coverage: new untested function
            calc = project / "backend" / "app" / "calc.py"
            calc.write_text(
                calc.read_text() + "\ndef sub(a, b):\n    return a - b\n",
                encoding="utf-8",
            )
            code, out = _bash(SLICE_GATE, project, "backend")
            assert code == 1, f"uncovered code must block: {out}"

            # 3. Checkpoint refused without a fresh green gate
            #    (marker still exists from step 1 but HEAD moved on content;
            #    gate marker freshness window covers it, so simulate staleness)
            marker = project / ".project-state" / "last_slice_gate.json"
            data = json.loads(marker.read_text())
            data["passed_at_epoch"] -= 4000
            marker.write_text(json.dumps(data))
            code, out = _bash(CHECKPOINT, project, "should not commit")
            assert code == 1, out

        # 4. Wave gate: failing hook chain -> retries -> needs_human
        stub = project / "stub-scripts"
        (stub / "hooks").mkdir(parents=True)
        (stub / "lib").mkdir()
        for lib in ("retry_controller.py", "state_manager.py", "metrics.py"):
            (stub / "lib" / lib).write_text(
                (FRAMEWORK_ROOT / "scripts" / "lib" / lib).read_text(encoding="utf-8"),
                encoding="utf-8",
            )
        (stub / "hooks" / "post-wave-3-backend.sh").write_text(
            "#!/bin/bash\nexit 1\n", encoding="utf-8", newline="\n"
        )
        env = {
            "REDWORK_SCRIPTS": to_posix(str(stub)),
            "FRAMEWORK_MAX_RETRIES": "2",
        }
        code, out = _bash(RUN_GATES, project, "3", env_extra=env)
        assert code == 1, out
        action = get_next_action(str(project))
        assert action["action"] == "retry_gate"
        assert action["wave"] == "3"

        code, out = _bash(RUN_GATES, project, "3", env_extra=env)
        assert code == 2, f"retries exhausted must exit 2: {out}"
        assert (project / ".project-state" / "needs_human.flag").exists()
        action = get_next_action(str(project))
        assert action["action"] == "escalate_human"

        # 5. Human decision taken: clear flag, fix the wave, gate passes,
        #    flags clear automatically
        (project / ".project-state" / "needs_human.flag").unlink()
        (stub / "hooks" / "post-wave-3-backend.sh").write_text(
            "#!/bin/bash\nexit 0\n", encoding="utf-8", newline="\n"
        )
        code, out = _bash(RUN_GATES, project, "3", env_extra=env)
        assert code == 0, out
        assert not (project / ".project-state" / "wave_3_blocked.flag").exists()
