"""
Tests for scripts.lib.resolve_paths module.

Validates path resolution for agents, framework detection,
and version reading from install-state.json.
"""

import json
from pathlib import Path

import pytest

from scripts.lib.resolve_paths import (
    GLOBAL_ROOT,
    get_version,
    is_framework_repo,
    resolve_agent,
)

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()


class TestGlobalRoot:
    def test_global_root_points_to_claude_redwork(self):
        parts = GLOBAL_ROOT.parts
        assert parts[-2] == ".claude"
        assert parts[-1] == "redwork"


class TestResolveAgent:
    def test_resolve_existing_agent(self):
        result = resolve_agent("01-product-discovery")
        assert result is not None
        assert result.exists()
        assert result.name == "01-product-discovery.md"

    def test_resolve_missing_agent_returns_none(self):
        result = resolve_agent("nonexistent-agent")
        assert result is None


class TestIsFrameworkRepo:
    def test_is_framework_repo_true_in_repo(self, monkeypatch):
        monkeypatch.setattr(Path, "cwd", staticmethod(lambda: FRAMEWORK_ROOT))
        assert is_framework_repo() is True


class TestGetVersion:
    def test_get_version_from_state(self, tmp_path, monkeypatch):
        state_file = tmp_path / "install-state.json"
        state_file.write_text(
            json.dumps({"version": "2.0.0"}),
            encoding="utf-8",
        )
        monkeypatch.setattr(
            "scripts.lib.resolve_paths.GLOBAL_ROOT",
            tmp_path,
        )
        assert get_version() == "2.0.0"
