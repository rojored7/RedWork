"""
Tests for LearningManager.
"""

import json
import pytest
from pathlib import Path

import sys
sys.path.insert(0, str(Path(__file__).parent.parent))

from scripts.lib.learning_manager import (
    LearningManager,
    CONFIDENCE_INITIAL,
    CONFIDENCE_INCREMENT,
    CONFIDENCE_DECREMENT,
    CONFIDENCE_ACTIVE,
    CONFIDENCE_PROMOTABLE,
    CONFIDENCE_MAX,
    CONFIDENCE_ARCHIVE,
    _write_yaml,
    _read_yaml,
    _normalize_input,
)


# ---- YAML Serialization ----

class TestYamlSerialization:
    def test_write_and_read_roundtrip(self, tmp_path):
        path = tmp_path / "test.yaml"
        data = {
            "id": "instinct-001",
            "pattern": "Always run tests",
            "confidence": 0.7,
            "stage": "active",
            "occurrences": 5,
            "tags": ["python", "testing"],
            "evidence": [
                {"timestamp": "2026-04-12T10:00:00Z", "detail": "Test passed"},
            ],
        }
        _write_yaml(path, data)
        loaded = _read_yaml(path)

        assert loaded["id"] == "instinct-001"
        assert loaded["pattern"] == "Always run tests"
        assert loaded["confidence"] == 0.7
        assert loaded["stage"] == "active"
        assert loaded["occurrences"] == 5
        assert "python" in loaded["tags"]
        assert "testing" in loaded["tags"]

    def test_write_null_and_bool(self, tmp_path):
        path = tmp_path / "test.yaml"
        data = {"key_null": None, "key_true": True, "key_false": False}
        _write_yaml(path, data)
        loaded = _read_yaml(path)

        assert loaded["key_null"] is None
        assert loaded["key_true"] is True
        assert loaded["key_false"] is False

    def test_read_nonexistent_returns_empty(self, tmp_path):
        result = _read_yaml(tmp_path / "missing.yaml")
        assert result == {}


# ---- Observations ----

class TestObservations:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_record_observation_creates_file(self, lm):
        lm.record_observation("Write", "editing file.py")
        assert lm.observations_file.exists()

    def test_record_observation_appends_jsonl(self, lm):
        lm.record_observation("Write", "file1.py")
        lm.record_observation("Edit", "file2.py")

        records = lm.read_observations()
        assert len(records) == 2
        assert records[0]["tool"] == "Write"
        assert records[1]["tool"] == "Edit"

    def test_record_observation_truncates_long_input(self, lm):
        long_input = "x" * 1000
        record = lm.record_observation("Bash", long_input)
        assert len(record["input"]) == 500

    def test_read_observations_with_limit(self, lm):
        for i in range(10):
            lm.record_observation("Write", f"file{i}.py")

        recent = lm.read_observations(limit=3)
        assert len(recent) == 3
        assert recent[0]["input"] == "file7.py"

    def test_observation_count(self, lm):
        assert lm.observation_count() == 0
        lm.record_observation("Write", "a.py")
        lm.record_observation("Edit", "b.py")
        assert lm.observation_count() == 2

    def test_rotate_observations(self, lm):
        for i in range(20):
            lm.record_observation("Write", f"file{i}.py")

        archived = lm.rotate_observations(max_lines=10)
        assert archived == 10
        assert lm.observation_count() == 10

        archive_dir = lm.learning_dir / "observations-archive"
        assert archive_dir.exists()
        archive_files = list(archive_dir.glob("observations-*.jsonl"))
        assert len(archive_files) == 1

    def test_rotate_noop_when_under_limit(self, lm):
        for i in range(5):
            lm.record_observation("Write", f"file{i}.py")
        archived = lm.rotate_observations(max_lines=10)
        assert archived == 0


# ---- Instincts CRUD ----

