"""
Integration tests that simulate a mini workflow WITHOUT real agents.

Tests StateManager, MetricsCollector, and validate scripts working together
to verify the end-to-end framework workflow from init to validation.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()

sys.path.insert(0, str(FRAMEWORK_ROOT / "scripts"))


from lib.metrics import MetricsCollector
from lib.state_manager import StateManager


class TestFullWorkflowInitToValidate:
    """Simulate: init project -> copy fixture -> validate -> mark complete -> check state."""

    def test_full_workflow_init_to_validate(self, tmp_path):
        # Arrange: create project structure
        project = tmp_path / "test-project"
        project.mkdir()
        (project / "outputs").mkdir()
        (project / ".project-state").mkdir()
        (project / "backend").mkdir()
        (project / "09_sprint_plan" / "sprint_01").mkdir(parents=True)

        # Initialize state via StateManager
        sm = StateManager(project_path=str(project))
        sm.initialize("test-project", {"backend": "fastapi", "frontend": "react"})

        # Verify state was created
        assert sm.exists(), "State file should exist after initialization"

        # Copy the valid fixture to outputs
        fixture_src = FRAMEWORK_ROOT / "tests" / "fixtures" / "valid" / "01_product_discovery.md"
        fixture_dst = project / "outputs" / "01_product_discovery.md"
        shutil.copy2(str(fixture_src), str(fixture_dst))

        # Run validate-agent-01.sh against the fixture.
        # Write a sanitized copy (LF line endings) to a temp file in the
        # outputs dir so bash can resolve it without Windows path issues.
        validator = FRAMEWORK_ROOT / "scripts" / "workflow" / "validate-agent-01.sh"
        script_content = validator.read_text(encoding="utf-8").replace("\r\n", "\n")
        tmp_script = project / "outputs" / "_validate.sh"
        tmp_script.write_text(script_content, encoding="utf-8", newline="\n")
        result = subprocess.run(
            ["bash", "_validate.sh"],
            cwd=str(project / "outputs"),
            capture_output=True,
            text=True,
            timeout=15,
        )
        tmp_script.unlink(missing_ok=True)
        assert result.returncode == 0, (
            f"validate-agent-01.sh failed:\nstdout: {result.stdout}\nstderr: {result.stderr}"
        )

        # Mark prevalidation + agent 01 as complete in state
        sm.agent_start("00b")
        sm.agent_complete("00b", "outputs/00b_impact_analysis.md")
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01_product_discovery.md")

        # Verify state shows agent 01 completed
        state = sm.load()
        assert state["agents"]["01"]["status"] == "completed"

        # Verify get_next_agent returns "02"
        next_agent = sm.get_next_agent()
        assert next_agent == "02", f"Expected next agent '02', got '{next_agent}'"


class TestStateResumeAfterFailure:
    """Test resume_info after partial completion with a failure."""

    def test_state_resume_after_failure(self, tmp_path):
        # Arrange
        project = tmp_path / "resume-project"
        project.mkdir()
        sm = StateManager(project_path=str(project))
        sm.initialize("resume-project")

        # Mark prevalidation completed
        sm.agent_start("00b")
        sm.agent_complete("00b", "outputs/00b_impact_analysis.md")

        # Mark agent 01 completed
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01_product_discovery.md")

        # Mark agent 02 completed
        sm.agent_start("02")
        sm.agent_complete("02", "outputs/02_stakeholder_map.md")

        # Mark agent 03 failed
        sm.agent_start("03")
        sm.agent_fail("03", "Domain model validation error")

        # Act
        info = sm.resume_info()

        # Assert
        assert info["completed_count"] == 3, (
            f"Expected 3 completed (00b + 01 + 02), got {info['completed_count']}"
        )
        assert len(info["failed"]) == 1, (
            f"Expected 1 failed, got {len(info['failed'])}"
        )
        assert info["failed"][0]["id"] == "03"

        # get_next_agent should return "03" (retry the failed one, which is
        # not "completed" so the loop in get_next_agent checks can_run for it;
        # its status is "failed" not "completed" and not "in_progress",
        # so it checks dependencies which are met -> returns "03")
        next_agent = sm.get_next_agent()
        assert next_agent == "03", (
            f"Expected next agent '03' (retry failed), got '{next_agent}'"
        )


class TestMetricsIntegration:
    """Test MetricsCollector records and reports correctly."""

    def test_metrics_integration(self, tmp_path):
        # Arrange
        project = tmp_path / "metrics-project"
        project.mkdir()
        mc = MetricsCollector(project_path=str(project))

        # Record some agent executions
        mc.record_start("01", sprint=1)
        mc.record_end("01", "success", sprint=1)

        mc.record_start("02", sprint=1)
        mc.record_end("02", "success", sprint=1)

        mc.record_start("03", sprint=1)
        mc.record_end("03", "failed", sprint=1)

        # Act
        report = mc.format_report(sprint=1)

        # Assert: report is a non-empty string with expected content
        assert isinstance(report, str)
        assert len(report) > 0
        assert "Sprint 1" in report
        assert "Success rate" in report

        # Check summary numbers
        summary = mc.get_summary(sprint=1)
        assert summary["total_runs"] == 3
        assert summary["successes"] == 2
        assert summary["failures"] == 1
        assert summary["agents_run"] == 3


class TestSprintStateTracking:
    """Test sprint wave status tracking via StateManager."""

    def test_sprint_state_tracking(self, tmp_path):
        # Arrange
        project = tmp_path / "sprint-project"
        project.mkdir()
        sm = StateManager(project_path=str(project))
        sm.initialize("sprint-project")

        # Act: update sprint wave to in_progress
        sm.update_sprint(1, "3a", "in_progress", 5, 14)

        state = sm.load()
        wave_3a = state["sprints"]["1"]["waves"]["3a"]
        assert wave_3a["status"] == "in_progress"
        assert wave_3a["tasks_completed"] == 5
        assert wave_3a["tasks_total"] == 14

        # Act: update sprint wave to completed
        sm.update_sprint(1, "3a", "completed", 14, 14)

        state = sm.load()
        wave_3a = state["sprints"]["1"]["waves"]["3a"]
        assert wave_3a["status"] == "completed"
        assert wave_3a["tasks_completed"] == 14
        assert wave_3a["tasks_total"] == 14

        # Sprint itself should be completed (only one wave and it is done)
        assert state["sprints"]["1"]["status"] == "completed"

    def test_sprint_not_complete_until_all_waves_done(self, tmp_path):
        # Arrange
        project = tmp_path / "multi-wave-project"
        project.mkdir()
        sm = StateManager(project_path=str(project))
        sm.initialize("multi-wave-project")

        # Add both waves: 3b first as in_progress, then 3a as completed.
        # Order matters because update_sprint checks if ALL existing waves
        # are completed -- adding 3a as completed first would mark the
        # sprint as completed before 3b exists.
        sm.update_sprint(1, "3b", "in_progress", 3, 8)
        sm.update_sprint(1, "3a", "completed", 10, 10)

        state = sm.load()
        # Sprint should NOT be completed yet
        assert state["sprints"]["1"]["status"] == "in_progress"

        # Complete the second wave
        sm.update_sprint(1, "3b", "completed", 8, 8)

        state = sm.load()
        # Now sprint should be completed
        assert state["sprints"]["1"]["status"] == "completed"
