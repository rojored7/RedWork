"""
Level 2 Execution Audit: Test each Claude Code hook individually.

Runs hooks via subprocess (not through Claude's Bash tool) to avoid
the live hooks intercepting the test commands themselves.
"""

import subprocess
import json
import pytest
from pathlib import Path

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()


def run_hook(hook_name: str, input_json: str) -> tuple:
    """Run a hook script with JSON input via stdin. Returns (exit_code, stdout, stderr)."""
    hook_path = FRAMEWORK_ROOT / ".claude" / "hooks" / hook_name
    result = subprocess.run(
        ["bash", str(hook_path)],
        input=input_json,
        capture_output=True,
        text=True,
        timeout=10,
        cwd=str(FRAMEWORK_ROOT),
    )
    return result.returncode, result.stdout, result.stderr


class TestPreWriteValidateHook:
    HOOK = "pre-write-validate.sh"

    def test_blocks_ts_in_backend(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/app.ts", "content": "const x = 1;"}
        }))
        assert code == 2, f"Expected block (exit 2), got {code}"
        assert "BLOCKED" in err

    def test_allows_py_in_backend(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/main.py", "content": "from fastapi import FastAPI"}
        }))
        assert code == 0, f"Expected allow (exit 0), got {code}: {err}"

    def test_blocks_nestjs_in_package_json(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/package.json", "content": '{"dependencies":{"@nestjs/core":"^10"}}'}
        }))
        assert code == 2
        assert "BLOCKED" in err

    def test_blocks_direct_project_state_edit(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": ".project-state/state.json", "content": "{}"}
        }))
        assert code == 2
        assert "auto-commit-task" in err

    def test_blocks_direct_git_hooks_edit(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": ".git/hooks/pre-commit", "content": "#!/bin/bash"}
        }))
        assert code == 2
        assert "install-workflow-hooks" in err

    def test_allows_frontend_tsx(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "frontend/src/App.tsx", "content": "export default function App() {}"}
        }))
        assert code == 0

    def test_blocks_nest_cli_json(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/nest-cli.json", "content": "{}"}
        }))
        assert code == 2

    def test_blocks_pom_xml(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "backend/pom.xml", "content": "<project></project>"}
        }))
        assert code == 2

    def test_allows_outputs_md(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Write",
            "tool_input": {"file_path": "outputs/01_product_discovery.md", "content": "# Discovery"}
        }))
        assert code == 0


class TestPreBashValidateHook:
    HOOK = "pre-bash-validate.sh"

    def test_blocks_force_push_main(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "git push --force origin main"}
        }))
        assert code == 2
        assert "BLOCKED" in err

    def test_blocks_npm_install_nestjs(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "npm install @nestjs/core"}
        }))
        assert code == 2

    def test_blocks_rm_rf_project_state(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "rm -rf .project-state"}
        }))
        assert code == 2

    def test_blocks_git_reset_hard(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "git reset --hard HEAD~1"}
        }))
        assert code == 2

    def test_allows_pytest(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "python -m pytest tests/ -v"}
        }))
        assert code == 0

    def test_allows_ls(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "ls -la"}
        }))
        assert code == 0

    def test_allows_git_status(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "git status"}
        }))
        assert code == 0

    def test_blocks_yarn_add_nestjs(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "yarn add @nestjs/common"}
        }))
        assert code == 2

    def test_blocks_rm_rf_framework(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "tool_name": "Bash",
            "tool_input": {"command": "rm -rf .framework"}
        }))
        assert code == 2


class TestSessionStartHook:
    HOOK = "session-start.sh"

    def test_produces_json_output(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "cwd": str(FRAMEWORK_ROOT),
            "hook_event_name": "SessionStart",
        }))
        assert code == 0, f"Hook failed: {err}"
        # Should produce JSON with additionalContext
        assert "additionalContext" in out or "REDWORK" in out, f"No context in output: {out[:200]}"

    def test_detects_framework_repo_mode(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "cwd": str(FRAMEWORK_ROOT),
        }))
        assert code == 0
        assert "framework-repo" in out or "Mode" in out


class TestOnStopHook:
    HOOK = "on-stop.sh"

    def test_runs_without_error(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "cwd": str(FRAMEWORK_ROOT),
        }))
        assert code == 0, f"on-stop failed: {err}"


class TestPreCompactHook:
    HOOK = "pre-compact.sh"

    def test_runs_without_error(self):
        code, out, err = run_hook(self.HOOK, json.dumps({
            "cwd": str(FRAMEWORK_ROOT),
        }))
        assert code == 0, f"pre-compact failed: {err}"
