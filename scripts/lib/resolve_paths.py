"""
RedWork Path Resolution Library.

Resolves paths for framework files in two modes:
- Global: ~/.claude/redwork/ (installed via install.py)
- Local: .framework/ or scripts/ (legacy, project-local copy)

All scripts and hooks use this module to find framework files
without hardcoding paths.
"""

import os
from pathlib import Path
from typing import Optional


GLOBAL_ROOT = Path.home() / ".claude" / "redwork"
LOCAL_ROOTS = [".framework", "scripts", "."]


def get_redwork_root() -> Path:
    """Return the active RedWork installation root.

    Priority:
    1. REDWORK_ROOT environment variable (explicit override)
    2. ~/.claude/redwork/ if install-state.json exists (global install)
    3. .framework/ if it exists (legacy project-local)
    4. Current directory if agents/ exists (running from framework repo)
    """
    env_root = os.environ.get("REDWORK_ROOT")
    if env_root:
        return Path(env_root)

    if (GLOBAL_ROOT / "install-state.json").exists():
        return GLOBAL_ROOT

    cwd = Path.cwd()
    if (cwd / ".framework" / "agents").exists():
        return cwd / ".framework"

    if (cwd / "agents").exists():
        return cwd

    return GLOBAL_ROOT


def resolve(relative_path: str) -> Optional[Path]:
    """Resolve a framework-relative path to an absolute path.

    Searches in order:
    1. Global install (~/.claude/redwork/)
    2. Local .framework/
    3. Project root scripts/
    4. Current directory

    Returns None if not found anywhere.
    """
    candidates = [GLOBAL_ROOT / relative_path]

    cwd = Path.cwd()
    for local in LOCAL_ROOTS:
        candidates.append(cwd / local / relative_path)

    for candidate in candidates:
        if candidate.exists():
            return candidate

    return None


def resolve_agent(agent_name: str) -> Optional[Path]:
    """Resolve an agent .md file by name (with or without .md extension)."""
    if not agent_name.endswith(".md"):
        agent_name += ".md"
    return resolve(f"agents/{agent_name}")


def resolve_skill(skill_name: str) -> Optional[Path]:
    """Resolve a skill .md file by name."""
    if not skill_name.endswith(".md"):
        skill_name += ".md"
    return resolve(f"skills/{skill_name}")


def resolve_script(script_name: str) -> Optional[Path]:
    """Resolve a script file (workflow or hooks)."""
    result = resolve(f"scripts/workflow/{script_name}")
    if result:
        return result
    return resolve(f"scripts/hooks/{script_name}")


def resolve_stack_config(stack_name: str) -> Optional[Path]:
    """Resolve a stack config.yaml file."""
    return resolve(f"stacks/{stack_name}/config.yaml")


def get_project_state_dir() -> Path:
    """Return the .project-state/ directory for the current project."""
    return Path.cwd() / ".project-state"


def get_outputs_dir() -> Path:
    """Return the outputs/ directory for the current project."""
    return Path.cwd() / "outputs"


def is_global_install() -> bool:
    """Check if RedWork is installed globally."""
    return (GLOBAL_ROOT / "install-state.json").exists()


def is_framework_repo() -> bool:
    """Check if we are inside the Framework repository itself."""
    cwd = Path.cwd()
    return (cwd / "agents").is_dir() and (cwd / "init-new-project.sh").exists()


def get_version() -> str:
    """Return the installed RedWork version from install-state.json."""
    import json
    state_file = GLOBAL_ROOT / "install-state.json"
    if state_file.exists():
        with open(state_file) as f:
            return json.load(f).get("version", "unknown")
    return "local"
