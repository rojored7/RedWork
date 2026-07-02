"""
Tests for the impact-prevalidator hard gate
(scripts/workflow/validate-impact-analysis.sh) and the agent definition.

Exit code contract:
    0 = fresh VERDE (or AMARILLO with --allow-amber)
    1 = ROJO (or AMARILLO without --allow-amber)
    2 = report missing
    3 = report malformed
    4 = report stale (ANALYZED-COMMIT != HEAD)
"""

import subprocess
from pathlib import Path

import pytest

from tests.conftest import FRAMEWORK_ROOT, FIXTURES_DIR, GIT_BASH, to_posix

GATE = FRAMEWORK_ROOT / "scripts" / "workflow" / "validate-impact-analysis.sh"
AGENT_MD = FRAMEWORK_ROOT / "agents" / "impact-prevalidator.md"
REPORT_REL = Path("outputs") / "00b_impact_analysis.md"


def _run_gate(cwd, *args) -> tuple:
    result = subprocess.run(
        [GIT_BASH, to_posix(str(GATE)), *args],
        cwd=str(cwd),
        capture_output=True,
        text=True,
        timeout=60,
    )
    return result.returncode, result.stdout, result.stderr


@pytest.fixture
def git_project(tmp_project):
    """tmp_project with git identity and an initial commit (HEAD exists)."""
    for cmd in (
        ["git", "config", "user.email", "test@redwork.local"],
        ["git", "config", "user.name", "redwork-tests"],
        ["git", "commit", "--allow-empty", "-m", "init"],
    ):
        subprocess.run(cmd, cwd=str(tmp_project), capture_output=True, check=True)
    return tmp_project


def _head_sha(project) -> str:
    result = subprocess.run(
        ["git", "rev-parse", "HEAD"],
        cwd=str(project),
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def _write_report(project, fixture_name: str, sha: str, subdir: str = "valid"):
    fixture = FIXTURES_DIR / subdir / fixture_name
    content = fixture.read_text(encoding="utf-8").replace("{sha}", sha)
    (project / REPORT_REL).write_text(content, encoding="utf-8")


class TestGateMissingReport:
    def test_missing_report_exits_2(self, git_project):
        code, out, _ = _run_gate(git_project)
        assert code == 2, f"Expected exit 2, got {code}: {out}"
        assert "impact-prevalidator" in out


class TestGateVerdicts:
    def test_verde_fresh_exits_0(self, git_project):
        _write_report(git_project, "00b_impact_verde.md", _head_sha(git_project))
        code, out, _ = _run_gate(git_project)
        assert code == 0, f"Expected exit 0, got {code}: {out}"

    def test_amarillo_without_flag_exits_1(self, git_project):
        _write_report(git_project, "00b_impact_amarillo.md", _head_sha(git_project))
        code, out, _ = _run_gate(git_project)
        assert code == 1, f"Expected exit 1, got {code}: {out}"

    def test_amarillo_with_allow_amber_exits_0(self, git_project):
        _write_report(git_project, "00b_impact_amarillo.md", _head_sha(git_project))
        code, out, _ = _run_gate(git_project, "--allow-amber")
        assert code == 0, f"Expected exit 0, got {code}: {out}"
        assert "Condiciones" in out

    def test_rojo_exits_1_even_with_allow_amber(self, git_project):
        _write_report(
            git_project, "00b_impact_rojo.md", _head_sha(git_project), subdir="invalid"
        )
        code, out, _ = _run_gate(git_project, "--allow-amber")
        assert code == 1, f"Expected exit 1, got {code}: {out}"
        assert "ROJO" in out


class TestGateFreshness:
    def test_stale_commit_exits_4(self, git_project):
        _write_report(git_project, "00b_impact_verde.md", _head_sha(git_project))
        subprocess.run(
            ["git", "commit", "--allow-empty", "-m", "bump HEAD"],
            cwd=str(git_project),
            capture_output=True,
            check=True,
        )
        code, out, _ = _run_gate(git_project)
        assert code == 4, f"Expected exit 4, got {code}: {out}"
        assert "stale" in out.lower()

    def test_short_sha_prefix_accepted(self, git_project):
        _write_report(git_project, "00b_impact_verde.md", _head_sha(git_project)[:12])
        code, out, _ = _run_gate(git_project)
        assert code == 0, f"Expected exit 0 for SHA prefix, got {code}: {out}"


class TestGateMalformed:
    def test_missing_verdict_and_commit_exits_3(self, git_project):
        _write_report(
            git_project,
            "00b_impact_sin_veredicto.md",
            _head_sha(git_project),
            subdir="invalid",
        )
        code, out, _ = _run_gate(git_project)
        assert code == 3, f"Expected exit 3, got {code}: {out}"

    def test_unknown_argument_exits_3(self, git_project):
        code, out, _ = _run_gate(git_project, "--bogus")
        assert code == 3, f"Expected exit 3, got {code}: {out}"


class TestAgentDefinition:
    def test_agent_file_exists(self):
        assert AGENT_MD.exists(), "agents/impact-prevalidator.md missing"

    def test_frontmatter_contract(self):
        content = AGENT_MD.read_text(encoding="utf-8")
        for token in ("name: impact-prevalidator", "model:", "tools:", "description:"):
            assert token in content, f"Frontmatter missing '{token}'"

    def test_body_contract(self):
        content = AGENT_MD.read_text(encoding="utf-8")
        for token in (
            "00b_impact_analysis.md",
            "Anti-Hallucination",
            "ANALYZED-COMMIT",
            "## Veredicto: VERDE | AMARILLO | ROJO",
            "validate-impact-analysis.sh",
        ):
            assert token in content, f"Agent body missing '{token}'"

    def test_registered_in_state_manager(self):
        from scripts.lib.state_manager import AGENT_DEPENDENCIES, AGENT_PHASES

        assert AGENT_DEPENDENCIES.get("00b") == []
        assert "00b" in AGENT_DEPENDENCIES.get("01", [])
        assert "00b" in AGENT_DEPENDENCIES.get("25", [])
        assert AGENT_PHASES.get("prevalidation") == ["00b"]
