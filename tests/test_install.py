"""
Tests for install.py cmd_init function.

Uses tmp_path and monkeypatch to avoid touching the real ~/.claude/redwork/ installation.
"""

import json
import sys
from argparse import Namespace
from pathlib import Path
from unittest.mock import patch

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
sys.path.insert(0, str(FRAMEWORK_ROOT))

import install


@pytest.fixture
def init_env(tmp_path, monkeypatch):
    """Set up an isolated environment for cmd_init tests.

    Creates a fake 'workspace' directory, patches GLOBAL_ROOT and FRAMEWORK_DIR,
    and changes cwd so that cmd_init resolves '../<project>' inside tmp_path.
    """
    workspace = tmp_path / "workspace"
    workspace.mkdir()

    fake_global = tmp_path / "global_redwork"
    fake_global.mkdir()

    monkeypatch.setattr(install, "GLOBAL_ROOT", fake_global)
    monkeypatch.setattr(install, "FRAMEWORK_DIR", FRAMEWORK_ROOT)
    monkeypatch.chdir(workspace)

    return workspace, fake_global


def _run_init(project_name: str = "test-project",
              backend: str = "fastapi",
              frontend: str = "react"):
    """Call cmd_init with the given arguments."""
    args = Namespace(
        project_name=project_name,
        backend=backend,
        frontend=frontend,
    )
    install.cmd_init(args)


def test_init_creates_project_structure(init_env):
    """cmd_init creates outputs/, .project-state/, backend/, frontend/ directories."""
    workspace, _ = init_env
    _run_init("test-project")

    project = (workspace / ".." / "test-project").resolve()
    assert project.exists(), f"Project dir not found at {project}"
    assert (project / "outputs").is_dir()
    assert (project / ".project-state").is_dir()
    assert (project / "backend").is_dir()
    assert (project / "frontend").is_dir()
    assert (project / "docs").is_dir()


def test_init_creates_state_json(init_env):
    """state.json is created with correct project_name, stack, and framework_version."""
    workspace, _ = init_env
    _run_init("my-app")

    project = (workspace / ".." / "my-app").resolve()
    state_file = project / ".project-state" / "state.json"
    assert state_file.exists()

    state = json.loads(state_file.read_text(encoding="utf-8"))
    from scripts.lib.version import FRAMEWORK_VERSION

    assert state["project_name"] == "my-app"
    assert state["stack"]["backend"] == "fastapi"
    assert state["stack"]["frontend"] == "react"
    assert state["framework_version"] == FRAMEWORK_VERSION


def test_init_rejects_unsupported_backend():
    """--backend django was pruned in v2.3: argparse rejects it (exit 2)."""
    import subprocess

    result = subprocess.run(
        [sys.executable, "install.py", "init", "x-proj", "--backend", "django"],
        cwd=str(FRAMEWORK_ROOT),
        capture_output=True,
        text=True,
        timeout=30,
    )
    assert result.returncode == 2
    assert "invalid choice" in result.stderr


def test_init_creates_claude_md(init_env):
    """CLAUDE.md exists and contains 'RedWork'."""
    workspace, _ = init_env
    _run_init("md-proj")

    project = (workspace / ".." / "md-proj").resolve()
    claude_md = project / "CLAUDE.md"
    assert claude_md.exists()
    content = claude_md.read_text(encoding="utf-8")
    assert "RedWork" in content


def test_init_creates_gitignore(init_env):
    """.gitignore exists and contains 'node_modules'."""
    workspace, _ = init_env
    _run_init("gi-proj")

    project = (workspace / ".." / "gi-proj").resolve()
    gitignore = project / ".gitignore"
    assert gitignore.exists()
    content = gitignore.read_text(encoding="utf-8")
    assert "node_modules" in content


def test_init_fails_if_dir_exists(init_env):
    """cmd_init should sys.exit(1) if the project directory already exists."""
    workspace, _ = init_env
    existing = (workspace / ".." / "existing-proj").resolve()
    existing.mkdir(parents=True, exist_ok=True)

    with pytest.raises(SystemExit) as exc_info:
        _run_init("existing-proj")
    assert exc_info.value.code == 1


class TestCopyDirManifestFilter:
    """_copy_dir must match manifest entries, which are repo-relative with
    forward slashes (e.g. 'agents/impact-prevalidator.md'). Regression: the
    old comparison used the src-relative path, matched nothing, and profile
    installs silently copied zero files."""

    def test_manifest_entries_are_copied(self, tmp_path):
        manifest = json.loads(
            (FRAMEWORK_ROOT / "manifests" / "backend-only.json").read_text()
        )
        dst = tmp_path / "agents-out"
        install._copy_dir(FRAMEWORK_ROOT / "agents", dst, manifest)

        copied = sorted(
            f"agents/{p.relative_to(dst).as_posix()}" for p in dst.rglob("*.md")
        )
        expected = sorted(e for e in manifest if e.startswith("agents/"))
        assert copied == expected, (
            f"Profile filter copied {len(copied)} agents, expected {len(expected)}"
        )
        assert "agents/impact-prevalidator.md" in copied
        assert "agents/ambient/planner.md" in copied

    def test_unlisted_files_are_skipped(self, tmp_path):
        manifest = ["agents/impact-prevalidator.md"]
        dst = tmp_path / "agents-out"
        install._copy_dir(FRAMEWORK_ROOT / "agents", dst, manifest)
        copied = [p.name for p in dst.glob("*.md")]
        assert copied == ["impact-prevalidator.md"]
