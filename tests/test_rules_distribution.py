"""
Tests for the modular rules system.

Validates:
- Rules directory structure exists with all expected files
- Frontmatter in each rule file is valid YAML with required fields
- install.py copies rules to global installation
- install.py init copies common + stack-specific rules to projects
"""

import subprocess
import sys
from pathlib import Path

import pytest
import yaml

from conftest import FRAMEWORK_ROOT, to_posix

RULES_DIR = FRAMEWORK_ROOT / "rules"
COMMON_RULES = ["framework-rules.md", "tdd-rules.md", "agent-sequence-rules.md"]
STACK_DIRS = ["fastapi", "react"]
VALID_APPLIES_TO = {"all", "fastapi", "react"}
VALID_PHASES = {"always", "discovery", "planning", "development", "validation"}
VALID_ENFORCEMENT = {"hook", "convention", "ci"}


# ============================================================================
# DIRECTORY STRUCTURE
# ============================================================================

class TestRulesDirectoryExists:

    def test_rules_directory_exists(self):
        assert RULES_DIR.exists(), "rules/ directory must exist in framework root"

    def test_common_directory_exists(self):
        assert (RULES_DIR / "common").exists(), "rules/common/ must exist"

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_directory_exists(self, stack):
        assert (RULES_DIR / stack).exists(), f"rules/{stack}/ must exist"


# ============================================================================
# COMMON RULES FILES
# ============================================================================

class TestCommonRulesPresent:

    @pytest.mark.parametrize("filename", COMMON_RULES)
    def test_common_rule_file_exists(self, filename):
        path = RULES_DIR / "common" / filename
        assert path.exists(), f"rules/common/{filename} must exist"

    @pytest.mark.parametrize("filename", COMMON_RULES)
    def test_common_rule_not_empty(self, filename):
        path = RULES_DIR / "common" / filename
        content = path.read_text(encoding="utf-8")
        assert len(content.strip()) > 50, f"{filename} should have substantial content"


# ============================================================================
# STACK RULES FILES
# ============================================================================

class TestStackRulesPresent:

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_rules_file_exists(self, stack):
        path = RULES_DIR / stack / "stack-rules.md"
        assert path.exists(), f"rules/{stack}/stack-rules.md must exist"

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_rules_not_empty(self, stack):
        path = RULES_DIR / stack / "stack-rules.md"
        content = path.read_text(encoding="utf-8")
        assert len(content.strip()) > 50, f"{stack}/stack-rules.md should have content"


# ============================================================================
# FRONTMATTER VALIDATION
# ============================================================================

def _all_rule_files():
    """Collect all .md rule files for parametrized tests."""
    files = []
    for md in RULES_DIR.rglob("*.md"):
        rel = md.relative_to(RULES_DIR)
        files.append(str(rel))
    return files


def _parse_frontmatter(path: Path) -> dict:
    """Extract YAML frontmatter from a markdown file."""
    content = path.read_text(encoding="utf-8")
    if not content.startswith("---"):
        return {}
    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}
    return yaml.safe_load(parts[1]) or {}


class TestFrontmatterValid:

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_is_valid_yaml(self, rel_path):
        path = RULES_DIR / rel_path
        fm = _parse_frontmatter(path)
        assert isinstance(fm, dict), f"{rel_path} frontmatter must be valid YAML dict"

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_has_rule_id(self, rel_path):
        fm = _parse_frontmatter(RULES_DIR / rel_path)
        assert "rule_id" in fm, f"{rel_path} must have rule_id in frontmatter"

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_has_applies_to(self, rel_path):
        fm = _parse_frontmatter(RULES_DIR / rel_path)
        assert fm.get("applies_to") in VALID_APPLIES_TO, \
            f"{rel_path} applies_to must be one of {VALID_APPLIES_TO}"

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_has_phase(self, rel_path):
        fm = _parse_frontmatter(RULES_DIR / rel_path)
        assert fm.get("phase") in VALID_PHASES, \
            f"{rel_path} phase must be one of {VALID_PHASES}"

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_has_enforcement(self, rel_path):
        fm = _parse_frontmatter(RULES_DIR / rel_path)
        assert fm.get("enforcement") in VALID_ENFORCEMENT, \
            f"{rel_path} enforcement must be one of {VALID_ENFORCEMENT}"

    @pytest.mark.parametrize("rel_path", _all_rule_files())
    def test_frontmatter_has_version(self, rel_path):
        fm = _parse_frontmatter(RULES_DIR / rel_path)
        assert "version" in fm, f"{rel_path} must have version in frontmatter"


