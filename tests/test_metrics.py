"""
Tests for scripts/lib/metrics.py MetricsCollector.

Uses tmp_path so no real project state is touched.
"""

import json
import sys
import time
from pathlib import Path
from unittest.mock import patch

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
sys.path.insert(0, str(FRAMEWORK_ROOT))

from scripts.lib.metrics import MetricsCollector


@pytest.fixture
def collector(tmp_path):
    """Return a MetricsCollector writing to tmp_path."""
    return MetricsCollector(str(tmp_path))


def test_record_start_creates_file(tmp_path):
    """record_start creates the metrics.jsonl file."""
    mc = MetricsCollector(str(tmp_path))
    metrics_file = tmp_path / ".project-state" / "metrics.jsonl"
    assert not metrics_file.exists()

    mc.record_start("01")

    assert metrics_file.exists()
    lines = metrics_file.read_text(encoding="utf-8").strip().split("\n")
    assert len(lines) == 1
    record = json.loads(lines[0])
    assert record["agent"] == "01"
    assert record["event"] == "start"


def test_record_end_with_duration(collector):
    """record_end after record_start produces a duration_s value."""
    collector.record_start("02")
    collector.record_end("02", status="success")

    records = collector._read_all()
    end_records = [r for r in records if r["event"] == "end"]
    assert len(end_records) == 1
    assert end_records[0]["status"] == "success"
    assert end_records[0]["duration_s"] is not None
    assert end_records[0]["duration_s"] >= 0


def test_summary_counts(collector):
    """get_summary counts total_runs, successes, and failures correctly."""
    collector.record_start("01")
    collector.record_end("01", status="success")
    collector.record_start("02")
    collector.record_end("02", status="success")
    collector.record_start("03")
    collector.record_end("03", status="failed")

    summary = collector.get_summary()
    assert summary["total_runs"] == 3
    assert summary["successes"] == 2
    assert summary["failures"] == 1


def test_summary_success_rate(collector):
    """3 successes + 1 failure = 75.0% success rate."""
    for agent_id in ["01", "02", "03"]:
        collector.record_start(agent_id)
        collector.record_end(agent_id, status="success")
    collector.record_start("04")
    collector.record_end("04", status="failed")

    summary = collector.get_summary()
    assert summary["total_runs"] == 4
    assert summary["successes"] == 3
    assert summary["failures"] == 1
    assert summary["success_rate"] == 75.0


def test_slowest_agents(collector):
    """get_slowest_agents returns agents sorted by total duration descending."""
    # Inject records directly with known durations to avoid timing issues.
    metrics_file = collector.metrics_file
    metrics_file.parent.mkdir(parents=True, exist_ok=True)

    ts = "2026-01-01T00:00:00Z"
    records = [
        {"agent": "01", "sprint": None, "event": "end",
         "status": "success", "duration_s": 10, "timestamp": ts},
        {"agent": "02", "sprint": None, "event": "end",
         "status": "success", "duration_s": 50, "timestamp": ts},
        {"agent": "03", "sprint": None, "event": "end",
         "status": "success", "duration_s": 30, "timestamp": ts},
    ]
    with open(metrics_file, "w", encoding="utf-8") as f:
        for r in records:
            f.write(json.dumps(r) + "\n")

    slowest = collector.get_slowest_agents(5)
    assert len(slowest) == 3
    assert slowest[0]["agent"] == "02"
    assert slowest[0]["total_s"] == 50
    assert slowest[1]["agent"] == "03"
    assert slowest[1]["total_s"] == 30
    assert slowest[2]["agent"] == "01"
    assert slowest[2]["total_s"] == 10


def test_format_report(collector):
    """format_report returns a readable string containing 'Summary'."""
    collector.record_start("01")
    collector.record_end("01", status="success")

    report = collector.format_report()
    assert isinstance(report, str)
    assert "Summary" in report
    assert "Success rate" in report or "success_rate" in report
