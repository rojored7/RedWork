"""
RedWork State Manager.

Manages project state in .project-state/state.json.
Tracks agent completion, sprint progress, wave status, and enables
resume from any point in the workflow.
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


# Agent dependency graph: agent_id -> list of required predecessors
# "00b" is the impact-prevalidator (hard gate: validate-impact-analysis.sh);
# it anchors the whole pipeline, so 01 (discovery) and 25 (orchestrator)
# depend on it.
AGENT_DEPENDENCIES = {
    "00b": [],
    "01": ["00b"],
    "02": ["01"],
    "03": ["02"],
    "04": ["03"],
    "04b": ["04"],
    "05": ["04"],
    "05b": ["05"],
    "06": ["05"],
    "07": ["06"],
    "08": ["07"],
    "09": ["08"],
    "10": ["09"],
    "11": ["10"],
    "12": ["09"],
    "13": ["12"],
    "14": ["13"],
    "15": ["12"],
    "16": ["15"],
    "17": ["14", "16"],
    "18": ["17"],
    "19": ["18"],
    "20": ["14", "16"],
    "21": ["20"],
    "22": ["14", "16"],
    "23": ["22"],
    "24": ["23"],
    "25": ["09", "00b"],
}

AGENT_PHASES = {
    "prevalidation": ["00b"],
    "discovery": ["01", "02", "03", "04", "04b", "05", "05b"],
    "planning": ["06", "07", "08", "09"],
    "api_contract": ["10", "11"],
    "infrastructure": ["12"],
    "backend_test": ["13"],
    "backend_dev": ["14"],
    "frontend_test": ["15"],
    "frontend_dev": ["16"],
    "validation": ["17", "18", "19", "20", "21"],
    "quality": ["22", "23", "24"],
}


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class StateManager:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.state_dir = self.project_path / ".project-state"
        self.state_file = self.state_dir / "state.json"

    def exists(self) -> bool:
        return self.state_file.exists()

    def initialize(self, project_name: str, stack: Optional[dict] = None,
                   framework_version: Optional[str] = None):
        """Create initial state.json for a new project."""
        if framework_version is None:
            try:
                from scripts.lib.version import FRAMEWORK_VERSION
            except ImportError:  # loose-script execution
                from version import FRAMEWORK_VERSION
            framework_version = FRAMEWORK_VERSION
        self.state_dir.mkdir(parents=True, exist_ok=True)
        state = {
            "project_name": project_name,
            "created_at": _now_iso(),
            "framework_version": framework_version,
            "stack": stack or {"backend": "fastapi", "frontend": "react"},
            "current_phase": "discovery",
            "agents": {},
            "sprints": {},
            "last_agent": None,
            "last_activity": _now_iso(),
        }
        self._save(state)
        return state

    def load(self) -> dict:
        if not self.state_file.exists():
            raise FileNotFoundError(
                f"State file not found: {self.state_file}\n"
                "Run 'python install.py init <project>' or Agent 25 Phase 0 first."
            )
        with open(self.state_file, "r", encoding="utf-8") as f:
            return json.load(f)

    def _save(self, state: dict):
        self.state_dir.mkdir(parents=True, exist_ok=True)
        tmp = str(self.state_file) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        os.replace(tmp, str(self.state_file))

    def agent_start(self, agent_id: str):
        state = self.load()
        state["agents"][agent_id] = {
            "status": "in_progress",
            "started_at": _now_iso(),
        }
        state["last_agent"] = agent_id
        state["last_activity"] = _now_iso()
        self._determine_phase(state, agent_id)
        self._save(state)

    def agent_complete(self, agent_id: str, output_path: str = ""):
        state = self.load()
        agent_state = state["agents"].get(agent_id, {})
        agent_state.update({
            "status": "completed",
            "completed_at": _now_iso(),
            "output": output_path,
        })
        state["agents"][agent_id] = agent_state
        state["last_agent"] = agent_id
        state["last_activity"] = _now_iso()
        self._save(state)

    def agent_fail(self, agent_id: str, error: str):
        state = self.load()
        agent_state = state["agents"].get(agent_id, {})
        agent_state.update({
            "status": "failed",
            "failed_at": _now_iso(),
            "error": error,
        })
        state["agents"][agent_id] = agent_state
        state["last_agent"] = agent_id
        state["last_activity"] = _now_iso()
        self._save(state)

    def can_run(self, agent_id: str) -> tuple[bool, list[str]]:
        """Check if an agent's dependencies are all completed.
        Returns (can_run, missing_deps)."""
        state = self.load()
        deps = AGENT_DEPENDENCIES.get(agent_id, [])
        missing = []
        for dep in deps:
            agent_info = state["agents"].get(dep, {})
            if agent_info.get("status") != "completed":
                missing.append(dep)
        return len(missing) == 0, missing

    def get_next_agent(self) -> Optional[str]:
        """Calculate the next agent to run based on current state."""
        state = self.load()
        all_ids = list(AGENT_DEPENDENCIES.keys())

        for agent_id in all_ids:
            agent_info = state["agents"].get(agent_id, {})
            status = agent_info.get("status")

            if status == "completed":
                continue
            if status == "in_progress":
                return agent_id

            can, _ = self.can_run(agent_id)
            if can:
                return agent_id

        return None

    def get_failed_agents(self) -> list[dict]:
        state = self.load()
        failed = []
        for aid, info in state["agents"].items():
            if info.get("status") == "failed":
                failed.append({"id": aid, **info})
        return failed

    def resume_info(self) -> dict:
        """Get comprehensive resume information."""
        state = self.load()
        completed = [
            aid for aid, info in state["agents"].items()
            if info.get("status") == "completed"
        ]
        failed = self.get_failed_agents()
        next_agent = self.get_next_agent()

        return {
            "project": state.get("project_name"),
            "phase": state.get("current_phase"),
            "completed": completed,
            "completed_count": len(completed),
            "failed": failed,
            "next_agent": next_agent,
            "last_agent": state.get("last_agent"),
            "last_activity": state.get("last_activity"),
            "sprints": state.get("sprints", {}),
        }

    def update_sprint(self, sprint_num: int, wave: str, status: str,
                       tasks_completed: int = 0, tasks_total: int = 0):
        state = self.load()
        sprint_key = str(sprint_num)
        if sprint_key not in state["sprints"]:
            state["sprints"][sprint_key] = {"status": "in_progress", "waves": {}}

        state["sprints"][sprint_key]["waves"][wave] = {
            "status": status,
            "tasks_completed": tasks_completed,
            "tasks_total": tasks_total,
        }

        all_waves_done = all(
            w.get("status") == "completed"
            for w in state["sprints"][sprint_key]["waves"].values()
        )
        if all_waves_done and state["sprints"][sprint_key]["waves"]:
            state["sprints"][sprint_key]["status"] = "completed"

        state["last_activity"] = _now_iso()
        self._save(state)

    def _determine_phase(self, state: dict, agent_id: str):
        for phase, agents in AGENT_PHASES.items():
            if agent_id in agents:
                state["current_phase"] = phase
                break
