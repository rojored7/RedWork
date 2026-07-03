"""
Reference integrity of the content layer (agents, skills, commands, docs).

Guards against the drift class found in the v2.2 audit: phantom paths,
stale v1 agent numbering, duplicate agent names, dead subsystems and
skill references that do not resolve.
"""

import hashlib
import re
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent))

from tests.conftest import FRAMEWORK_ROOT

AGENTS = FRAMEWORK_ROOT / "agents"
SKILLS = FRAMEWORK_ROOT / "skills"
COMMANDS = FRAMEWORK_ROOT / "commands"


def _agent_files():
    for md in list(AGENTS.glob("*.md")) + list((AGENTS / "ambient").glob("*.md")):
        if md.name != "README.md":
            yield md


def _frontmatter(path: Path) -> str:
    match = re.match(
        r"^---\n(.*?)\n---\n", path.read_text(encoding="utf-8"), re.DOTALL
    )
    return match.group(1) if match else ""


class TestSweepCheck:
    def test_sweep_references_check_passes(self):
        result = subprocess.run(
            [sys.executable, "scripts/maintenance/sweep_references.py", "--check"],
            cwd=str(FRAMEWORK_ROOT),
            capture_output=True,
            text=True,
            timeout=120,
        )
        assert result.returncode == 0, (
            f"sweep_references --check failed:\n{result.stdout}"
        )


class TestAgentNames:
    def test_every_agent_has_frontmatter_name(self):
        missing = [
            md.name for md in _agent_files()
            if not re.search(r"^name:\s*\S+", _frontmatter(md), re.MULTILINE)
        ]
        assert not missing, f"Agents without frontmatter name: {missing}"

    def test_names_are_kebab_lowercase_and_match_filename(self):
        bad = []
        for md in _agent_files():
            m = re.search(r"^name:\s*(\S+)", _frontmatter(md), re.MULTILINE)
            name = m.group(1).strip("\"'")
            if name != name.lower() or name != md.stem:
                bad.append(f"{md.name}: name={name}")
        assert not bad, f"Non-canonical agent names: {bad}"

    def test_names_unique(self):
        seen = {}
        for md in _agent_files():
            m = re.search(r"^name:\s*(\S+)", _frontmatter(md), re.MULTILINE)
            name = m.group(1).strip("\"'")
            assert name not in seen, f"Duplicate: {name} in {md.name} and {seen[name]}"
            seen[name] = md.name


class TestSkillReferences:
    SKILL_REF = re.compile(r"~/\.claude/redwork/(skills/[A-Za-z0-9/_-]+\.md)")

    def test_referenced_skills_exist(self):
        missing = []
        for md in list(_agent_files()) + list(COMMANDS.glob("*.md")):
            for m in self.SKILL_REF.finditer(md.read_text(encoding="utf-8")):
                rel = m.group(1)
                if not (FRAMEWORK_ROOT / rel).exists():
                    missing.append(f"{md.name} -> {rel}")
        assert not missing, "Dangling skill references:\n" + "\n".join(missing)

    def test_no_duplicate_skills_by_hash(self):
        hashes = {}
        dupes = []
        for skill in SKILLS.rglob("*.md"):
            if skill.name == "README.md":
                continue
            digest = hashlib.sha256(skill.read_bytes()).hexdigest()
            if digest in hashes:
                dupes.append(f"{skill.relative_to(SKILLS)} == {hashes[digest]}")
            else:
                hashes[digest] = str(skill.relative_to(SKILLS))
        assert not dupes, "Byte-identical duplicate skills:\n" + "\n".join(dupes)


class TestOutputConventions:
    OUTPUT_DECL = re.compile(r"outputs/(\d{2}b?)_[a-z0-9_]+\.(md|yaml|json)")

    def test_numbered_outputs_match_agent_numbers(self):
        """An agent NN-*.md must not declare another agent's numbered output
        as its own primary artifact (the v2.2 audit found agent 13 writing
        10_backend_test_report.md)."""
        mismatches = []
        for md in AGENTS.glob("[0-9]*.md"):
            agent_num = re.match(r"^(\d{2}b?)", md.stem).group(1)
            content = md.read_text(encoding="utf-8")
            # Only check declared *report/output of this agent* lines
            for line in content.splitlines():
                if "outputs/" in line and ("Output" in line or "produce" in line.lower()):
                    for m in self.OUTPUT_DECL.finditer(line):
                        if m.group(1) not in (agent_num,):
                            # referencing other agents' outputs as INPUT is fine;
                            # flag only "must produce" style lines
                            if re.search(r"(you (must )?produce|emite|escribe|Output:)", line, re.IGNORECASE):
                                mismatches.append(f"{md.name}: {line.strip()[:90]}")
        assert not mismatches, "\n".join(mismatches)
