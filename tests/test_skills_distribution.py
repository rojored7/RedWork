"""
Tests for stack-specific skills organization.

Validates:
- Generic skills remain at root
- Stack-specific skills exist in their directories
- Stack configs reference applicable skills
- All referenced skill files exist
"""

from pathlib import Path

import pytest
import yaml

from conftest import FRAMEWORK_ROOT

SKILLS_DIR = FRAMEWORK_ROOT / "skills"
STACKS_DIR = FRAMEWORK_ROOT / "stacks"

GENERIC_SKILLS = [
    "api-dx-design.md",
    "configuration-management.md",
    "ddd-clean-architecture.md",
    "openapi-code-generation.md",
    "security-best-practices.md",
    "testing-patterns.md",
]

FASTAPI_SKILLS = ["patterns.md", "testing.md", "security.md"]
DJANGO_SKILLS = ["patterns.md", "testing.md", "orm-ddd.md"]
VUE_SKILLS = ["component-patterns.md", "state-management.md"]
REACT_SKILLS = [
    "component-patterns.md", "state-management.md", "performance.md",
    "accessibility.md", "api-client.md", "typescript-quality.md",
    "ux-design-system.md",
]


# ============================================================================
# GENERIC SKILLS AT ROOT
# ============================================================================

class TestGenericSkillsAtRoot:

    @pytest.mark.parametrize("filename", GENERIC_SKILLS)
    def test_generic_skill_exists(self, filename):
        assert (SKILLS_DIR / filename).exists(), f"skills/{filename} must exist"


# ============================================================================
# STACK-SPECIFIC SKILLS
# ============================================================================

class TestFastAPISkills:

    @pytest.mark.parametrize("filename", FASTAPI_SKILLS)
    def test_skill_exists(self, filename):
        assert (SKILLS_DIR / "fastapi" / filename).exists()

    @pytest.mark.parametrize("filename", FASTAPI_SKILLS)
    def test_skill_not_empty(self, filename):
        content = (SKILLS_DIR / "fastapi" / filename).read_text(encoding="utf-8")
        assert len(content) > 100


class TestDjangoSkills:

    @pytest.mark.parametrize("filename", DJANGO_SKILLS)
    def test_skill_exists(self, filename):
        assert (SKILLS_DIR / "django" / filename).exists()

    @pytest.mark.parametrize("filename", DJANGO_SKILLS)
    def test_skill_not_empty(self, filename):
        content = (SKILLS_DIR / "django" / filename).read_text(encoding="utf-8")
        assert len(content) > 100


class TestVueSkills:

    @pytest.mark.parametrize("filename", VUE_SKILLS)
    def test_skill_exists(self, filename):
        assert (SKILLS_DIR / "vue" / filename).exists()

    @pytest.mark.parametrize("filename", VUE_SKILLS)
    def test_skill_not_empty(self, filename):
        content = (SKILLS_DIR / "vue" / filename).read_text(encoding="utf-8")
        assert len(content) > 100


class TestReactSkills:

    @pytest.mark.parametrize("filename", REACT_SKILLS)
    def test_skill_exists(self, filename):
        assert (SKILLS_DIR / "react" / filename).exists()


# ============================================================================
# STACK CONFIGS REFERENCE SKILLS
# ============================================================================

class TestStackConfigSkills:

    @pytest.mark.parametrize("stack", ["fastapi", "django", "react", "vue"])
    def test_config_has_applicable_skills(self, stack):
        config_path = STACKS_DIR / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        assert "applicable_skills" in config, \
            f"stacks/{stack}/config.yaml must have applicable_skills"

    @pytest.mark.parametrize("stack", ["fastapi", "django", "react", "vue"])
    def test_all_referenced_skills_exist(self, stack):
        config_path = STACKS_DIR / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        for skill_ref in config.get("applicable_skills", []):
            skill_path = SKILLS_DIR / skill_ref
            assert skill_path.exists(), \
                f"Skill '{skill_ref}' referenced in {stack}/config.yaml does not exist"

    @pytest.mark.parametrize("stack", ["fastapi", "django", "react", "vue"])
    def test_has_at_least_3_skills(self, stack):
        config_path = STACKS_DIR / stack / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        skills = config.get("applicable_skills", [])
        assert len(skills) >= 3, f"{stack} should have at least 3 applicable skills"

    def test_fastapi_has_stack_specific_skills(self):
        config_path = STACKS_DIR / "fastapi" / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        skills = config.get("applicable_skills", [])
        fastapi_skills = [s for s in skills if s.startswith("fastapi/")]
        assert len(fastapi_skills) >= 3

    def test_django_has_stack_specific_skills(self):
        config_path = STACKS_DIR / "django" / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        skills = config.get("applicable_skills", [])
        django_skills = [s for s in skills if s.startswith("django/")]
        assert len(django_skills) >= 3

    def test_vue_has_stack_specific_skills(self):
        config_path = STACKS_DIR / "vue" / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        skills = config.get("applicable_skills", [])
        vue_skills = [s for s in skills if s.startswith("vue/")]
        assert len(vue_skills) >= 2

    def test_react_has_stack_specific_skills(self):
        config_path = STACKS_DIR / "react" / "config.yaml"
        with open(config_path) as f:
            config = yaml.safe_load(f)
        skills = config.get("applicable_skills", [])
        react_skills = [s for s in skills if s.startswith("react/")]
        assert len(react_skills) >= 5
