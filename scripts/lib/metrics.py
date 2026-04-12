"""
RedWork Metrics Collector.

Records agent execution metrics in .project-state/metrics.jsonl
and provides summary/analysis commands.
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


class MetricsCollector:
    def __init__(self, project_path: str = "."):
        self.project_path = Path(project_path)
        self.metrics_file = self.project_path / ".project-state" / "metrics.jsonl"

    def _append(self, record: dict):
        self.metrics_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.metrics_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")

    def _read_all(self) -> list[dict]:
        if not self.metrics_file.exists():
            return []
        records = []
        with open(self.metrics_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        records.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        return records

    def record_start(self, agent_id: str, sprint: Optional[int] = None):
        self._append({
            "agent": agent_id,
            "sprint": sprint,
            "event": "start",
            "timestamp": _now_iso(),
        })

    def record_end(self, agent_id: str, status: str, sprint: Optional[int] = None):
        records = self._read_all()
        start_time = None
        for r in reversed(records):
            if r.get("agent") == agent_id and r.get("event") == "start":
                start_time = r.get("timestamp")
                break

        duration_s = None
        if start_time:
            try:
                start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
                end_dt = datetime.now(timezone.utc)
                duration_s = int((end_dt - start_dt).total_seconds())
            except (ValueError, TypeError):
                pass

        self._append({
            "agent": agent_id,
            "sprint": sprint,
            "event": "end",
            "status": status,
            "duration_s": duration_s,
            "timestamp": _now_iso(),
        })

    def get_summary(self, sprint: Optional[int] = None) -> dict:
        records = self._read_all()
        if sprint is not None:
            records = [r for r in records if r.get("sprint") == sprint]

        ends = [r for r in records if r.get("event") == "end"]
        total_runs = len(ends)
        successes = sum(1 for r in ends if r.get("status") == "success")
        failures = sum(1 for r in ends if r.get("status") == "failed")

        durations = {}
        for r in ends:
            if r.get("duration_s") is not None:
                aid = r["agent"]
                if aid not in durations:
                    durations[aid] = []
                durations[aid].append(r["duration_s"])

        total_time_s = sum(
            sum(ds) for ds in durations.values()
        )

        return {
            "sprint": sprint,
            "total_runs": total_runs,
            "successes": successes,
            "failures": failures,
            "success_rate": round(successes / total_runs * 100, 1) if total_runs else 0,
            "total_time_s": total_time_s,
            "total_time_human": _format_duration(total_time_s),
            "agents_run": len(durations),
        }

    def get_slowest_agents(self, n: int = 5) -> list[dict]:
        records = self._read_all()
        ends = [r for r in records if r.get("event") == "end" and r.get("duration_s")]

        agent_totals = {}
        for r in ends:
            aid = r["agent"]
            if aid not in agent_totals:
                agent_totals[aid] = 0
            agent_totals[aid] += r["duration_s"]

        sorted_agents = sorted(agent_totals.items(), key=lambda x: x[1], reverse=True)
        return [
            {"agent": aid, "total_s": total, "human": _format_duration(total)}
            for aid, total in sorted_agents[:n]
        ]

    def get_failed_runs(self) -> list[dict]:
        records = self._read_all()
        return [r for r in records if r.get("event") == "end" and r.get("status") == "failed"]

    def format_report(self, sprint: Optional[int] = None) -> str:
        summary = self.get_summary(sprint)
        slowest = self.get_slowest_agents(5)
        failed = self.get_failed_runs()

        lines = []
        sprint_label = f"Sprint {sprint}" if sprint else "All Sprints"
        lines.append(f"{sprint_label} Summary:")
        lines.append(f"  Total time: {summary['total_time_human']}")
        lines.append(f"  Agents run: {summary['agents_run']}")
        lines.append(
            f"  Success rate: {summary['success_rate']}% "
            f"({summary['successes']}/{summary['total_runs']})"
        )

        if slowest:
            lines.append(f"  Slowest:")
            for s in slowest[:3]:
                lines.append(f"    Agent {s['agent']}: {s['human']}")

        if failed:
            lines.append(f"  Failed runs: {len(failed)}")
            for f_run in failed[-3:]:
                lines.append(f"    Agent {f_run['agent']} (sprint {f_run.get('sprint', '?')})")

        return "\n".join(lines)


def _format_duration(seconds: int) -> str:
    if seconds < 60:
        return f"{seconds}s"
    elif seconds < 3600:
        m, s = divmod(seconds, 60)
        return f"{m}m {s}s"
    else:
        h, rem = divmod(seconds, 3600)
        m, s = divmod(rem, 60)
        return f"{h}h {m}m"