# ============================================================================
# INSTALL COPIES RULES TO GLOBAL
# ============================================================================

class TestInstallCopiesRules:

    def test_install_py_references_rules(self):
        """install.py must contain rules copy logic."""
        install_py = FRAMEWORK_ROOT / "install.py"
        content = install_py.read_text(encoding="utf-8")
        assert "Copying rules" in content, "install.py must copy rules on install"

    def test_init_copies_rules(self):
        """install.py init must contain rules distribution logic."""
        install_py = FRAMEWORK_ROOT / "install.py"
        content = install_py.read_text(encoding="utf-8")
        assert "Copy rules" in content, "install.py init must copy rules to projects"


# ============================================================================
# STACK CONFIG REFERENCES RULES
# ============================================================================

class TestStackConfigReferencesRules:

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_config_has_rules_field(self, stack):
        config_path = FRAMEWORK_ROOT / "stacks" / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        assert "rules" in config, f"stacks/{stack}/config.yaml must have 'rules' field"

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_config_rules_include_common(self, stack):
        config_path = FRAMEWORK_ROOT / "stacks" / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        rules = config.get("rules", [])
        common_refs = [r for r in rules if r.startswith("common/")]
        assert len(common_refs) == 3, \
            f"stacks/{stack}/config.yaml must reference all 3 common rules"

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_config_rules_include_own_stack(self, stack):
        config_path = FRAMEWORK_ROOT / "stacks" / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        rules = config.get("rules", [])
        stack_refs = [r for r in rules if r.startswith(f"{stack}/")]
        assert len(stack_refs) >= 1, \
            f"stacks/{stack}/config.yaml must reference its own stack rules"

    @pytest.mark.parametrize("stack", STACK_DIRS)
    def test_stack_config_rules_all_files_exist(self, stack):
        config_path = FRAMEWORK_ROOT / "stacks" / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        for rule_ref in config.get("rules", []):
            rule_path = RULES_DIR / rule_ref
            assert rule_path.exists(), \
                f"Rule referenced in {stack}/config.yaml does not exist: {rule_ref}"


# ============================================================================
# CLAUDE.MD REFERENCES RULES
# ============================================================================

class TestClaudeMdReferencesRules:

    def test_claude_md_references_rules_dir(self):
        claude_md = FRAMEWORK_ROOT / "CLAUDE.md"
        content = claude_md.read_text(encoding="utf-8")
        assert "rules/" in content, "CLAUDE.md must reference rules/ directory"

    def test_claude_md_no_embedded_numbered_rules(self):
        """Embedded numbered rules should have been replaced with reference."""
        claude_md = FRAMEWORK_ROOT / "CLAUDE.md"
        content = claude_md.read_text(encoding="utf-8")
        assert "1. **No emojis**" not in content, \
            "CLAUDE.md should not have embedded numbered rules (moved to rules/)"


# ============================================================================
# INIT CREATES CORRECT RULES IN PROJECT
# ============================================================================

class TestInitRulesDistribution:

    def test_init_creates_rules_for_fastapi_react(self, tmp_path):
        """Simulate what init does: copy common + fastapi + react rules."""
        rules_dst = tmp_path / ".claude" / "rules"

        # Simulate the copy logic from install.py
        from install import _copy_dir
        rules_src = FRAMEWORK_ROOT / "rules"

        common_src = rules_src / "common"
        if common_src.exists():
            _copy_dir(common_src, rules_dst / "common")

        for stack_name in ["fastapi", "react"]:
            stack_src = rules_src / stack_name
            if stack_src.exists():
                _copy_dir(stack_src, rules_dst / stack_name)

        # Verify common rules copied
        for rule_file in COMMON_RULES:
            assert (rules_dst / "common" / rule_file).exists()

        # Verify fastapi rules copied
        assert (rules_dst / "fastapi" / "stack-rules.md").exists()

        # Verify react rules copied
        assert (rules_dst / "react" / "stack-rules.md").exists()

        # Verify django/vue NOT copied
        assert not (rules_dst / "django").exists()
        assert not (rules_dst / "vue").exists()

    def test_unsupported_stack_rules_removed(self):
        """django/vue scaffolding was pruned in v2.3 (FastAPI+React only)."""
        rules_src = FRAMEWORK_ROOT / "rules"
        assert not (rules_src / "django").exists()
        assert not (rules_src / "vue").exists()
