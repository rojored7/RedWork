"""
Tests for NestJS contamination validation.

Validates that framework agent documents maintain FastAPI mandate
and do not contain NestJS/Express/Spring references.
"""

import subprocess
from pathlib import Path

import pytest

from conftest import FRAMEWORK_ROOT, to_posix

VALIDATOR = FRAMEWORK_ROOT / "scripts" / "workflow" / "validate-no-nestjs-contamination.sh"

CRITICAL_AGENT_FILES = [
    "agents/04-architecture-decision.md",
    "agents/10-api-specification.md",
    "agents/14-backend-development.md",
]

FORBIDDEN_PATTERNS = [
    "NestJS",
    "@nestjs",
    "class-validator",
    "@Injectable",
    "@UseGuards",
    "NestFactory",
    "INestApplication",
]


class TestValidatorExists:

    def test_validator_script_exists(self):
        assert VALIDATOR.exists()

    def test_validator_is_bash_script(self):
        content = VALIDATOR.read_text(encoding="utf-8")
        assert content.startswith("#!/bin/bash")


class TestCriticalFilesClean:

    @pytest.mark.parametrize("agent_file", CRITICAL_AGENT_FILES)
    def test_agent_file_exists(self, agent_file):
        path = FRAMEWORK_ROOT / agent_file
        assert path.exists(), f"{agent_file} must exist"

    @pytest.mark.parametrize("agent_file", CRITICAL_AGENT_FILES)
    def test_no_nestjs_in_agent(self, agent_file):
        content = (FRAMEWORK_ROOT / agent_file).read_text(encoding="utf-8")
        for pattern in FORBIDDEN_PATTERNS:
            if pattern in content:
                # Allow if it's in a "forbidden" or "prohibited" context
                lines = content.splitlines()
                for line in lines:
                    if pattern in line:
                        lower = line.lower()
                        if not any(w in lower for w in ["forbidden", "prohibited",
                                                         "never", "must not", "do not",
                                                         "blocked", "ban"]):
                            pytest.fail(
                                f"Found '{pattern}' in {agent_file} outside "
                                f"prohibition context: {line.strip()}"
                            )


class TestFastAPIMandatePresent:

    def test_architecture_agent_has_fastapi_mandate(self):
        path = FRAMEWORK_ROOT / "agents" / "04-architecture-decision.md"
        if path.exists():
            content = path.read_text(encoding="utf-8")
            assert "FastAPI" in content, "Agent 04 must mention FastAPI"

    def test_backend_agent_has_fastapi_mandate(self):
        path = FRAMEWORK_ROOT / "agents" / "14-backend-development.md"
        if path.exists():
            content = path.read_text(encoding="utf-8")
            assert "FastAPI" in content, "Agent 14 must mention FastAPI"


class TestSkillsClean:

    def test_security_skill_no_nestjs(self):
        path = FRAMEWORK_ROOT / "skills" / "security-best-practices.md"
        if path.exists():
            content = path.read_text(encoding="utf-8")
            for pattern in ["@nestjs", "NestFactory", "INestApplication"]:
                assert pattern not in content, \
                    f"Security skill should not contain {pattern}"

    def test_config_skill_no_nestjs(self):
        path = FRAMEWORK_ROOT / "skills" / "configuration-management.md"
        if path.exists():
            content = path.read_text(encoding="utf-8")
            for pattern in ["@nestjs", "NestFactory"]:
                assert pattern not in content
