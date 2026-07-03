#!/usr/bin/env python3
"""
RedWork Framework Installer.

Usage:
    python install.py install [--profile full|backend-only|frontend-only]
    python install.py update
    python install.py uninstall
    python install.py init <project-name> [--backend fastapi] [--frontend react]
    python install.py status
"""

import argparse
import hashlib
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

VERSION = "2.2.0"
GLOBAL_ROOT = Path.home() / ".claude" / "redwork"
FRAMEWORK_DIR = Path(__file__).parent.resolve()


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _file_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()[:12]


def _copy_dir(src: Path, dst: Path, manifest_filter: list = None):
    """Copy directory tree, optionally filtering by manifest.

    Manifest entries are repo-relative with forward slashes (e.g.
    "agents/impact-prevalidator.md"), so matching must prefix the source
    dir name and normalize separators."""
    for root, dirs, files in os.walk(src):
        # Skip hidden dirs and __pycache__
        dirs[:] = [d for d in dirs if not d.startswith(".") and d != "__pycache__"]
        for f in files:
            src_file = Path(root) / f
            rel = src_file.relative_to(src)

            if manifest_filter:
                rel_key = f"{src.name}/{rel.as_posix()}"
                if rel_key not in manifest_filter and rel.as_posix() not in manifest_filter:
                    continue

            dst_file = dst / rel
            dst_file.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(str(src_file), str(dst_file))


def _install_ambient_agents() -> list:
    """Copy agents/ambient/*.md to ~/.claude/agents/ (the Task tool registry).

    Non-clobbering policy:
      - destination missing        -> copy and record
      - destination identical hash -> skip (already installed, e.g. by ECC)
      - destination differs        -> keep the user's version, warn

    Returns the list of agent filenames actually copied by this install.
    """
    ambient_src = FRAMEWORK_DIR / "agents" / "ambient"
    if not ambient_src.exists():
        return []

    print("  Installing ambient agents (Task tool registry)...")
    agents_dst = Path.home() / ".claude" / "agents"
    agents_dst.mkdir(parents=True, exist_ok=True)

    copied = []
    for agent_file in sorted(ambient_src.glob("*.md")):
        if agent_file.name == "README.md":
            continue
        dst = agents_dst / agent_file.name
        if not dst.exists():
            shutil.copy2(str(agent_file), str(dst))
            copied.append(agent_file.name)
        elif _file_hash(dst) == _file_hash(agent_file):
            continue  # identical copy already present (e.g. ECC install)
        else:
            print(f"    WARNING: ~/.claude/agents/{agent_file.name} differs "
                  "from the vendored copy - keeping the existing version.")
    if copied:
        print(f"    Copied {len(copied)} ambient agents.")
    return copied


def _load_manifest(profile: str) -> list:
    """Load manifest for a profile. Returns empty list for 'full' (copy everything)."""
    manifest_path = FRAMEWORK_DIR / "manifests" / f"{profile}.json"
    if manifest_path.exists():
        with open(manifest_path) as f:
            return json.load(f)
    return []


# ============================================================================
# INSTALL
# ============================================================================

