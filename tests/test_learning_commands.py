"""
Tests for learning command scripts.
"""

import json
import subprocess
import pytest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.lib.learning_manager import LearningManager

FRAMEWORK_ROOT = Path(__file__).parent.parent


def to_posix(path) -> str:
    return str(path).replace("\\", "/")


def run_command(script_name: str, args: list[str] = None,
                cwd: str = ".") -> tuple:
    script_path = FRAMEWORK_ROOT / "scripts" / "learning" / script_name
    cmd = ["python", to_posix(str(script_path))]
    if args:
        cmd.extend(args)
    result = subprocess.run(
        cmd,
        capture_output=True,
        text=True,
        timeout=30,
        cwd=cwd,
    )
    return result.returncode, result.stdout, result.stderr


class TestLearnExtract:
    @pytest.fixture
    def project_dir(self, tmp_path):
        (tmp_path / ".learning").mkdir()
        return tmp_path

    def test_extract_no_observations(self, project_dir):
        rc, stdout, _ = run_command(
            "learn_extract.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "No observations" in stdout

    def test_extract_creates_instincts(self, project_dir):
        lm = LearningManager(str(project_dir))
        # Create enough observations for a pattern
        for _ in range(5):
            lm.record_observation("Write", "backend/app/models.py")

        rc, stdout, _ = run_command(
            "learn_extract.py",
            [str(project_dir), "--window", "1440"],
            cwd=str(project_dir),
        )
        assert rc == 0
        assert "[NEW]" in stdout

        instincts = lm.list_instincts()
        assert len(instincts) >= 1

    def test_extract_updates_existing(self, project_dir):
        lm = LearningManager(str(project_dir))
        for _ in range(5):
            lm.record_observation("Write", "backend/app/models.py")

        # First extraction creates
        run_command(
            "learn_extract.py",
            [str(project_dir), "--window", "1440"],
            cwd=str(project_dir),
        )

        # Add more observations
        for _ in range(5):
            lm.record_observation("Write", "backend/app/models.py")

        # Second extraction updates
        rc, stdout, _ = run_command(
            "learn_extract.py",
            [str(project_dir), "--window", "1440"],
            cwd=str(project_dir),
        )
        assert rc == 0


class TestInstinctStatus:
    @pytest.fixture
    def project_dir(self, tmp_path):
        (tmp_path / ".learning").mkdir()
        return tmp_path

    def test_status_empty(self, project_dir):
        rc, stdout, _ = run_command(
            "instinct_status.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "Observations: 0" in stdout

    def test_status_with_data(self, project_dir):
        lm = LearningManager(str(project_dir))
        lm.record_observation("Write", "test.py")
        lm.create_instinct("test pattern", "ctx", confidence=0.6)

        rc, stdout, _ = run_command(
            "instinct_status.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "Observations: 1" in stdout
        assert "test pattern" in stdout


class TestEvolve:
    @pytest.fixture
    def project_dir(self, tmp_path):
        (tmp_path / ".learning").mkdir()
        return tmp_path

    def test_evolve_empty(self, project_dir):
        rc, stdout, _ = run_command(
            "evolve.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "No project instincts" in stdout

    def test_evolve_shows_promotable(self, project_dir):
        lm = LearningManager(str(project_dir))
        lm.create_instinct("high conf pattern", "ctx", confidence=0.8,
                           tags=["python"])

        rc, stdout, _ = run_command(
            "evolve.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "Promotable" in stdout
        assert "high conf pattern" in stdout

    def test_evolve_shows_clusters(self, project_dir):
        lm = LearningManager(str(project_dir))
        lm.create_instinct("pattern1", "ctx", tags=["python"])
        lm.create_instinct("pattern2", "ctx", tags=["python"])

        rc, stdout, _ = run_command(
            "evolve.py", [str(project_dir)], cwd=str(project_dir)
        )
        assert rc == 0
        assert "python" in stdout


class TestPromote:
    @pytest.fixture
    def project_dir(self, tmp_path):
        (tmp_path / ".learning").mkdir()
        return tmp_path

    def test_promote_success(self, project_dir):
        lm = LearningManager(
            str(project_dir),
            global_root=project_dir / "global-learning",
        )
        inst = lm.create_instinct("promotable", "ctx", confidence=0.8)

        # Need to pass global root via env or the script uses default
        # For testing, we verify the manager directly
        result = lm.promote_instinct(inst["id"])
        assert result is not None
        assert result["stage"] == "promoted"

    def test_promote_low_confidence_rejected(self, project_dir):
        lm = LearningManager(str(project_dir))
        inst = lm.create_instinct("too low", "ctx", confidence=0.3)

        rc, stdout, _ = run_command(
            "promote.py",
            [inst["id"], str(project_dir)],
            cwd=str(project_dir),
        )
        assert rc == 1
        assert "too low" in stdout

    def test_promote_not_found(self, project_dir):
        rc, stdout, _ = run_command(
            "promote.py",
            ["nonexistent-id", str(project_dir)],
            cwd=str(project_dir),
        )
        assert rc == 1
        assert "not found" in stdout
