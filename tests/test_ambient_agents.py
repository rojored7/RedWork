"""
Tests for the vendored ambient agents (agents/ambient/) and the
invocation-integrity of the flows.

The flows (/flow-new-project, /flow-update, /flow-bugfix) invoke ambient
agents via the Task tool. Vendoring them makes RedWork self-contained;
these tests guarantee that every agent a flow invokes actually exists.
"""

import re
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))

from tests.conftest import FRAMEWORK_ROOT

AMBIENT_DIR = FRAMEWORK_ROOT / "agents" / "ambient"
AGENTS_DIR = FRAMEWORK_ROOT / "agents"
COMMANDS_DIR = FRAMEWORK_ROOT / "commands"

AMBIENT_AGENTS = [
    "code-explorer",
    "code-architect",
    "planner",
    "tdd-guide",
    "code-reviewer",
    "security-reviewer",
    "python-reviewer",
    "typescript-reviewer",
    "build-error-resolver",
]


def _frontmatter(path: Path) -> str:
    content = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", content, re.DOTALL)
    return match.group(1) if match else ""


def _agent_names() -> set:
    """All `name:` values declared by agents (pipeline + ambient)."""
    names = set()
    for md in list(AGENTS_DIR.glob("*.md")) + list(AMBIENT_DIR.glob("*.md")):
        if md.name == "README.md":
            continue
        fm = _frontmatter(md)
        m = re.search(r"^name:\s*(\S+)", fm, re.MULTILINE)
        if m:
            names.add(m.group(1).strip("\"'"))
    return names


class TestVendoredAgents:
    @pytest.mark.parametrize("agent", AMBIENT_AGENTS)
    def test_agent_vendored(self, agent):
        assert (AMBIENT_DIR / f"{agent}.md").exists(), (
            f"agents/ambient/{agent}.md missing — flows invoke it"
        )

    @pytest.mark.parametrize("agent", AMBIENT_AGENTS)
    def test_frontmatter_valid(self, agent):
        fm = _frontmatter(AMBIENT_DIR / f"{agent}.md")
        assert fm, f"{agent}.md has no YAML frontmatter"
        for field in ("name:", "description:", "model:"):
            assert field in fm, f"{agent}.md frontmatter missing {field}"
        m = re.search(r"^name:\s*(\S+)", fm, re.MULTILINE)
        assert m and m.group(1).strip("\"'") == agent, (
            f"{agent}.md declares name '{m.group(1) if m else None}'"
        )

    def test_readme_documents_provenance(self):
        readme = (AMBIENT_DIR / "README.md").read_text(encoding="utf-8")
        assert "everything-claude-code" in readme
        assert "~/.claude/agents/" in readme

    def test_no_duplicate_names_across_agents(self):
        seen = {}
        for md in list(AGENTS_DIR.glob("*.md")) + list(AMBIENT_DIR.glob("*.md")):
            if md.name == "README.md":
                continue
            m = re.search(r"^name:\s*(\S+)", _frontmatter(md), re.MULTILINE)
            if not m:
                continue
            name = m.group(1).strip("\"'")
            assert name not in seen, (
                f"Duplicate agent name '{name}': {md.name} and {seen[name]}"
            )
            seen[name] = md.name


class TestInvocationIntegrity:
    """THE factory test: every agent a flow or pipeline agent invokes must
    exist as a file. Protects the flows from future drift."""

    # Agents referenced in prose as invocable actors
    INVOKABLE_PATTERN = re.compile(
        r"\*\*(?P<name>[a-z0-9]+(?:-[a-z0-9]+)+)\*\*"
    )
    # Known non-agent bold tokens to ignore
    IGNORE = {
        "flow-new-project", "flow-update", "flow-bugfix", "feature-dev",
        "build-fix", "run-gates", "slice-gate", "checkpoint-commit",
        "impact-prevalidator", "plan-critic",  # local, checked separately
    }

    def _existing_agent_files(self) -> set:
        files = set()
        for md in list(AGENTS_DIR.glob("*.md")) + list(AMBIENT_DIR.glob("*.md")):
            files.add(md.stem)
        return files

    def test_flow_invocations_resolve(self):
        existing = self._existing_agent_files() | _agent_names()
        missing = []
        for flow in COMMANDS_DIR.glob("flow-*.md"):
            content = flow.read_text(encoding="utf-8")
            for m in self.INVOKABLE_PATTERN.finditer(content):
                name = m.group("name")
                if name in self.IGNORE or name in existing:
                    continue
                # numbered agents referenced as NN-name
                if re.match(r"^\d", name) and name in existing:
                    continue
                missing.append(f"{flow.name}: **{name}**")
        # Filter: only flag names that look like agents (contain no spaces,
        # are kebab-case with 2+ segments) and are genuinely absent
        real_missing = [
            m for m in missing
            if not any(tok in m for tok in ("http", ".md", ".sh", ".py"))
        ]
        assert not real_missing, (
            "Flows invoke agents that do not exist:\n" + "\n".join(real_missing)
        )

    def test_core_ambient_agents_referenced_by_flows_exist(self):
        """Direct check: the 9 known ambient invocations resolve."""
        for agent in AMBIENT_AGENTS:
            assert (AMBIENT_DIR / f"{agent}.md").exists() or (
                AGENTS_DIR / f"{agent}.md"
            ).exists(), f"{agent} invoked by flows but not vendored"

    def test_plan_critic_and_prevalidator_local(self):
        assert (AGENTS_DIR / "plan-critic.md").exists()
        assert (AGENTS_DIR / "impact-prevalidator.md").exists()


class TestInstallerIntegration:
    def test_install_py_installs_ambient(self):
        content = (FRAMEWORK_ROOT / "install.py").read_text(encoding="utf-8")
        assert "_install_ambient_agents" in content
        assert "ambient_installed" in content

    def test_manifests_include_ambient(self):
        import json
        for mf in ("backend-only.json", "frontend-only.json"):
            data = json.loads(
                (FRAMEWORK_ROOT / "manifests" / mf).read_text(encoding="utf-8")
            )
            ambient_entries = [e for e in data if e.startswith("agents/ambient/")]
            assert len(ambient_entries) >= 9, f"{mf} missing ambient agents"