def cmd_install(args):
    profile = args.profile or "full"
    print(f"Installing RedWork v{VERSION} (profile: {profile})...")
    print(f"Destination: {GLOBAL_ROOT}")

    manifest = _load_manifest(profile) if profile != "full" else []

    # Copy agents
    print("  Copying agents...")
    _copy_dir(FRAMEWORK_DIR / "agents", GLOBAL_ROOT / "agents", manifest or None)

    # Copy skills
    print("  Copying skills...")
    _copy_dir(FRAMEWORK_DIR / "skills", GLOBAL_ROOT / "skills", manifest or None)

    # Copy scripts
    print("  Copying scripts...")
    _copy_dir(FRAMEWORK_DIR / "scripts", GLOBAL_ROOT / "scripts", manifest or None)

    # Create global learning directories
    learning_dirs = [
        GLOBAL_ROOT / "learning",
        GLOBAL_ROOT / "learning" / "instincts",
    ]
    for d in learning_dirs:
        d.mkdir(parents=True, exist_ok=True)
    print("  Created learning directories...")

    # Copy stacks
    stacks_dir = FRAMEWORK_DIR / "stacks"
    if stacks_dir.exists():
        print("  Copying stacks...")
        _copy_dir(stacks_dir, GLOBAL_ROOT / "stacks")

    # Copy rules
    rules_dir = FRAMEWORK_DIR / "rules"
    if rules_dir.exists():
        print("  Copying rules...")
        _copy_dir(rules_dir, GLOBAL_ROOT / "rules")

    # Copy .project-state-templates
    templates_dir = FRAMEWORK_DIR / ".project-state-templates"
    if templates_dir.exists():
        print("  Copying project state templates...")
        _copy_dir(templates_dir, GLOBAL_ROOT / ".project-state-templates")

    # Copy Claude Code hooks
    hooks_src = FRAMEWORK_DIR / ".claude" / "hooks"
    if hooks_src.exists():
        print("  Copying Claude Code hooks...")
        hooks_dst = Path.home() / ".claude" / "hooks"
        hooks_dst.mkdir(parents=True, exist_ok=True)
        for hook_file in hooks_src.glob("*.sh"):
            shutil.copy2(str(hook_file), str(hooks_dst / hook_file.name))

    # Copy slash commands (flows) to ~/.claude/commands/
    commands_src = FRAMEWORK_DIR / "commands"
    if commands_src.exists():
        print("  Copying slash commands (flows)...")
        commands_dst = Path.home() / ".claude" / "commands"
        commands_dst.mkdir(parents=True, exist_ok=True)
        for cmd_file in commands_src.glob("*.md"):
            shutil.copy2(str(cmd_file), str(commands_dst / cmd_file.name))

    # Install vendored ambient agents to ~/.claude/agents/ (the registry
    # the Task tool reads). Non-clobbering: never overwrite a differing
    # user/ECC copy; skip identical ones; record what we actually copied.
    ambient_installed = _install_ambient_agents()

    # Update global settings.json to reference hooks
    settings_src = FRAMEWORK_DIR / ".claude" / "settings.json"
    settings_dst = Path.home() / ".claude" / "settings.json"
    if settings_src.exists():
        print("  Updating Claude Code settings.json...")
        # Merge: keep existing settings, add hooks from RedWork
        existing = {}
        if settings_dst.exists():
            with open(settings_dst) as f:
                existing = json.load(f)

        with open(settings_src) as f:
            redwork_settings = json.load(f)

        # Merge hooks (RedWork hooks + existing hooks)
        if "hooks" in redwork_settings:
            if "hooks" not in existing:
                existing["hooks"] = {}
            for event, hook_list in redwork_settings["hooks"].items():
                if event not in existing["hooks"]:
                    existing["hooks"][event] = hook_list
                else:
                    # Append RedWork hooks that don't already exist
                    existing_commands = {h.get("command") for h in existing["hooks"][event] if isinstance(h, dict)}
                    for hook in hook_list:
                        if isinstance(hook, dict) and hook.get("command") not in existing_commands:
                            existing["hooks"][event].append(hook)

        with open(settings_dst, "w") as f:
            json.dump(existing, f, indent=2)

    # Write install state
    installed_files = []
    for root, _, files in os.walk(GLOBAL_ROOT):
        for f in files:
            rel = str(Path(root, f).relative_to(GLOBAL_ROOT))
            installed_files.append(rel)

    install_state = {
        "version": VERSION,
        "profile": profile,
        "installed_at": _now_iso(),
        "updated_at": _now_iso(),
        "files_count": len(installed_files),
        "ambient_installed": ambient_installed,
        "framework_source": str(FRAMEWORK_DIR),
    }

    state_file = GLOBAL_ROOT / "install-state.json"
    state_file.parent.mkdir(parents=True, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump(install_state, f, indent=2)

    print(f"\nRedWork v{VERSION} installed successfully.")
    print(f"  Files: {len(installed_files)}")
    print(f"  Location: {GLOBAL_ROOT}")
    print(f"\nNext: python install.py init <project-name>")


# ============================================================================
# UPDATE
# ============================================================================

def cmd_update(args):
    state_file = GLOBAL_ROOT / "install-state.json"
    if not state_file.exists():
        print("ERROR: RedWork is not installed. Run 'python install.py install' first.")
        sys.exit(1)

    with open(state_file) as f:
        state = json.load(f)

    profile = state.get("profile", "full")
    print(f"Updating RedWork from v{state.get('version', '?')} to v{VERSION}...")

    # Re-run install with same profile
    args.profile = profile
    cmd_install(args)

    # Update timestamp
    with open(state_file) as f:
        state = json.load(f)
    state["updated_at"] = _now_iso()
    state["version"] = VERSION
    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)


