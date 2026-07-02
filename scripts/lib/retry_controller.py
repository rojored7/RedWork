"""
RedWork Retry Controller.

Deterministic state for the "factory loop": tracks gate attempts in
.project-state/retry_state.json with a configurable cap, and computes
the next action for the loop (run agent / retry gate / escalate / done).

The loop itself is executed by Claude following Agent 25 / the flows;
this module is the machinery that makes retries bounded, observable
and resumable. run-gates.sh consumes the CLI.

CLI (for bash):
    python -m scripts.lib.retry_controller record <gate_id> pass|fail
    python -m scripts.lib.retry_controller can-retry <gate_id>
    python -m scripts.lib.retry_controller next
    python -m scripts.lib.retry_controller status
"""

import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from .metrics import MetricsCollector
    from .state_manager import StateManager
except ImportError:  # executed as a loose script (bash heredoc / direct path)
    sys.path.insert(0, str(Path(__file__).parent))
    from metrics import MetricsCollector
    from state_manager import StateManager

DEFAULT_MAX_RETRIES = 3


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def _max_retries() -> int:
    raw = os.environ.get("FRAMEWORK_MAX_RETRIES", "")
    try:
        value = int(raw)
        return value if value > 0 else DEFAULT_MAX_RETRIES
    except ValueError:
        return DEFAULT_MAX_RETRIES


class RetryController:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.state_dir = self.project_path / ".project-state"
        self.retry_file = self.state_dir / "retry_state.json"
        self.max_retries = _max_retries()

    def _load(self) -> dict:
        if not self.retry_file.exists():
            return {"gates": {}, "updated_at": None}
        try:
            with open(self.retry_file, "r", encoding="utf-8") as f:
                return json.load(f)
        except (json.JSONDecodeError, OSError):
            return {"gates": {}, "updated_at": None}

    def _save(self, state: dict):
        self.state_dir.mkdir(parents=True, exist_ok=True)
        state["updated_at"] = _now_iso()
        tmp = str(self.retry_file) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(state, f, indent=2)
        os.replace(tmp, str(self.retry_file))

    def attempts(self, gate_id: str) -> int:
        return self._load()["gates"].get(gate_id, {}).get("attempts", 0)

    def can_retry(self, gate_id: str) -> bool:
        return self.attempts(gate_id) < self.max_retries

    def record_attempt(self, gate_id: str, passed: bool) -> dict:
        """Record one gate attempt. On pass the counter resets; on fail it
        increments. Returns {attempt, max, exhausted, passed}."""
        state = self._load()
        gate = state["gates"].setdefault(gate_id, {"attempts": 0, "history": []})

        metrics = MetricsCollector(str(self.project_path))
        if passed:
            attempt_number = gate["attempts"] + 1
            gate["attempts"] = 0
            gate["last_result"] = "pass"
            metrics.record_end(f"gate:{gate_id}", "success")
        else:
            gate["attempts"] += 1
            attempt_number = gate["attempts"]
            gate["last_result"] = "fail"
            metrics.record_end(f"gate:{gate_id}", "retry_fail")

        gate["history"].append(
            {"at": _now_iso(), "passed": passed, "attempt": attempt_number}
        )
        gate["history"] = gate["history"][-20:]
        self._save(state)

        return {
            "gate": gate_id,
            "attempt": attempt_number,
            "max": self.max_retries,
            "exhausted": (not passed) and gate["attempts"] >= self.max_retries,
            "passed": passed,
        }

    def reset(self, gate_id: str):
        state = self._load()
        if gate_id in state["gates"]:
            state["gates"][gate_id]["attempts"] = 0
            state["gates"][gate_id]["last_result"] = "reset"
            self._save(state)

    def exhausted_gates(self) -> list[str]:
        state = self._load()
        return [
            gid
            for gid, info in state["gates"].items()
            if info.get("attempts", 0) >= self.max_retries
        ]

    def status(self) -> dict:
        state = self._load()
        return {
            "max_retries": self.max_retries,
            "gates": {
                gid: {
                    "attempts": info.get("attempts", 0),
                    "last_result": info.get("last_result"),
                }
                for gid, info in state["gates"].items()
            },
            "exhausted": self.exhausted_gates(),
        }


def _blocked_waves(project_path: Path) -> list[str]:
    state_dir = project_path / ".project-state"
    if not state_dir.exists():
        return []
    return sorted(
        f.name.replace("wave_", "").replace("_blocked.flag", "")
        for f in state_dir.glob("wave_*_blocked.flag")
    )


def get_next_action(project_path: str = ".") -> dict:
    """Combine StateManager + blocked-wave flags + retry state into the
    single next action for the factory loop."""
    project = Path(project_path)
    rc = RetryController(project_path)

    needs_human = project / ".project-state" / "needs_human.flag"
    if needs_human.exists():
        return {
            "action": "escalate_human",
            "reason": "needs_human.flag present (a gate exhausted its retries)",
            "exhausted_gates": rc.exhausted_gates(),
        }

    exhausted = rc.exhausted_gates()
    if exhausted:
        return {
            "action": "escalate_human",
            "reason": f"gates exhausted retries (max {rc.max_retries})",
            "exhausted_gates": exhausted,
        }

    blocked = _blocked_waves(project)
    if blocked:
        wave = blocked[0]
        gate_id = f"wave_{wave}"
        return {
            "action": "retry_gate",
            "gate_id": gate_id,
            "wave": wave,
            "attempt": rc.attempts(gate_id) + 1,
            "max": rc.max_retries,
            "reason": f"wave {wave} blocked; fix within plan scope and re-run run-gates.sh {wave}",
        }

    sm = StateManager(project_path)
    if not sm.exists():
        return {
            "action": "escalate_human",
            "reason": ".project-state/state.json not found (project not initialized)",
        }

    failed = sm.get_failed_agents()
    if failed:
        return {
            "action": "run_agent",
            "agent_id": failed[0]["id"],
            "reason": f"agent {failed[0]['id']} previously failed; re-run it",
        }

    next_agent = sm.get_next_agent()
    if next_agent:
        return {
            "action": "run_agent",
            "agent_id": next_agent,
            "reason": "next runnable agent per dependency graph",
        }

    return {"action": "done", "reason": "all agents completed, no blocked waves"}


def _main(argv: list[str]) -> int:
    if len(argv) < 1:
        print(
            "Usage: retry_controller record <gate> pass|fail | "
            "can-retry <gate> | next | status",
            file=sys.stderr,
        )
        return 3

    command = argv[0]
    rc = RetryController(".")

    if command == "record" and len(argv) == 3 and argv[2] in ("pass", "fail"):
        result = rc.record_attempt(argv[1], argv[2] == "pass")
        print(json.dumps(result))
        return 0
    if command == "can-retry" and len(argv) == 2:
        allowed = rc.can_retry(argv[1])
        print(json.dumps({"gate": argv[1], "can_retry": allowed}))
        return 0 if allowed else 1
    if command == "next":
        print(json.dumps(get_next_action(".")))
        return 0
    if command == "status":
        print(json.dumps(rc.status(), indent=2))
        return 0

    print(f"ERROR: invalid arguments: {' '.join(argv)}", file=sys.stderr)
    return 3


if __name__ == "__main__":
    sys.exit(_main(sys.argv[1:]))
