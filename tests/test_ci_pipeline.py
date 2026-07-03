"""
Tests for the v2.3 CI reality:
- .github/workflows/framework-ci.yml is the canonical CI (executes, blocks)
- templates/project/github-workflows-ci.yml carries the 100% coverage gates
- .gitlab-ci.yml is a minimal honest mirror (no theater)
- the GitLab child-pipeline theater and deploy stubs are gone
"""

from pathlib import Path

import pytest
import yaml

from tests.conftest import FRAMEWORK_ROOT

FRAMEWORK_CI = FRAMEWORK_ROOT / ".github" / "workflows" / "framework-ci.yml"
PROJECT_CI = FRAMEWORK_ROOT / "templates" / "project" / "github-workflows-ci.yml"
GITLAB_CI = FRAMEWORK_ROOT / ".gitlab-ci.yml"


def _load(path: Path) -> dict:
    with open(path, encoding="utf-8") as f:
        return yaml.safe_load(f)


class TestFrameworkCI:
    def test_workflow_exists_and_parses(self):
        assert FRAMEWORK_CI.exists()
        data = _load(FRAMEWORK_CI)
        assert "jobs" in data

    def test_expected_jobs_present(self):
        jobs = _load(FRAMEWORK_CI)["jobs"]
        for job in ("tests", "security", "reference-integrity"):
            assert job in jobs, f"framework-ci.yml missing job '{job}'"

    def test_no_continue_on_error(self):
        content = FRAMEWORK_CI.read_text(encoding="utf-8")
        assert "continue-on-error" not in content, "CI must block, never tolerate"

    def test_runs_the_real_suite(self):
        content = FRAMEWORK_CI.read_text(encoding="utf-8")
        assert "pytest tests/" in content
        assert "validate-no-nestjs-contamination.sh" in content
        assert "scan-secrets.sh" in content
        assert "sweep_references.py --check" in content

    def test_no_deploy_job(self):
        jobs = _load(FRAMEWORK_CI)["jobs"]
        assert not any("deploy" in j.lower() for j in jobs)


class TestProjectCITemplate:
    def test_template_exists_and_parses(self):
        assert PROJECT_CI.exists()
        data = _load(PROJECT_CI)
        assert "jobs" in data

    def test_backend_gate_matches_local_gate(self):
        """ONE contract: the CI runs the same coverage command the local
        slice/wave gates run."""
        content = PROJECT_CI.read_text(encoding="utf-8")
        assert "--cov=app" in content
        assert "--cov-fail-under=100" in content
        assert "ruff check" in content
        assert "mypy app/" in content

    def test_frontend_gate_has_coverage(self):
        content = PROJECT_CI.read_text(encoding="utf-8")
        assert "vitest run --coverage" in content
        assert "tsc --noEmit" in content
        assert "eslint src/" in content

    def test_security_job_present(self):
        jobs = _load(PROJECT_CI)["jobs"]
        assert "security" in jobs

    def test_no_deploy_and_no_continue_on_error(self):
        content = PROJECT_CI.read_text(encoding="utf-8")
        jobs = _load(PROJECT_CI)["jobs"]
        assert not any("deploy" in j.lower() for j in jobs)
        assert "continue-on-error" not in content
        assert "DEPLOYMENT.md" in content  # honest scope note


class TestGitLabMirrorIsMinimal:
    def test_parses(self):
        data = _load(GITLAB_CI)
        assert data

    def test_only_test_framework_stage(self):
        data = _load(GITLAB_CI)
        assert data.get("stages") == ["test-framework"]

    def test_no_theater(self):
        content = GITLAB_CI.read_text(encoding="utf-8")
        for forbidden in ("when: manual", "allow_failure", "trigger:",
                          "wait-for-file", "deploy", "sleep"):
            assert forbidden not in content, f"GitLab theater residue: {forbidden}"

    def test_child_pipelines_removed(self):
        assert not (FRAMEWORK_ROOT / ".gitlab").exists()


class TestTheaterRemoved:
    def test_pipeline_scripts_removed(self):
        assert not (FRAMEWORK_ROOT / "scripts/workflow/install-pipeline.sh").exists()
        assert not (FRAMEWORK_ROOT / "scripts/workflow/pipeline-helper.sh").exists()

    def test_new_sprint_generates_no_gitlab_yaml(self):
        content = (FRAMEWORK_ROOT / "scripts/workflow/new_sprint.py").read_text(encoding="utf-8")
        assert ".gitlab" not in content
        assert "sprint-template" not in content

    def test_init_does_not_copy_gitlab(self):
        content = (FRAMEWORK_ROOT / "install.py").read_text(encoding="utf-8")
        assert '".gitlab"' not in content
        assert ".gitlab-ci.yml" not in content
        assert "github-workflows-ci.yml" in content
        assert "DEPLOYMENT.md" in content