# ============================================================================
# UNINSTALL
# ============================================================================

def cmd_uninstall(args):
    if not GLOBAL_ROOT.exists():
        print("RedWork is not installed.")
        return

    print(f"Uninstalling RedWork from {GLOBAL_ROOT}...")
    shutil.rmtree(str(GLOBAL_ROOT))
    print("RedWork uninstalled.")
    print("Note: Project-local files (outputs/, .project-state/) are NOT removed.")


# ============================================================================
# INIT
# ============================================================================

def cmd_init(args):
    project_name = args.project_name
    backend = args.backend or "fastapi"
    frontend = args.frontend or "react"

    project_path = (Path.cwd() / ".." / project_name).resolve()

    if project_path.exists():
        print(f"ERROR: Directory already exists: {project_path}")
        sys.exit(1)

    print(f"Initializing project: {project_name}")
    print(f"  Location: {project_path}")
    print(f"  Backend: {backend}")
    print(f"  Frontend: {frontend}")

    # Create project structure
    dirs = [
        "outputs", "outputs/compliance",
        ".project-state",
        ".learning", ".learning/instincts",
        ".learning/analysis", ".learning/proposed-skills", ".learning/errors-kb",
        "backend", "frontend", "docs",
        ".claude/hooks",
        ".github/workflows",
        "scripts/security",
    ]
    for d in dirs:
        (project_path / d).mkdir(parents=True, exist_ok=True)

    # Project CI: GitHub Actions (same gate commands as slice-gate/run-gates).
    # Deployment is out of scope by design (docs/DEPLOYMENT.md).
    ci_template = FRAMEWORK_DIR / "templates" / "project" / "github-workflows-ci.yml"
    if ci_template.exists():
        shutil.copy2(str(ci_template), str(project_path / ".github" / "workflows" / "ci.yml"))

    deployment_doc = FRAMEWORK_DIR / "templates" / "project" / "DEPLOYMENT.md"
    if deployment_doc.exists():
        shutil.copy2(str(deployment_doc), str(project_path / "docs" / "DEPLOYMENT.md"))

    # Security scripts travel with the project (CI runners have no ~/.claude)
    security_src = FRAMEWORK_DIR / "scripts" / "security"
    if security_src.exists():
        for sec_file in security_src.iterdir():
            if sec_file.is_file():
                shutil.copy2(str(sec_file), str(project_path / "scripts" / "security" / sec_file.name))

    # Copy rules (common + stack-specific)
    rules_src = FRAMEWORK_DIR / "rules"
    if rules_src.exists():
        rules_dst = project_path / ".claude" / "rules"
        # Always copy common rules
        common_rules = rules_src / "common"
        if common_rules.exists():
            _copy_dir(common_rules, rules_dst / "common")
        # Copy stack-specific rules
        for stack_name in [backend, frontend]:
            stack_rules = rules_src / stack_name
            if stack_rules.exists():
                _copy_dir(stack_rules, rules_dst / stack_name)

    # Copy project templates (coverage contracts: acceptance is 100%, always)
    templates_src = FRAMEWORK_DIR / "templates" / "project"
    if templates_src.exists():
        backend_toml = templates_src / "backend-pyproject.toml"
        if backend_toml.exists():
            shutil.copy2(str(backend_toml), str(project_path / "backend" / "pyproject.toml"))
        vitest_cfg = templates_src / "frontend-vitest.config.ts"
        if vitest_cfg.exists():
            shutil.copy2(str(vitest_cfg), str(project_path / "frontend" / "vitest.config.ts"))

    # Generate CLAUDE.md that references global install
    claude_md = f"""# CLAUDE.md - {project_name}

## RedWork Framework (global install)

This project uses RedWork Framework v{VERSION} installed at ~/.claude/redwork/.
Agents, skills, and scripts are NOT local - they live globally.

## Agent Sequence

```
DISCOVERY:  01 -> 02 -> 03 -> 04 [-> 04b] -> 05 [-> 05b]
PLANNING:   06 -> 07 -> 08 -> 09
API:        10 -> 11
INFRA:      12
BACKEND:    13(test) -> 14(impl)
FRONTEND:   15(test) -> 16(impl)
VALIDATION: 17 -> 18 -> 19 -> 20 -> 21
QUALITY:    22 -> 23 -> 24
```

## Stack

- Backend: {backend}
- Frontend: {frontend}

## Rules

See `.claude/rules/` for modular rules (common + stack-specific).
Rules are auto-distributed on `install.py init` based on declared stack.

## TDD Mandate

Tests FIRST (agents 13/15), implementation AFTER (agents 14/16).
"""
    (project_path / "CLAUDE.md").write_text(claude_md, encoding="utf-8")

    # Generate .claude/settings.json (local, inherits global hooks)
    local_settings = {
        "hooks": {
            "SessionStart": [
                {
                    "matcher": "startup|resume|compact",
                    "hooks": [
                        {
                            "type": "command",
                            "command": "bash ~/.claude/hooks/session-start.sh",
                            "timeout": 10
                        }
                    ]
                }
            ]
        }
    }
    with open(project_path / ".claude" / "settings.json", "w") as f:
        json.dump(local_settings, f, indent=2)

    # Generate .gitignore
    gitignore = """# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local

# Build
dist/
build/
*.log

# Testing
coverage/
.pytest_cache/

# Learning data
.learning/

# RedWork local state (per-machine; never merged between developers)
.project-state/
.project-orchestration/
"""
    (project_path / ".gitignore").write_text(gitignore, encoding="utf-8")

    # Initialize state.json
    sys.path.insert(0, str(FRAMEWORK_DIR))
    from scripts.lib.state_manager import StateManager
    sm = StateManager(str(project_path))
    sm.initialize(project_name, {"backend": backend, "frontend": frontend})

    # Git init
    os.chdir(str(project_path))
    subprocess.run(["git", "init"], capture_output=True)
    subprocess.run(["git", "add", "."], capture_output=True)
    subprocess.run(
        ["git", "commit", "-m", f"feat: Initialize {project_name} with RedWork v{VERSION}"],
        capture_output=True
    )

    print(f"\nProject initialized: {project_path}")
    print(f"\nNext steps:")
    print(f"  cd {project_path}")
    print(f"  git remote add origin <gitlab-url>")
    print(f"  git push -u origin main")
    print(f"  # Then in Claude Code:")
    print(f'  "lanza el agente 01-product-discovery quiero un [IDEA]"')


