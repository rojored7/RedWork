"""
Tests for StateManager.
"""

import json
import pytest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.lib.state_manager import StateManager


class TestStateManagerInit:
    def test_initialize_creates_state_file(self, tmp_path):
        sm = StateManager(str(tmp_path))
        state = sm.initialize("test-project")

        assert sm.state_file.exists()
        assert state["project_name"] == "test-project"
        assert state["stack"]["backend"] == "fastapi"
        assert state["current_phase"] == "discovery"

    def test_initialize_with_custom_stack(self, tmp_path):
        sm = StateManager(str(tmp_path))
        state = sm.initialize("test", {"backend": "django", "frontend": "vue"})

        assert state["stack"]["backend"] == "django"
        assert state["stack"]["frontend"] == "vue"


class TestStateManagerAgentLifecycle:
    @pytest.fixture
    def sm(self, tmp_path):
        sm = StateManager(str(tmp_path))
        sm.initialize("test-project")
        return sm

    def test_agent_start(self, sm):
        sm.agent_start("01")
        state = sm.load()
        assert state["agents"]["01"]["status"] == "in_progress"
        assert state["last_agent"] == "01"

    def test_agent_complete(self, sm):
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01_product_discovery.md")
        state = sm.load()
        assert state["agents"]["01"]["status"] == "completed"
        assert state["agents"]["01"]["output"] == "outputs/01_product_discovery.md"

    def test_agent_fail(self, sm):
        sm.agent_start("01")
        sm.agent_fail("01", "Missing sections")
        state = sm.load()
        assert state["agents"]["01"]["status"] == "failed"
        assert state["agents"]["01"]["error"] == "Missing sections"


class TestStateManagerDependencies:
    @pytest.fixture
    def sm(self, tmp_path):
        sm = StateManager(str(tmp_path))
        sm.initialize("test-project")
        return sm

    def test_agent_01_can_run_immediately(self, sm):
        can, missing = sm.can_run("01")
        assert can is True
        assert missing == []

    def test_agent_02_blocked_without_01(self, sm):
        can, missing = sm.can_run("02")
        assert can is False
        assert "01" in missing

    def test_agent_02_unblocked_after_01_complete(self, sm):
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01.md")
        can, missing = sm.can_run("02")
        assert can is True

    def test_get_next_agent_returns_first_runnable(self, sm):
        next_agent = sm.get_next_agent()
        assert next_agent == "01"

    def test_get_next_agent_skips_completed(self, sm):
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01.md")
        next_agent = sm.get_next_agent()
        assert next_agent == "02"


class TestStateManagerResume:
    @pytest.fixture
    def sm(self, tmp_path):
        sm = StateManager(str(tmp_path))
        sm.initialize("test-project")
        sm.agent_start("01")
        sm.agent_complete("01", "outputs/01.md")
        sm.agent_start("02")
        sm.agent_complete("02", "outputs/02.md")
        sm.agent_start("03")
        sm.agent_fail("03", "Network error")
        return sm

    def test_resume_info_shows_state(self, sm):
        info = sm.resume_info()
        assert info["completed_count"] == 2
        assert len(info["failed"]) == 1
        assert info["failed"][0]["id"] == "03"
        assert info["next_agent"] == "03"  # failed agent is retryable


class TestStateManagerSprint:
    @pytest.fixture
    def sm(self, tmp_path):
        sm = StateManager(str(tmp_path))
        sm.initialize("test-project")
        return sm

    def test_update_sprint_wave(self, sm):
        sm.update_sprint(1, "3a", "in_progress", 5, 14)
        state = sm.load()
        assert state["sprints"]["1"]["waves"]["3a"]["tasks_completed"] == 5

    def test_sprint_completes_when_all_waves_done(self, sm):
        sm.update_sprint(1, "0", "completed")
        sm.update_sprint(1, "3a", "completed")
        sm.update_sprint(1, "3b", "completed")
        state = sm.load()
        assert state["sprints"]["1"]["status"] == "completed"
