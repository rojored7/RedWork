"""
Promote an instinct from project scope to global scope.

Usage:
    python scripts/learning/promote.py <instinct_id> [project_path]
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.lib.learning_manager import LearningManager, CONFIDENCE_PROMOTABLE


def main() -> int:
    parser = argparse.ArgumentParser(description="Promote instinct to global")
    parser.add_argument("instinct_id", help="ID of the instinct to promote")
    parser.add_argument("project_path", nargs="?", default=".")
    args = parser.parse_args()

    lm = LearningManager(args.project_path)

    inst = lm.get_instinct(args.instinct_id, scope="project")
    if inst is None:
        print(f"Instinct not found: {args.instinct_id}")
        return 1

    conf = inst.get("confidence", 0)
    if conf < CONFIDENCE_PROMOTABLE:
        print(
            f"Confidence too low for promotion: {conf:.2f} "
            f"(minimum: {CONFIDENCE_PROMOTABLE})"
        )
        return 1

    result = lm.promote_instinct(args.instinct_id)
    if result:
        print(f"Promoted: {result.get('pattern', '?')}")
        print(f"  Confidence: {result.get('confidence', 0):.2f}")
        print(f"  Now available globally.")
        return 0

    print("Promotion failed.")
    return 1


if __name__ == "__main__":
    sys.exit(main())
