"""
RedWork Learning Manager.

Captures tool observations, detects patterns, and manages instincts
with incremental confidence scoring. Supports project-scoped and
global instincts.

Storage:
  - Observations: .learning/observations.jsonl (JSONL, append-only)
  - Instincts: .learning/instincts/*.yaml (project scope)
  - Global:    ~/.claude/redwork/learning/instincts/*.yaml (global scope)
"""

import json
import os
import re
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


# Confidence thresholds
CONFIDENCE_INITIAL = 0.3
CONFIDENCE_INCREMENT = 0.1
CONFIDENCE_DECREMENT = 0.15
CONFIDENCE_ACTIVE = 0.5
CONFIDENCE_PROMOTABLE = 0.7
CONFIDENCE_MAX = 0.9
CONFIDENCE_ARCHIVE = 0.2

# Analysis thresholds
MIN_OCCURRENCES = 3
DEFAULT_WINDOW_MINUTES = 60
MAX_OBSERVATIONS_FILE_LINES = 10000


def _now_iso() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


_id_counter = 0


def _generate_id() -> str:
    global _id_counter
    _id_counter += 1
    ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    return f"instinct-{ts}-{_id_counter:04d}"


def _write_yaml(path: Path, data: dict) -> None:
    """Write a dict as YAML without requiring PyYAML."""
    lines = []
    for key, value in data.items():
        if isinstance(value, list):
            lines.append(f"{key}:")
            for item in value:
                if isinstance(item, dict):
                    first = True
                    for k, v in item.items():
                        prefix = "  - " if first else "    "
                        lines.append(f"{prefix}{k}: {json.dumps(v)}")
                        first = False
                else:
                    lines.append(f"  - {json.dumps(item)}")
        elif isinstance(value, dict):
            lines.append(f"{key}:")
            for k, v in value.items():
                lines.append(f"  {k}: {json.dumps(v)}")
        elif value is None:
            lines.append(f"{key}: null")
        elif isinstance(value, bool):
            lines.append(f"{key}: {'true' if value else 'false'}")
        elif isinstance(value, (int, float)):
            lines.append(f"{key}: {value}")
        else:
            lines.append(f"{key}: {json.dumps(str(value))}")

    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = str(path) + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        f.write("\n".join(lines) + "\n")
    os.replace(tmp, str(path))


def _read_yaml(path: Path) -> dict:
    """Read a simple YAML file without requiring PyYAML.

    Handles the subset of YAML that _write_yaml produces:
    scalar values (strings, numbers, booleans, null) and
    lists of scalars or dicts.
    """
    if not path.exists():
        return {}

    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    data: dict = {}
    current_key: Optional[str] = None
    current_list: Optional[list] = None
    current_dict_item: Optional[dict] = None

    for raw_line in lines:
        line = raw_line.rstrip("\n")
        stripped = line.strip()

        if not stripped or stripped.startswith("#"):
            continue

        indent = len(line) - len(line.lstrip())

        if indent == 0 and ":" in stripped:
            # Flush any pending list
            if current_key is not None and current_list is not None:
                if current_dict_item is not None:
                    current_list.append(current_dict_item)
                    current_dict_item = None
                data[current_key] = current_list
                current_list = None

            key, _, rest = stripped.partition(":")
            key = key.strip()
            rest = rest.strip()

            if rest == "":
                # Start of a list or dict block
                current_key = key
                current_list = []
            else:
                current_key = None
                data[key] = _parse_yaml_value(rest)

        elif stripped.startswith("- ") and current_list is not None:
            # Flush previous dict item
            if current_dict_item is not None:
                current_list.append(current_dict_item)
                current_dict_item = None

            item_content = stripped[2:].strip()
            if ":" in item_content:
                k, _, v = item_content.partition(":")
                current_dict_item = {k.strip(): _parse_yaml_value(v.strip())}
            else:
                current_list.append(_parse_yaml_value(item_content))

        elif indent > 0 and ":" in stripped and current_key is not None:
            k, _, v = stripped.partition(":")
            k = k.strip()
            v = v.strip()

            if current_dict_item is not None:
                current_dict_item[k] = _parse_yaml_value(v)
            elif current_list is not None:
                # Nested dict without list prefix (simple key-value block)
                if not isinstance(current_list, dict):
                    if len(current_list) == 0:
                        current_list = {}
                        data[current_key] = current_list
                if isinstance(data.get(current_key), dict):
                    data[current_key][k] = _parse_yaml_value(v)

    # Flush remaining list
    if current_key is not None and current_list is not None:
        if current_dict_item is not None:
            current_list.append(current_dict_item)
        if isinstance(current_list, list):
            data[current_key] = current_list

    return data


