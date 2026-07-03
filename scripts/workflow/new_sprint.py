#!/usr/bin/env python3
"""
Register a new sprint in project state.

v2.3: the GitLab child-pipeline generation was removed with the CI theater.
The gate engine consumes .project-state/sprint_*_tasks.json and
outputs/09_sprint_plan/ — no CI YAML is involved in sprint mechanics.

Usage:
    python new_sprint.py <sprint-number> [--force]

Example:
    python new_sprint.py 2
    python new_sprint.py 2 --force   # skip previous-sprint confirmation
"""

import argparse
import json
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Register a new sprint in project state")
    parser.add_argument("sprint", type=int, help="Sprint number")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Continue even if the previous sprint is not completed (no prompt)",
    )
    args = parser.parse_args()

    sprint_num = args.sprint
    project_root = Path.cwd()
    state_file = project_root / ".project-state" / "state.json"

    # Validate state
    if not state_file.exists():
        print("ERROR: .project-state/state.json not found.")
        print("Initialize project first: python install.py init <name>")
        sys.exit(1)

    with open(state_file) as f:
        state = json.load(f)

    # Check previous sprint completed (if sprint > 1)
    if sprint_num > 1:
        prev_key = str(sprint_num - 1)
        prev_sprint = state.get("sprints", {}).get(prev_key, {})
        if prev_sprint.get("status") != "completed":
            print(f"WARNING: Sprint {sprint_num - 1} is not marked as completed.")
            print(f"  Status: {prev_sprint.get('status', 'not started')}")
            if args.force:
                print("  --force given: continuing anyway.")
            elif not sys.stdin.isatty():
                print("ERROR: Non-interactive environment. Re-run with --force to continue.")
                sys.exit(1)
            else:
                response = input("Continue anyway? [y/N]: ").strip().lower()
                if response != "y":
                    sys.exit(0)

    # Register sprint in state.json
    sprint_key = str(sprint_num)
    if "sprints" not in state:
        state["sprints"] = {}

    state["sprints"][sprint_key] = {
        "status": "pending",
        "created_at": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "waves": {},
    }

    with open(state_file, "w") as f:
        json.dump(state, f, indent=2)
    print(f"Updated: {state_file} (added sprint {sprint_num})")

    print(f"\nSprint {sprint_num} ready.")
    print("Next: Run Agent 25 (development-orchestrator) to plan and execute.")


if __name__ == "__main__":
    main()
