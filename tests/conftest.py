"""
RedWork Framework Test Configuration.

Shared fixtures for testing validators, hooks, install, and state management.
"""

import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
FIXTURES_DIR = Path(__file__).parent / "fixtures"


def _find_git_bash() -> str:
    """Locate Git Bash binary that handles C:/ style paths on Windows."""
    candidates = [
        r"C:\Program Files\Git\usr\bin\bash.exe",
        r"C:\Program Files\Git\bin\bash.exe",
    ]
    for c in candidates:
        if Path(c).exists():
            return c
    return "bash"


GIT_BASH = _find_git_bash()


def to_posix(path) -> str:
    """Convert Windows backslashes to forward slashes for bash.
    C:\\Users\\X -> C:/Users/X (works in both Git Bash and subprocess)."""
    return str(path).replace("\\", "/")


@pytest.fixture
def tmp_project(tmp_path):
    """Create a temporary project directory with basic structure."""
    project = tmp_path / "test-project"
    project.mkdir()
    (project / "outputs").mkdir()
    (project / ".project-state").mkdir()
    (project / "backend").mkdir()
    (project / "frontend").mkdir()
    subprocess.run(["git", "init"], cwd=to_posix(project), capture_output=True)
    return project


@pytest.fixture
def framework_root():
    """Return the framework root directory."""
    return FRAMEWORK_ROOT


@pytest.fixture
def valid_fixtures():
    """Return path to valid test fixtures."""
    return FIXTURES_DIR / "valid"


@pytest.fixture
def invalid_fixtures():
    """Return path to invalid test fixtures."""
    return FIXTURES_DIR / "invalid"


def run_script(script_path: str, cwd: str = None, env: dict = None) -> tuple:
    """Run a shell script and return (exit_code, stdout, stderr)."""
    full_env = os.environ.copy()
    if env:
        full_env.update(env)

    result = subprocess.run(
        [GIT_BASH, to_posix(script_path)],
        cwd=str(cwd) if cwd else str(FRAMEWORK_ROOT),
        capture_output=True,
        text=True,
        env=full_env,
        timeout=30,
    )
    return result.returncode, result.stdout, result.stderr
