"""
Extract learning patterns from recent observations.

Usage:
    python scripts/learning/learn_extract.py [project_path] [--window MINUTES]

Analyzes observations.jsonl, creates instinct candidates for new patterns,
and updates confidence for existing instincts that match.
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.lib.learning_manager import (
    LearningManager,
    CONFIDENCE_INCREMENT,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Extract learning patterns")
    parser.add_argument("project_path", nargs="?", default=".")
    parser.add_argument("--window", type=int, default=1440,
                        help="Analysis window in minutes (default: 1440 = 24h)")
    args = parser.parse_args()

    lm = LearningManager(args.project_path)
    obs_count = lm.observation_count()

    if obs_count == 0:
        print("No observations found. Use the framework to generate data.")
        return 0

    print(f"Analyzing {obs_count} observations (window: {args.window}min)...")

    candidates = lm.analyze_observations(window_minutes=args.window)

    if not candidates:
        print("No repeated patterns detected (minimum 3 occurrences needed).")
        return 0

    # Check existing instincts to avoid duplicates
    existing = lm.list_instincts(scope="project")
    existing_patterns = {
        inst.get("pattern", ""): inst.get("id", "")
        for inst in existing
    }

    created = 0
    updated = 0

    for candidate in candidates:
        pattern_text = f"{candidate['tool']}: {candidate['pattern']}"

        # Check if similar instinct exists
        matched_id = None
        for ep, eid in existing_patterns.items():
            if candidate["tool"] in ep and candidate["pattern"] in ep:
                matched_id = eid
                break

        if matched_id:
            lm.update_confidence(
                matched_id,
                CONFIDENCE_INCREMENT,
                f"Re-detected with {candidate['occurrences']} occurrences",
            )
            updated += 1
            print(f"  [UPDATE] {pattern_text} (+{CONFIDENCE_INCREMENT})")
        else:
            inst = lm.create_instinct(
                pattern=pattern_text,
                context=f"Detected from {candidate['occurrences']} observations",
                tags=[candidate["tool"].lower()],
            )
            existing_patterns[pattern_text] = inst["id"]
            created += 1
            print(f"  [NEW] {pattern_text} (conf: 0.3)")

    print(f"\nDone: {created} created, {updated} updated.")

    # Rotate if needed
    archived = lm.rotate_observations()
    if archived > 0:
        print(f"Rotated {archived} old observations to archive.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
