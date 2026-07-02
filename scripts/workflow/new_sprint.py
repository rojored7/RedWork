#!/usr/bin/env python3
"""
Generate a new sprint CI pipeline and update project state.

Usage:
    python new_sprint.py <sprint-number> [--force]

Example:
    python new_sprint.py 2
    python new_sprint.py 2 --force   # skip previous-sprint confirmation
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description="Generate a new sprint CI pipeline")
    parser.add_argument("sprint", type=int, help="Sprint number")
    parser.add_argument(
        "--force",
        action="store_true",
        help="Continue even if the previous sprint is not completed (no prompt)",
    )
    args = parser.parse_args()

    sprint_num = args.sprint
    sprint_str = f"{sprint_num:02d}"

    project_root = Path.cwd()
    state_file = project_root / ".project-state" / "state.json"
    ci_dir = project_root / ".gitlab" / "ci"
    parent_ci = project_root / ".gitlab-ci.yml"

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

    # Find sprint template
    template_path = None
    for candidate in [
        ci_dir / "_sprint-template.yml",
        Path.home() / ".claude" / "redwork" / "scripts" / "hooks" / "_sprint-template.yml",
    ]:
        if candidate.exists():
            template_path = candidate
            break

    if not template_path:
        # Generate inline
        print("WARNING: No sprint template found. Generating minimal pipeline.")
        template_content = _minimal_template()
    else:
        with open(template_path) as f:
            template_content = f.read()

    # Replace variables
    sprint_ci = template_content.replace("${SPRINT_NUM}", str(sprint_num))
    sprint_ci = sprint_ci.replace("${SPRINT}", str(sprint_num))

    # Write sprint CI file
    ci_dir.mkdir(parents=True, exist_ok=True)
    sprint_file = ci_dir / f"sprint-{sprint_num}.yml"
    with open(sprint_file, "w") as f:
        f.write(sprint_ci)
    print(f"Created: {sprint_file}")

    # Update parent .gitlab-ci.yml to include new sprint stage
    if parent_ci.exists():
        with open(parent_ci) as f:
            parent_content = f.read()

        # Add stage if not present
        stage_name = f"sprint-{sprint_num}"
        if stage_name not in parent_content:
            # Add stage to stages list
            parent_content = parent_content.replace(
                "  - deploy",
                f"  - {stage_name}\n  - deploy"
            )

            # Add trigger block before deploy section
            deploy_marker = "# ============================================================================\n# STAGE 8: DEPLOY"
            if deploy_marker in parent_content:
                sprint_block = f"""# ============================================================================
# STAGE: SPRINT {sprint_num}
# ============================================================================

"sprint-{sprint_num}: pipeline":
  stage: {stage_name}
  trigger:
    include: .gitlab/ci/sprint-{sprint_num}.yml
    strategy: depend
  needs:
    - "sprint-{sprint_num - 1}: pipeline"
  rules:
    - when: manual
      allow_failure: true

"""
                parent_content = parent_content.replace(deploy_marker, sprint_block + deploy_marker)

            with open(parent_ci, "w") as f:
                f.write(parent_content)
            print(f"Updated: {parent_ci} (added sprint-{sprint_num} stage)")

    # Update state.json
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
    print(f"Next: Run Agent 25 (development-orchestrator) to plan and execute.")


def _minimal_template() -> str:
    return """stages:
  - infrastructure
  - development
  - validation

"infrastructure":
  stage: infrastructure
  script: ["echo 'Sprint ${SPRINT_NUM} infrastructure'"]
  rules: [{when: manual}]

"backend-tests":
  stage: development
  needs: ["infrastructure"]
  script: ["echo 'Sprint ${SPRINT_NUM} backend tests'"]
  rules: [{when: manual}]

"frontend-tests":
  stage: development
  needs: ["infrastructure"]
  script: ["echo 'Sprint ${SPRINT_NUM} frontend tests'"]
  rules: [{when: manual}]

"validation":
  stage: validation
  needs: ["backend-tests", "frontend-tests"]
  script: ["echo 'Sprint ${SPRINT_NUM} validation'"]
  rules: [{when: manual}]
"""


if __name__ == "__main__":
    main()
