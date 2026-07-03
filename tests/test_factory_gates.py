"""
Tests for the flow-invoked factory gates (v2.3):
- slice-gate.sh: per-slice quality gate (lint + types + tests + 100% coverage)
- checkpoint-commit.sh: silent checkpoint, gate-verified, NEVER pushes
- coverage policy: no 80%/99% acceptance text survives in the content layer
- post-wave hooks carry the 100% coverage flags
"""

import json
import os
import re
import subprocess
import time
from pathlib import Path

import pytest

from tests.conftest import FRAMEWORK_ROOT, GIT_BASH, to_posix

SLICE_GATE = FRAMEWORK_ROOT / "scripts" / "workflow" / "slice-gate.sh"
CHECKPOINT = FRAMEWORK_ROOT / "scripts" / "workflow" / "checkpoint-commit.sh"


def _run(script, cwd, *args, env_extra=None):
    env = os.environ.copy()
    if env_extra:
        env.update(env_extra)
    result = subprocess.run(
        [GIT_BASH, to_posix(str(script)), *args],
        cwd=str(cwd), capture_output=True, text=True, timeout=120, env=env,
    )
    return result.returncode, result.stdout, result.stderr


@pytest.fixture
def git_project(tmp_path):
    subprocess.run(["git", "init", "-q"], cwd=str(tmp_path), check=True)
    for cmd in (["git", "config", "user.email", "t@t"],
                ["git", "config", "user.name", "t"]):
        subprocess.run(cmd, cwd=str(tmp_path), check=True, capture_output=True)
    (tmp_path / ".project-state").mkdir()
    return tmp_path


def _write_gate_marker(project, age_seconds=0):
    marker = {
        "side": "backend",
        "passed_at_epoch": int(time.time()) - age_seconds,
        "head_at_pass": "",
    }
    (project / ".project-state" / "last_slice_gate.json").write_text(
        json.dumps(marker), encoding="utf-8"
    )


class TestSliceGateScript:
    def test_unknown_side_exits_3(self, git_project):
        code, out, _ = _run(SLICE_GATE, git_project, "bogus")
        assert code == 3, out

    def test_missing_backend_dir_exits_3(self, git_project):
        code, out, _ = _run(SLICE_GATE, git_project, "backend")
        assert code == 3, out

    def test_script_contains_hard_coverage_gate(self):
        content = SLICE_GATE.read_text(encoding="utf-8")
        assert "--cov-fail-under=100" in content
        assert "--cov=app" in content
        assert "vitest run --coverage" in content
        # coverage tooling absent must FAIL, never skip
        assert "pytest_cov" in content

    def test_green_gate_writes_marker(self, git_project):
        """Backend project whose suite passes at 100% coverage -> marker."""
        backend = git_project / "backend"
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
        code, out, _ = _run(SLICE_GATE, git_project, "backend")
        marker = git_project / ".project-state" / "last_slice_gate.json"
        if code == 0:
            assert marker.exists(), "green gate must write the marker"
        else:
            # Environment without ruff/mypy/pytest-cov: gate must FAIL (1),
            # never silently pass, and must not write a marker
            assert code == 1, out
            assert not marker.exists()

    def test_failing_coverage_blocks(self, git_project):
        """Uncovered line -> gate exit 1 and no marker."""
        backend = git_project / "backend"
        (backend / "app").mkdir(parents=True)
        (backend / "tests").mkdir()
        (backend / "app" / "__init__.py").write_text("")
        (backend / "app" / "calc.py").write_text(
            "def add(a, b):\n    return a + b\n\n"
            "def sub(a, b):\n    return a - b\n",  # never tested
            encoding="utf-8",
        )
        (backend / "tests" / "test_calc.py").write_text(
            "from app.calc import add\n\ndef test_add():\n    assert add(1, 2) == 3\n",
            encoding="utf-8",
        )
        code, out, _ = _run(SLICE_GATE, git_project, "backend")
        assert code == 1, f"uncovered code must fail the gate: {out}"
        assert not (git_project / ".project-state" / "last_slice_gate.json").exists()


