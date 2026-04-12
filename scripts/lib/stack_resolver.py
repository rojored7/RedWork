"""
RedWork Stack Resolver.

Loads stack-specific configuration (test commands, linters, CI images, etc.)
based on the project's declared stack in state.json.

Default: FastAPI (backend) + React (frontend).
Override: explicit --backend/--frontend flags during init.
"""

import yaml
from pathlib import Path
from typing import Optional

from scripts.lib.resolve_paths import resolve_stack_config, get_project_state_dir


DEFAULT_STACK = {
    "backend": "fastapi",
    "frontend": "react",
}

# Inline defaults if config.yaml files don't exist yet
BUILTIN_CONFIGS = {
    "fastapi": {
        "framework": "FastAPI",
        "language": "python",
        "test_runner": "pytest",
        "linter": "ruff",
        "type_checker": "mypy",
        "package_manager": "pip",
        "build_command": "uvicorn app.main:app",
        "test_command": "python -m pytest tests/ -v",
        "lint_command": "ruff check .",
        "type_check_command": "mypy app/",
        "ci_image": "python:3.12-slim",
        "forbidden_patterns": ["@nestjs", "express", ".ts files in backend/"],
    },
    "django": {
        "framework": "Django",
        "language": "python",
        "test_runner": "pytest",
        "linter": "ruff",
        "type_checker": "mypy",
        "package_manager": "pip",
        "build_command": "python manage.py runserver",
        "test_command": "python -m pytest tests/ -v",
        "lint_command": "ruff check .",
        "type_check_command": "mypy .",
        "ci_image": "python:3.12-slim",
        "forbidden_patterns": ["@nestjs", "express"],
    },
    "react": {
        "framework": "React",
        "language": "typescript",
        "test_runner": "vitest",
        "linter": "eslint",
        "type_checker": "tsc",
        "package_manager": "npm",
        "build_command": "npm run build",
        "test_command": "npx vitest run",
        "lint_command": "npx eslint src/",
        "type_check_command": "npx tsc --noEmit",
        "ci_image": "node:20-slim",
        "forbidden_patterns": [],
    },
    "vue": {
        "framework": "Vue",
        "language": "typescript",
        "test_runner": "vitest",
        "linter": "eslint",
        "type_checker": "vue-tsc",
        "package_manager": "npm",
        "build_command": "npm run build",
        "test_command": "npx vitest run",
        "lint_command": "npx eslint src/",
        "type_check_command": "npx vue-tsc --noEmit",
        "ci_image": "node:20-slim",
        "forbidden_patterns": [],
    },
}


def _load_project_stack() -> dict:
    """Read stack from project state.json."""
    import json
    state_file = get_project_state_dir() / "state.json"
    if state_file.exists():
        with open(state_file, "r", encoding="utf-8") as f:
            state = json.load(f)
        return state.get("stack", DEFAULT_STACK)
    return DEFAULT_STACK


def _load_config(stack_name: str) -> dict:
    """Load stack config from YAML file, falling back to builtins."""
    config_path = resolve_stack_config(stack_name)
    if config_path and config_path.exists():
        with open(config_path, "r", encoding="utf-8") as f:
            return yaml.safe_load(f)
    return BUILTIN_CONFIGS.get(stack_name, {})


class StackConfig:
    """Resolved stack configuration for backend or frontend."""

    def __init__(self, config: dict):
        self._config = config

    @property
    def framework(self) -> str:
        return self._config.get("framework", "unknown")

    @property
    def language(self) -> str:
        return self._config.get("language", "unknown")

    @property
    def test_command(self) -> str:
        return self._config.get("test_command", "echo 'no test command'")

    @property
    def lint_command(self) -> str:
        return self._config.get("lint_command", "echo 'no lint command'")

    @property
    def type_check_command(self) -> str:
        return self._config.get("type_check_command", "echo 'no type check'")

    @property
    def build_command(self) -> str:
        return self._config.get("build_command", "echo 'no build command'")

    @property
    def ci_image(self) -> str:
        return self._config.get("ci_image", "alpine:latest")

    @property
    def forbidden_patterns(self) -> list:
        return self._config.get("forbidden_patterns", [])

    @property
    def test_runner(self) -> str:
        return self._config.get("test_runner", "unknown")

    @property
    def linter(self) -> str:
        return self._config.get("linter", "unknown")

    def get(self, key: str, default=None):
        return self._config.get(key, default)


def get_backend_config() -> StackConfig:
    """Get the resolved backend stack configuration."""
    stack = _load_project_stack()
    backend = stack.get("backend", "fastapi")
    return StackConfig(_load_config(backend))


def get_frontend_config() -> StackConfig:
    """Get the resolved frontend stack configuration."""
    stack = _load_project_stack()
    frontend = stack.get("frontend", "react")
    return StackConfig(_load_config(frontend))


def get_stack_names() -> dict:
    """Return the declared stack names."""
    return _load_project_stack()


def is_fastapi_project() -> bool:
    """Check if the current project uses FastAPI (default)."""
    stack = _load_project_stack()
    return stack.get("backend", "fastapi") == "fastapi"


def get_available_stacks() -> dict:
    """List all available stack configurations."""
    return {
        "backend": list(k for k in BUILTIN_CONFIGS if BUILTIN_CONFIGS[k].get("language") == "python"),
        "frontend": list(k for k in BUILTIN_CONFIGS if BUILTIN_CONFIGS[k].get("language") == "typescript"),
    }
