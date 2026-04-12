"""
Tests for validate-agent-XX.sh scripts.

Each validator must:
- Pass with valid input (exit 0)
- Fail with invalid input (exit != 0)
- Fail with missing file (exit != 0)
- Produce clear error messages on failure
"""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

from tests.conftest import FRAMEWORK_ROOT, FIXTURES_DIR, run_script


class TestValidateAgent01:
    """Tests for validate-agent-01.sh (Product Discovery)."""

    VALIDATOR = FRAMEWORK_ROOT / "scripts" / "workflow" / "validate-agent-01.sh"

    def test_valid_input_passes(self, tmp_project, valid_fixtures):
        fixture = valid_fixtures / "01_product_discovery.md"
        if not fixture.exists():
            pytest.skip("Fixture not created yet")
        shutil.copy(str(fixture), str(tmp_project / "outputs" / "01_product_discovery.md"))
        # Validator expects file at outputs/ or root
        code, out, err = run_script(str(self.VALIDATOR), cwd=str(tmp_project))
        assert code == 0, f"Expected pass but got exit {code}: {out}{err}"

    def test_missing_file_fails(self, tmp_project):
        code, out, err = run_script(str(self.VALIDATOR), cwd=str(tmp_project))
        assert code != 0, "Expected failure for missing file"

    def test_too_short_fails(self, tmp_project, invalid_fixtures):
        fixture = invalid_fixtures / "01_too_short.md"
        if not fixture.exists():
            pytest.skip("Fixture not created yet")
        shutil.copy(str(fixture), str(tmp_project / "outputs" / "01_product_discovery.md"))
        code, out, err = run_script(str(self.VALIDATOR), cwd=str(tmp_project))
        assert code != 0, "Expected failure for too-short file"


class TestValidateSprintCompleteness:
    """Tests for validate-sprint-completeness.sh."""

    VALIDATOR = FRAMEWORK_ROOT / "scripts" / "workflow" / "validate-sprint-completeness.sh"

    def test_missing_sprint_dir_exits_2(self):
        code, out, err = run_script(
            str(self.VALIDATOR),
            env={"SPRINT_NUM": "99"},
        )
        # Pass sprint number as argument
        result = subprocess.run(
            ["bash", str(self.VALIDATOR), "99"],
            cwd=str(FRAMEWORK_ROOT),
            capture_output=True, text=True, timeout=30,
        )
        assert result.returncode == 2, f"Expected exit 2 for missing sprint, got {result.returncode}"

    def test_no_args_exits_3(self):
        result = subprocess.run(
            ["bash", str(self.VALIDATOR)],
            cwd=str(FRAMEWORK_ROOT),
            capture_output=True, text=True, timeout=30,
        )
        assert result.returncode == 3, f"Expected exit 3 for no args, got {result.returncode}"


class TestInstallWorkflowHooks:
    """Tests for install-workflow-hooks.sh."""

    SCRIPT = FRAMEWORK_ROOT / "scripts" / "install-workflow-hooks.sh"

    def test_installs_post_commit_with_v2_marker(self, tmp_project):
        # Copy scripts to tmp project
        scripts_dst = tmp_project / ".framework" / "scripts"
        shutil.copytree(str(FRAMEWORK_ROOT / "scripts"), str(scripts_dst))

        code, out, err = run_script(str(self.SCRIPT), cwd=str(tmp_project))
        assert code == 0, f"Install failed: {out}{err}"

        post_commit = tmp_project / ".git" / "hooks" / "post-commit"
        assert post_commit.exists(), "post-commit hook not created"

        content = post_commit.read_text()
        assert "framework-workflow-hook-v2" in content, "v2 marker missing"

    def test_installs_pre_commit(self, tmp_project):
        scripts_dst = tmp_project / ".framework" / "scripts"
        shutil.copytree(str(FRAMEWORK_ROOT / "scripts"), str(scripts_dst))

        code, out, err = run_script(str(self.SCRIPT), cwd=str(tmp_project))
        assert code == 0

        pre_commit = tmp_project / ".git" / "hooks" / "pre-commit"
        assert pre_commit.exists(), "pre-commit hook not created"

    def test_fails_without_git(self, tmp_path):
        no_git = tmp_path / "no-git"
        no_git.mkdir()
        code, out, err = run_script(str(self.SCRIPT), cwd=str(no_git))
        assert code != 0, "Should fail without .git"