class TestInstinctsCRUD:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_create_instinct(self, lm):
        inst = lm.create_instinct(
            pattern="Run ruff after editing .py",
            context="backend development",
            tags=["python", "linting"],
        )
        assert inst["id"].startswith("instinct-")
        assert inst["confidence"] == CONFIDENCE_INITIAL
        assert inst["stage"] == "pending"
        assert inst["occurrences"] == 1

    def test_create_instinct_with_high_confidence(self, lm):
        inst = lm.create_instinct(
            pattern="test pattern",
            context="test",
            confidence=0.6,
        )
        assert inst["stage"] == "active"

    def test_create_instinct_caps_at_max(self, lm):
        inst = lm.create_instinct(
            pattern="test",
            context="test",
            confidence=1.5,
        )
        assert inst["confidence"] == CONFIDENCE_MAX

    def test_get_instinct(self, lm):
        created = lm.create_instinct("test pattern", "test context")
        loaded = lm.get_instinct(created["id"])
        assert loaded is not None
        assert loaded["pattern"] == "test pattern"

    def test_get_instinct_not_found(self, lm):
        result = lm.get_instinct("nonexistent-id")
        assert result is None

    def test_list_instincts_empty(self, lm):
        assert lm.list_instincts() == []

    def test_list_instincts(self, lm):
        lm.create_instinct("pattern1", "ctx1")
        lm.create_instinct("pattern2", "ctx2")
        instincts = lm.list_instincts()
        assert len(instincts) == 2

    def test_list_instincts_min_confidence_filter(self, lm):
        lm.create_instinct("low", "ctx", confidence=0.3)
        lm.create_instinct("high", "ctx", confidence=0.7)
        filtered = lm.list_instincts(min_confidence=0.5)
        assert len(filtered) == 1
        assert filtered[0]["pattern"] == "high"

    def test_delete_instinct(self, lm):
        inst = lm.create_instinct("to delete", "ctx")
        assert lm.delete_instinct(inst["id"]) is True
        assert lm.get_instinct(inst["id"]) is None

    def test_delete_nonexistent(self, lm):
        assert lm.delete_instinct("nope") is False


# ---- Confidence Scoring ----

class TestConfidenceScoring:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_increment_confidence(self, lm):
        inst = lm.create_instinct("test", "ctx", confidence=0.3)
        updated = lm.update_confidence(
            inst["id"], CONFIDENCE_INCREMENT, "confirmed"
        )
        assert updated["confidence"] == 0.4
        assert updated["occurrences"] == 2

    def test_decrement_confidence(self, lm):
        inst = lm.create_instinct("test", "ctx", confidence=0.5)
        updated = lm.update_confidence(
            inst["id"], -CONFIDENCE_DECREMENT, "contradicted"
        )
        assert updated["confidence"] == 0.35
        assert updated["stage"] == "pending"

    def test_confidence_caps_at_max(self, lm):
        inst = lm.create_instinct("test", "ctx", confidence=0.85)
        updated = lm.update_confidence(inst["id"], 0.2, "confirmed")
        assert updated["confidence"] == CONFIDENCE_MAX

    def test_confidence_floors_at_zero(self, lm):
        inst = lm.create_instinct("test", "ctx", confidence=0.3)
        updated = lm.update_confidence(inst["id"], -0.5, "contradicted")
        assert updated["confidence"] == 0.0
        assert updated["stage"] == "archived"

    def test_stage_transitions(self, lm):
        inst = lm.create_instinct("test", "ctx", confidence=0.3)
        assert inst["stage"] == "pending"

        # Increment to active
        for _ in range(2):
            inst = lm.update_confidence(
                inst["id"], CONFIDENCE_INCREMENT, "confirmed"
            )
        assert inst["confidence"] == 0.5
        assert inst["stage"] == "active"

        # Decrement back to pending
        inst = lm.update_confidence(
            inst["id"], -CONFIDENCE_DECREMENT, "contradicted"
        )
        assert inst["stage"] == "pending"

    def test_evidence_tracking(self, lm):
        inst = lm.create_instinct("test", "ctx")
        lm.update_confidence(inst["id"], 0.1, "first evidence")
        lm.update_confidence(inst["id"], 0.1, "second evidence")
        loaded = lm.get_instinct(inst["id"])
        evidence = loaded.get("evidence", [])
        assert len(evidence) == 2
        assert evidence[0]["detail"] == "first evidence"

    def test_update_nonexistent_returns_none(self, lm):
        result = lm.update_confidence("nope", 0.1, "test")
        assert result is None