class TestCheckpointCommitScript:
    def test_never_pushes(self):
        content = CHECKPOINT.read_text(encoding="utf-8")
        assert "git push" not in content, "checkpoint-commit must NEVER push"
        assert "--allow-empty" not in content

    def test_blocked_without_gate_marker(self, git_project):
        (git_project / "file.py").write_text("x = 1\n")
        code, out, _ = _run(CHECKPOINT, git_project, "test change")
        assert code == 1, out
        assert "slice gate" in out.lower()

    def test_blocked_with_stale_marker(self, git_project):
        _write_gate_marker(git_project, age_seconds=3600)
        (git_project / "file.py").write_text("x = 1\n")
        code, out, _ = _run(CHECKPOINT, git_project, "test change")
        assert code == 1, out

    def test_commits_after_fresh_gate(self, git_project):
        _write_gate_marker(git_project)
        (git_project / "file.py").write_text("x = 1\n")
        code, out, _ = _run(CHECKPOINT, git_project, "add file", "S1")
        assert code == 0, f"{out}"
        log = subprocess.run(
            ["git", "log", "-1", "--pretty=%s"], cwd=str(git_project),
            capture_output=True, text=True,
        ).stdout.strip()
        assert log.startswith("checkpoint:"), log

    def test_secret_staged_aborts(self, git_project):
        _write_gate_marker(git_project)
        (git_project / "config.py").write_text(
            'AWS_KEY = "AKIAIOSFODNN7EXAMPLE"\n', encoding="utf-8"
        )
        code, out, _ = _run(CHECKPOINT, git_project, "oops")
        assert code == 1, f"secret must block the checkpoint: {out}"
        log = subprocess.run(
            ["git", "log", "--oneline"], cwd=str(git_project),
            capture_output=True, text=True,
        )
        assert "checkpoint" not in log.stdout

    def test_env_file_never_staged(self, git_project):
        _write_gate_marker(git_project)
        (git_project / ".env").write_text("SECRET=value\n")
        (git_project / "code.py").write_text("x = 1\n")
        code, out, _ = _run(CHECKPOINT, git_project, "work")
        assert code == 0, out
        tracked = subprocess.run(
            ["git", "ls-files"], cwd=str(git_project),
            capture_output=True, text=True,
        ).stdout
        assert ".env" not in tracked.split()


class TestCoveragePolicy:
    """No sub-100% acceptance text may survive in the content layer."""

    PATTERN = re.compile(
        r"\b(80|85|90|95|99)\s*%.{0,60}(coverage|cobertura|compliance)|"
        r"(coverage|cobertura|compliance).{0,60}\b(80|85|90|95|99)\s*%",
        re.IGNORECASE,
    )

    # Diagnostic examples (not acceptance thresholds) are exempt
    EXEMPT_FILES = {"configuration-analyzer.md"}

    def test_no_sub100_acceptance_text(self):
        hits = []
        for base in ("agents", "rules", "skills", "commands"):
            for md in (FRAMEWORK_ROOT / base).rglob("*.md"):
                if "CHANGELOG" in md.name or md.parts[-2] == "ambient":
                    continue
                if md.name in self.EXEMPT_FILES:
                    continue
                for lineno, line in enumerate(
                    md.read_text(encoding="utf-8", errors="replace").splitlines(), 1
                ):
                    # Lines that ENFORCE 100% may mention lower values as
                    # counter-examples ("NOT 95%, exactly 100%")
                    if "100%" in line:
                        continue
                    if self.PATTERN.search(line):
                        hits.append(f"{md.relative_to(FRAMEWORK_ROOT)}:{lineno}: {line.strip()[:80]}")
        assert not hits, "Sub-100% acceptance text found:\n" + "\n".join(hits)

    def test_post_wave_hooks_carry_coverage_flags(self):
        wave3 = (FRAMEWORK_ROOT / "scripts/hooks/post-wave-3-backend.sh").read_text(encoding="utf-8")
        assert "--cov-fail-under=100" in wave3
        assert "pytest_cov" in wave3  # missing tool = FAIL, not skip
        wave5 = (FRAMEWORK_ROOT / "scripts/hooks/post-wave-5-frontend.sh").read_text(encoding="utf-8")
        assert "vitest run --coverage" in wave5
        enforce = (FRAMEWORK_ROOT / "scripts/hooks/enforce-100.sh").read_text(encoding="utf-8")
        assert "--cov-fail-under=100" in enforce

    def test_project_templates_carry_100_thresholds(self):
        toml = (FRAMEWORK_ROOT / "templates/project/backend-pyproject.toml").read_text(encoding="utf-8")
        assert "fail_under = 100" in toml
        vitest = (FRAMEWORK_ROOT / "templates/project/frontend-vitest.config.ts").read_text(encoding="utf-8")
        for metric in ("lines: 100", "functions: 100", "branches: 100", "statements: 100"):
            assert metric in vitest

    def test_post_commit_hook_is_opt_in(self):
        hook = (FRAMEWORK_ROOT / "scripts/hooks/post-commit-workflow").read_text(encoding="utf-8")
        assert "REDWORK_COMMIT_HOOKS" in hook

    def test_auto_commit_push_is_opt_in(self):
        script = (FRAMEWORK_ROOT / "scripts/workflow/auto-commit-task.sh").read_text(encoding="utf-8")
        assert "REDWORK_AUTO_PUSH" in script
