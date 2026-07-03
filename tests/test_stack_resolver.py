"""
Tests for scripts.lib.stack_resolver module.

Validates stack resolution logic: default stacks, state.json reading,
builtin config properties, and available stacks listing.
"""

import json
from pathlib import Path

import pytest


@pytest.fixture
def fake_state_dir(tmp_path, monkeypatch):
    """Monkeypatch get_project_state_dir to return a temp directory."""
    state_dir = tmp_path / ".project-state"
    state_dir.mkdir()
    monkeypatch.setattr(
        "scripts.lib.stack_resolver.get_project_state_dir",
        lambda: state_dir,
    )
    return state_dir


class TestGetStackNames:
    def test_default_stack_is_fastapi(self, fake_state_dir):
        from scripts.lib.stack_resolver import get_stack_names

        result = get_stack_names()
        assert result == {"backend": "fastapi", "frontend": "react"}

    def test_reads_stack_from_state(self, fake_state_dir):
        from scripts.lib.stack_resolver import get_stack_names

        state_file = fake_state_dir / "state.json"
        state_file.write_text(
            json.dumps({"stack": {"backend": "fastapi", "frontend": "react"}}),
            encoding="utf-8",
        )

        result = get_stack_names()
        assert result == {"backend": "fastapi", "frontend": "react"}

    def test_pruned_stacks_removed_from_builtins(self, fake_state_dir):
        """django/vue were removed in v2.3 (FastAPI+React only)."""
        from scripts.lib.stack_resolver import BUILTIN_CONFIGS

        assert "django" not in BUILTIN_CONFIGS
        assert "vue" not in BUILTIN_CONFIGS


class TestStackConfigs:
    def test_fastapi_config_has_pytest(self, fake_state_dir):
        from scripts.lib.stack_resolver import get_backend_config

        config = get_backend_config()
        assert config.test_runner == "pytest"

    def test_react_config_has_vitest(self, fake_state_dir):
        from scripts.lib.stack_resolver import get_frontend_config

        config = get_frontend_config()
        assert config.test_runner == "vitest"


class TestAvailableStacks:
    def test_available_stacks(self):
        from scripts.lib.stack_resolver import get_available_stacks

        result = get_available_stacks()
        assert "backend" in result
        assert "frontend" in result
        assert "fastapi" in result["backend"]
        assert "react" in result["frontend"]


class TestIsFastapiProject:
    def test_is_fastapi_default(self, fake_state_dir):
        from scripts.lib.stack_resolver import is_fastapi_project

        assert is_fastapi_project() is True