# ---- Promotion ----

class TestPromotion:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_promote_high_confidence(self, lm):
        inst = lm.create_instinct("promotable", "ctx", confidence=0.7)
        promoted = lm.promote_instinct(inst["id"])
        assert promoted is not None
        assert promoted["stage"] == "promoted"

        # Verify exists in global scope
        global_inst = lm.get_instinct(inst["id"], scope="global")
        assert global_inst is not None

    def test_promote_low_confidence_rejected(self, lm):
        inst = lm.create_instinct("too low", "ctx", confidence=0.4)
        result = lm.promote_instinct(inst["id"])
        assert result is None

    def test_promote_nonexistent_returns_none(self, lm):
        result = lm.promote_instinct("nope")
        assert result is None


# ---- Global Scope ----

class TestGlobalScope:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_create_global_instinct(self, lm):
        inst = lm.create_instinct(
            "global pattern", "ctx", scope="global"
        )
        global_list = lm.list_instincts(scope="global")
        assert len(global_list) == 1
        assert global_list[0]["pattern"] == "global pattern"

    def test_project_and_global_independent(self, lm):
        lm.create_instinct("project only", "ctx", scope="project")
        lm.create_instinct("global only", "ctx", scope="global")

        assert len(lm.list_instincts(scope="project")) == 1
        assert len(lm.list_instincts(scope="global")) == 1


# ---- Analysis ----

class TestAnalysis:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_analyze_empty(self, lm):
        assert lm.analyze_observations() == []

    def test_analyze_detects_repeated_pattern(self, lm):
        for _ in range(5):
            lm.record_observation("Write", "backend/app/models.py")
        candidates = lm.analyze_observations(window_minutes=1440)
        assert len(candidates) >= 1
        assert candidates[0]["occurrences"] >= 3

    def test_analyze_ignores_low_frequency(self, lm):
        lm.record_observation("Write", "unique_file_1.py")
        lm.record_observation("Edit", "unique_file_2.py")
        candidates = lm.analyze_observations(window_minutes=1440)
        assert len(candidates) == 0


# ---- Pruning ----

class TestPruning:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_prune_removes_old_pending(self, lm):
        inst = lm.create_instinct("old pattern", "ctx", confidence=0.3)

        # Manually backdate the created_at
        path = lm.instincts_dir / f"{inst['id']}.yaml"
        data = _read_yaml(path)
        data["created_at"] = "2025-01-01T00:00:00Z"
        _write_yaml(path, data)

        pruned = lm.prune_pending(max_age_days=30)
        assert pruned == 1
        assert lm.get_instinct(inst["id"]) is None

    def test_prune_keeps_active_instincts(self, lm):
        inst = lm.create_instinct("active", "ctx", confidence=0.6)

        path = lm.instincts_dir / f"{inst['id']}.yaml"
        data = _read_yaml(path)
        data["created_at"] = "2025-01-01T00:00:00Z"
        _write_yaml(path, data)

        pruned = lm.prune_pending(max_age_days=30)
        assert pruned == 0

    def test_prune_empty_dir(self, lm):
        assert lm.prune_pending() == 0


# ---- Reporting ----

class TestReporting:
    @pytest.fixture
    def lm(self, tmp_path):
        return LearningManager(str(tmp_path), global_root=tmp_path / "global")

    def test_format_status_empty(self, lm):
        status = lm.format_status()
        assert "Observations: 0" in status
        assert "Project instincts: 0" in status

    def test_format_status_with_data(self, lm):
        lm.record_observation("Write", "test.py")
        lm.create_instinct("test pattern", "ctx", confidence=0.7)
        status = lm.format_status()
        assert "Observations: 1" in status
        assert "Project instincts: 1" in status
        assert "test pattern" in status


# ---- Input Normalization ----

class TestNormalization:
    def test_normalize_strips_paths(self):
        result = _normalize_input("editing C:\\Users\\test\\file.py")
        assert "<path>" in result

    def test_normalize_strips_line_numbers(self):
        result = _normalize_input("error at line 42")
        assert "line N" in result

    def test_normalize_truncates(self):
        result = _normalize_input("x" * 200)
        assert len(result) == 100
