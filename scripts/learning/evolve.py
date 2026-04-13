"""
Evolve instincts into higher-level structures.

Usage:
    python scripts/learning/evolve.py [project_path]

Groups related high-confidence instincts and suggests
promotion to global scope or transformation into skills.
"""

import argparse
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.lib.learning_manager import (
    LearningManager,
    CONFIDENCE_PROMOTABLE,
)


def main() -> int:
    parser = argparse.ArgumentParser(description="Evolve instincts")
    parser.add_argument("project_path", nargs="?", default=".")
    args = parser.parse_args()

    lm = LearningManager(args.project_path)
    instincts = lm.list_instincts(scope="project")

    if not instincts:
        print("No project instincts found.")
        return 0

    # Group by tags
    tag_groups: dict[str, list[dict]] = defaultdict(list)
    for inst in instincts:
        tags = inst.get("tags", [])
        if isinstance(tags, list):
            for tag in tags:
                tag_groups[tag].append(inst)
        if not tags:
            tag_groups["untagged"].append(inst)

    # Find promotable instincts
    promotable = [
        i for i in instincts
        if i.get("confidence", 0) >= CONFIDENCE_PROMOTABLE
    ]

    # Find clusters (2+ instincts with same tag)
    clusters = {
        tag: insts for tag, insts in tag_groups.items()
        if len(insts) >= 2
    }

    print(f"Total project instincts: {len(instincts)}")
    print()

    if promotable:
        print(f"Promotable to global ({len(promotable)}):")
        for inst in promotable:
            conf = inst.get("confidence", 0)
            pattern = inst.get("pattern", "?")[:60]
            inst_id = inst.get("id", "?")
            print(f"  [{conf:.1f}] {pattern}")
            print(f"         Run: python scripts/learning/promote.py {inst_id}")
        print()

    if clusters:
        print(f"Skill candidates (related clusters):")
        for tag, insts in clusters.items():
            avg_conf = sum(i.get("confidence", 0) for i in insts) / len(insts)
            print(f"  Tag '{tag}' ({len(insts)} instincts, avg conf: {avg_conf:.2f}):")
            for inst in insts[:5]:
                pattern = inst.get("pattern", "?")[:50]
                conf = inst.get("confidence", 0)
                print(f"    [{conf:.1f}] {pattern}")
        print()

    if not promotable and not clusters:
        print("No instincts ready for evolution yet.")
        print("Continue using the framework to build confidence.")

    return 0


if __name__ == "__main__":
    sys.exit(main())
