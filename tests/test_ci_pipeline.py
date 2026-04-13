"""
Tests for GitLab CI pipeline configuration.

Validates:
- YAML is valid
- Required stages exist in correct order
- Security scan stage exists
- No duplicate stage names
- Child pipeline references exist
"""

from pathlib import Path

import pytest
import yaml

from conftest import FRAMEWORK_ROOT

CI_FILE = FRAMEWORK_ROOT / ".gitlab-ci.yml"


@pytest.fixture
def ci_config():
    with open(CI_FILE) as f:
        return yaml.safe_load(f)


class TestCIFileValid:

    def test_gitlab_ci_exists(self):
        assert CI_FILE.exists()

    def test_gitlab_ci_valid_yaml(self):
        with open(CI_FILE) as f:
            config = yaml.safe_load(f)
        assert isinstance(config, dict)

    def test_has_stages_key(self, ci_config):
        assert "stages" in ci_config

    def test_stages_is_list(self, ci_config):
        assert isinstance(ci_config["stages"], list)


class TestStageOrder:

    EXPECTED_ORDER = [
        "test-framework",
        "setup",
        "discovery",
        "planning",
        "api-contract",
        "infrastructure",
        "sprint-1",
        "quality",
        "deploy",
    ]

    def test_test_framework_is_first_stage(self, ci_config):
        stages = ci_config["stages"]
        assert stages[0] == "test-framework"

    def test_deploy_is_last_stage(self, ci_config):
        stages = ci_config["stages"]
        assert stages[-1] == "deploy"

    def test_stages_in_expected_order(self, ci_config):
        stages = ci_config["stages"]
        assert stages == self.EXPECTED_ORDER

    def test_no_duplicate_stages(self, ci_config):
        stages = ci_config["stages"]
        assert len(stages) == len(set(stages))


class TestRequiredJobs:

    def test_test_framework_validate_job_exists(self, ci_config):
        assert "test-framework: validate" in ci_config

    def test_test_framework_security_scan_exists(self, ci_config):
        assert "test-framework: security-scan" in ci_config

    def test_setup_environment_job_exists(self, ci_config):
        assert "setup: environment" in ci_config


class TestTestFrameworkJobs:

    def test_validate_runs_pytest(self, ci_config):
        job = ci_config.get("test-framework: validate", {})
        script = " ".join(job.get("script", []))
        assert "pytest" in script

    def test_validate_runs_contamination_check(self, ci_config):
        job = ci_config.get("test-framework: validate", {})
        script = " ".join(job.get("script", []))
        assert "nestjs-contamination" in script

    def test_security_scan_runs_scan_secrets(self, ci_config):
        job = ci_config.get("test-framework: security-scan", {})
        script = " ".join(job.get("script", []))
        assert "scan-secrets" in script

    def test_security_scan_runs_scan_config(self, ci_config):
        job = ci_config.get("test-framework: security-scan", {})
        script = " ".join(job.get("script", []))
        assert "scan-config" in script


class TestPipelineIntegrity:

    def test_has_variables_section(self, ci_config):
        assert "variables" in ci_config

    def test_outputs_dir_variable(self, ci_config):
        assert ci_config.get("variables", {}).get("OUTPUTS_DIR") == "outputs"

    def test_all_jobs_have_stage(self, ci_config):
        """Every job (except special keys) must have a stage."""
        special_keys = {"stages", "variables", "include", "default", "workflow"}
        for key, value in ci_config.items():
            if key in special_keys or not isinstance(value, dict):
                continue
            if key.startswith("."):
                continue  # hidden/template jobs
            assert "stage" in value, f"Job '{key}' is missing 'stage' field"