# ============================================================================
# STATUS
# ============================================================================

def cmd_status(args):
    state_file = GLOBAL_ROOT / "install-state.json"
    if not state_file.exists():
        print("RedWork is NOT installed.")
        print(f"Run: python install.py install")
        return

    with open(state_file) as f:
        state = json.load(f)

    print(f"RedWork v{state.get('version', '?')}")
    print(f"  Profile: {state.get('profile', '?')}")
    print(f"  Installed: {state.get('installed_at', '?')}")
    print(f"  Updated: {state.get('updated_at', '?')}")
    print(f"  Files: {state.get('files_count', '?')}")
    print(f"  Location: {GLOBAL_ROOT}")

    agents_count = len(list((GLOBAL_ROOT / "agents").glob("*.md"))) if (GLOBAL_ROOT / "agents").exists() else 0
    skills_count = len(list((GLOBAL_ROOT / "skills").glob("*.md"))) if (GLOBAL_ROOT / "skills").exists() else 0
    print(f"  Agents: {agents_count}")
    print(f"  Skills: {skills_count}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    parser = argparse.ArgumentParser(description="RedWork Framework Installer")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # install
    p_install = subparsers.add_parser("install", help="Install RedWork globally")
    p_install.add_argument("--profile", choices=["full", "backend-only", "frontend-only"], default="full")

    # update
    subparsers.add_parser("update", help="Update to latest version")

    # uninstall
    subparsers.add_parser("uninstall", help="Remove global installation")

    # init
    p_init = subparsers.add_parser("init", help="Initialize a new project")
    p_init.add_argument("project_name", help="Name of the project")
    p_init.add_argument("--backend", choices=["fastapi"], default="fastapi")
    p_init.add_argument("--frontend", choices=["react"], default="react")

    # status
    subparsers.add_parser("status", help="Show installation status")

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(1)

    commands = {
        "install": cmd_install,
        "update": cmd_update,
        "uninstall": cmd_uninstall,
        "init": cmd_init,
        "status": cmd_status,
    }

    commands[args.command](args)


if __name__ == "__main__":
    main()