def _parse_yaml_value(raw: str):
    """Parse a YAML scalar value."""
    if raw == "null" or raw == "~":
        return None
    if raw == "true":
        return True
    if raw == "false":
        return False

    # JSON-encoded string
    if raw.startswith('"') and raw.endswith('"'):
        try:
            return json.loads(raw)
        except json.JSONDecodeError:
            return raw.strip('"')

    # Number
    try:
        if "." in raw:
            return float(raw)
        return int(raw)
    except ValueError:
        pass

    return raw


class LearningManager:
    def __init__(self, project_path: str = ".",
                 global_root: Optional[Path] = None):
        self.project_path = Path(project_path)
        self.learning_dir = self.project_path / ".learning"
        self.observations_file = self.learning_dir / "observations.jsonl"
        self.instincts_dir = self.learning_dir / "instincts"

        if global_root is not None:
            self.global_root = global_root
        else:
            self.global_root = Path.home() / ".claude" / "redwork" / "learning"
        self.global_instincts_dir = self.global_root / "instincts"

    # ---- Observations ----

    def record_observation(self, tool_name: str, input_summary: str,
                           output_summary: str = "",
                           context: Optional[dict] = None) -> dict:
        """Append an observation to the JSONL log."""
        record = {
            "tool": tool_name,
            "input": input_summary[:500],
            "output": output_summary[:500],
            "context": context or {},
            "timestamp": _now_iso(),
        }
        self.observations_file.parent.mkdir(parents=True, exist_ok=True)
        with open(self.observations_file, "a", encoding="utf-8") as f:
            f.write(json.dumps(record) + "\n")
        return record

    def read_observations(self, limit: Optional[int] = None) -> list[dict]:
        """Read observations from the JSONL log."""
        if not self.observations_file.exists():
            return []
        records = []
        with open(self.observations_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        records.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        if limit is not None:
            return records[-limit:]
        return records

    def observation_count(self) -> int:
        """Count observations without loading all into memory."""
        if not self.observations_file.exists():
            return 0
        count = 0
        with open(self.observations_file, "r", encoding="utf-8") as f:
            for line in f:
                if line.strip():
                    count += 1
        return count

    def rotate_observations(self, max_lines: int = MAX_OBSERVATIONS_FILE_LINES) -> int:
        """Archive old observations if file exceeds max_lines."""
        if not self.observations_file.exists():
            return 0

        records = self.read_observations()
        if len(records) <= max_lines:
            return 0

        archive_dir = self.learning_dir / "observations-archive"
        archive_dir.mkdir(parents=True, exist_ok=True)
        ts = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
        archive_file = archive_dir / f"observations-{ts}.jsonl"

        # Archive older records
        to_archive = records[:-max_lines]
        to_keep = records[-max_lines:]

        with open(archive_file, "w", encoding="utf-8") as f:
            for r in to_archive:
                f.write(json.dumps(r) + "\n")

        # Rewrite current file with only recent records
        tmp = str(self.observations_file) + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            for r in to_keep:
                f.write(json.dumps(r) + "\n")
        os.replace(tmp, str(self.observations_file))

        return len(to_archive)

    # ---- Instincts CRUD ----

    def create_instinct(self, pattern: str, context: str,
                        confidence: float = CONFIDENCE_INITIAL,
                        scope: str = "project",
                        tags: Optional[list[str]] = None) -> dict:
        """Create a new instinct YAML file."""
        instinct_id = _generate_id()
        instinct = {
            "id": instinct_id,
            "pattern": pattern,
            "context": context,
            "confidence": round(min(confidence, CONFIDENCE_MAX), 2),
            "stage": "pending" if confidence < CONFIDENCE_ACTIVE else "active",
            "evidence": [],
            "occurrences": 1,
            "created_at": _now_iso(),
            "updated_at": _now_iso(),
            "source_project": self.project_path.name,
            "tags": tags or [],
        }

        target_dir = (self.global_instincts_dir
                       if scope == "global"
                       else self.instincts_dir)
        _write_yaml(target_dir / f"{instinct_id}.yaml", instinct)
        return instinct

    def get_instinct(self, instinct_id: str,
                     scope: str = "project") -> Optional[dict]:
        """Load a single instinct by ID."""
        target_dir = (self.global_instincts_dir
                       if scope == "global"
                       else self.instincts_dir)
        path = target_dir / f"{instinct_id}.yaml"
        if not path.exists():
            return None
        return _read_yaml(path)

    def list_instincts(self, scope: str = "project",
                       min_confidence: float = 0.0) -> list[dict]:
        """List instincts filtered by scope and minimum confidence."""
        target_dir = (self.global_instincts_dir
                       if scope == "global"
                       else self.instincts_dir)

        if not target_dir.exists():
            return []

        instincts = []
        for f in sorted(target_dir.glob("instinct-*.yaml")):
            data = _read_yaml(f)
            if data and data.get("confidence", 0) >= min_confidence:
                instincts.append(data)

        return instincts

    def update_confidence(self, instinct_id: str, delta: float,
                          evidence: str = "",
                          scope: str = "project") -> Optional[dict]:
        """Increment or decrement an instinct's confidence."""
        target_dir = (self.global_instincts_dir
                       if scope == "global"
                       else self.instincts_dir)
        path = target_dir / f"{instinct_id}.yaml"
        if not path.exists():
            return None

        data = _read_yaml(path)
        old_conf = data.get("confidence", CONFIDENCE_INITIAL)
        new_conf = round(max(0.0, min(old_conf + delta, CONFIDENCE_MAX)), 2)
        data["confidence"] = new_conf
        data["updated_at"] = _now_iso()
        data["occurrences"] = data.get("occurrences", 1) + 1

        # Update stage based on confidence
        if new_conf < CONFIDENCE_ARCHIVE:
            data["stage"] = "archived"
        elif new_conf < CONFIDENCE_ACTIVE:
            data["stage"] = "pending"
        else:
            data["stage"] = "active"

        # Add evidence
        if evidence:
            evidence_list = data.get("evidence", [])
            if isinstance(evidence_list, list):
                evidence_list.append({
                    "timestamp": _now_iso(),
                    "detail": evidence[:200],
                })
                # Keep last 20 evidence entries
                data["evidence"] = evidence_list[-20:]

        _write_yaml(path, data)
        return data

    def delete_instinct(self, instinct_id: str,
                        scope: str = "project") -> bool:
        """Delete an instinct file."""
        target_dir = (self.global_instincts_dir
                       if scope == "global"
                       else self.instincts_dir)
        path = target_dir / f"{instinct_id}.yaml"
        if path.exists():
            path.unlink()
            return True
        return False

    # ---- Promotion ----

    def promote_instinct(self, instinct_id: str) -> Optional[dict]:
        """Copy an instinct from project scope to global scope."""
        data = self.get_instinct(instinct_id, scope="project")
        if data is None:
            return None

        if data.get("confidence", 0) < CONFIDENCE_PROMOTABLE:
            return None

        data["stage"] = "promoted"
        data["updated_at"] = _now_iso()

        _write_yaml(
            self.global_instincts_dir / f"{instinct_id}.yaml",
            data,
        )
        return data

    # ---- Analysis ----

    def analyze_observations(
        self, window_minutes: int = DEFAULT_WINDOW_MINUTES
    ) -> list[dict]:
        """Analyze recent observations for repeated patterns.

        Returns a list of candidate patterns with occurrence counts.
        Only includes patterns with >= MIN_OCCURRENCES.
        """
        records = self.read_observations()
        if not records:
            return []

        cutoff = datetime.now(timezone.utc)
        cutoff_iso = (
            cutoff.replace(
                minute=cutoff.minute - window_minutes % 60,
                hour=cutoff.hour - window_minutes // 60,
            ).strftime("%Y-%m-%dT%H:%M:%SZ")
            if window_minutes < 1440
            else ""
        )

        # Filter to recent window
        recent = []
        for r in records:
            ts = r.get("timestamp", "")
            if cutoff_iso and ts < cutoff_iso:
                continue
            recent.append(r)

        if not recent:
            return []

        # Group by tool + normalized input pattern
        pattern_counts: Counter = Counter()
        pattern_examples: dict[str, list[dict]] = {}

        for r in recent:
            tool = r.get("tool", "unknown")
            input_text = r.get("input", "")
            # Normalize: extract action type from input
            key = f"{tool}:{_normalize_input(input_text)}"
            pattern_counts[key] += 1
            if key not in pattern_examples:
                pattern_examples[key] = []
            if len(pattern_examples[key]) < 3:
                pattern_examples[key].append(r)

        candidates = []
        for key, count in pattern_counts.most_common():
            if count < MIN_OCCURRENCES:
                continue
            tool, pattern = key.split(":", 1)
            candidates.append({
                "tool": tool,
                "pattern": pattern,
                "occurrences": count,
                "examples": pattern_examples.get(key, []),
            })

        return candidates

    # ---- Pruning ----

    def prune_pending(self, max_age_days: int = 30) -> int:
        """Remove old pending instincts below active threshold."""
        if not self.instincts_dir.exists():
            return 0

        pruned = 0
        now = datetime.now(timezone.utc)

        for f in list(self.instincts_dir.glob("instinct-*.yaml")):
            data = _read_yaml(f)
            stage = data.get("stage", "pending")
            if stage not in ("pending", "archived"):
                continue

            created = data.get("created_at", "")
            if not created:
                continue

            try:
                created_dt = datetime.fromisoformat(
                    created.replace("Z", "+00:00")
                )
                age_days = (now - created_dt).days
                if age_days > max_age_days:
                    f.unlink()
                    pruned += 1
            except (ValueError, TypeError):
                continue

        return pruned

    # ---- Reporting ----

    def format_status(self) -> str:
        """Format a human-readable status of all instincts."""
        project_instincts = self.list_instincts(scope="project")
        global_instincts = self.list_instincts(scope="global")
        obs_count = self.observation_count()

        lines = []
        lines.append(f"Learning Status: {self.project_path.name}")
        lines.append(f"  Observations: {obs_count}")
        lines.append(
            f"  Project instincts: {len(project_instincts)}"
        )
        lines.append(
            f"  Global instincts: {len(global_instincts)}"
        )

        if project_instincts:
            lines.append("  Project:")
            for inst in sorted(
                project_instincts,
                key=lambda x: x.get("confidence", 0),
                reverse=True,
            ):
                conf = inst.get("confidence", 0)
                stage = inst.get("stage", "?")
                pattern = inst.get("pattern", "?")[:60]
                bar = _confidence_bar(conf)
                lines.append(f"    [{bar}] {conf:.1f} ({stage}) {pattern}")

        if global_instincts:
            lines.append("  Global:")
            for inst in sorted(
                global_instincts,
                key=lambda x: x.get("confidence", 0),
                reverse=True,
            ):
                conf = inst.get("confidence", 0)
                stage = inst.get("stage", "?")
                pattern = inst.get("pattern", "?")[:60]
                bar = _confidence_bar(conf)
                lines.append(f"    [{bar}] {conf:.1f} ({stage}) {pattern}")

        return "\n".join(lines)


def _normalize_input(text: str) -> str:
    """Normalize tool input for pattern grouping.

    Strips file-specific paths and numbers to find common actions.
    """
    # Remove absolute paths
    text = re.sub(r"[A-Z]:\\[^\s]+", "<path>", text)
    text = re.sub(r"/[^\s]+\.[a-z]+", "<path>", text)
    # Remove line numbers
    text = re.sub(r"line\s+\d+", "line N", text, flags=re.IGNORECASE)
    # Remove specific numbers
    text = re.sub(r"\b\d{3,}\b", "N", text)
    # Truncate
    return text[:100]


def _confidence_bar(confidence: float) -> str:
    """Render a simple ASCII confidence bar."""
    filled = int(confidence * 10)
    return "#" * filled + "-" * (10 - filled)
