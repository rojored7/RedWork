"""
RedWork Framework Test Configuration.

Shared fixtures for testing validators, hooks, install, and state management.
"""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def tmp_project(tmp_path):
    """Create a temporary project directory with basic structure."""
    project = tmp_path / "test-project"
    project.mkdir()
    (project / "outputs").mkdir()
    (project / ".project-state").mkdir()
    (project / "backend").mkdir()
    (project / "frontend").mkdir()
    # Init git so hooks can work
    subprocess.run(["git", "init"], cwd=str(project), capture_output=True)
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
        ["bash", str(script_path)],
        cwd=cwd or str(FRAMEWORK_ROOT),
        capture_output=True,
        text=True,
        env=full_env,
        timeout=30,
    )
    return result.returncode, result.stdout, result.stderr
