#!/usr/bin/env python3
"""
RedWork Agent Renaming Script.

Renames all agent files to follow the unified numbering scheme
and updates all cross-references across the codebase.
"""

import os
import re
import shutil
from pathlib import Path

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
AGENTS_DIR = FRAMEWORK_ROOT / "agents"

# Old name -> New name mapping
RENAME_MAP = {
    # Discovery
    "01-product-discovery.md": "01-product-discovery.md",  # no change
    "02-domain-modeling-agent.md": "02-domain-modeling.md",
    "context-mapping-agent.md": "03-context-mapping.md",
    "architecture-decision.md": "04-architecture-decision.md",
    "04b-security-by-design-agent.md": "04b-security-by-design.md",
    "service-design-architect.md": "05-service-design.md",
    "05b-technical-design-validator-agent.md": "05b-technical-design-validator.md",
    # Planning
    "epic-generation.md": "06-epic-generation.md",
    "user-story-generator.md": "07-user-story-generation.md",
    "tech-lead-delivery.md": "08-tech-lead-delivery.md",
    "sprint-orchestrator.md": "09-sprint-orchestrator.md",
    # API Contract (renumbered)
    "05c-api-first-specification-agent.md": "10-api-specification.md",
    "09b-implementation-contract-generator-agent.md": "11-implementation-contract.md",
    # Infrastructure
    "infrastructure-deployment.md": "12-infrastructure-deployment.md",
    # Backend TDD
    "backend-test-agent.md": "13-backend-test.md",
    "backend-fastapi-dev.md": "14-backend-development.md",
    # Frontend TDD
    "frontend-test-auditor.md": "15-frontend-test.md",
    "frontend-development.md": "16-frontend-development.md",
    # Validation
    "integration-test-validator.md": "17-integration-test.md",
    "e2e-test-validator.md": "18-e2e-test.md",
    "smoke-test-validator.md": "19-smoke-test.md",
    "linting-validator.md": "20-linting-validator.md",
    "security-review-agent.md": "21-security-review.md",
    # Quality
    "22-design-compliance-validator.md": "22-design-compliance.md",
    "23-quick-reference-generator.md": "23-quick-reference.md",
    "24-build-deploy-analyzer.md": "24-build-deploy.md",
    "25-development-orchestrator.md": "25-development-orchestrator.md",  # no change
    # Auxiliaries (move to no-number)
    "00-project-type-detector.md": "project-type-detector.md",
    "06bis-configuration-analyzer.md": "configuration-analyzer.md",
    "07bis-hidden-complexity-analyzer.md": "hidden-complexity-analyzer.md",
    "04c-agent-introspection-debugging.md": "agent-introspection-debugging.md",
    "21-learning-agent.md": "learning-agent.md",
}

# Frontmatter name updates (old name: -> new name:)
FRONTMATTER_MAP = {
    "02-Domain-Modeling-Agent": "02-Domain-Modeling",
    "03-Context-Mapping-Agent": "03-Context-Mapping",
    "04-Architecture-Decision-Agent": "04-Architecture-Decision",
    "04b-Security-By-Design-Agent": "04b-Security-By-Design",
    "05-Service-Design-Agent": "05-Service-Design",
    "05b-Technical-Design-Validator": "05b-Technical-Design-Validator",
    "05c-API-First-Specification-Agent": "10-API-Specification",
    "06-Epic-Generation-Agent": "06-Epic-Generation",
    "07-User-Story-Generation-Agent": "07-User-Story-Generation",
    "08-Tech-Lead-Delivery-Agent": "08-Tech-Lead-Delivery",
    "09-Sprint-Orchestrator-Agent": "09-Sprint-Orchestrator",
    "09b-Implementation-Contract-Generator-Agent": "11-Implementation-Contract",
    "10-Backend-Development-Agent": "14-Backend-Development",
    "11-Frontend-Development-Agent": "16-Frontend-Development",
    "12-Infrastructure-Development-Agent": "12-Infrastructure-Deployment",
    "13-Backend-Test-Agent": "13-Backend-Test",
    "14-Frontend-Test-Agent": "15-Frontend-Test",
    "15-Integration-Test-Agent": "17-Integration-Test",
    "16-E2E-Test-Agent": "18-E2E-Test",
    "18-smoke-test-validator": "19-Smoke-Test",
    "19-security-review-agent": "21-Security-Review",
    "20-linting-validator": "20-Linting-Validator",
    "00-Project-Type-Detector": "Project-Type-Detector",
}

# Text replacements for cross-references (applied to ALL files)
TEXT_REPLACEMENTS = [
    # Agent number references in prose
    ("Agent 05c", "Agent 10"),
    ("Agent 09b", "Agent 11"),
    ("Agent 10 (Backend Development)", "Agent 14 (Backend Development)"),
    ("Agent 11 (Frontend Development)", "Agent 16 (Frontend Development)"),
    ("Agent 13 (Backend Test", "Agent 13 (Backend Test"),  # no change needed
    ("Agent 14 (Frontend Test", "Agent 15 (Frontend Test"),
    ("Agent 15 (Integration", "Agent 17 (Integration"),
    ("Agent 16 (E2E", "Agent 18 (E2E"),
    ("Agent 18 (Smoke", "Agent 19 (Smoke"),
    ("Agent 19 (Security", "Agent 21 (Security"),
    ("Agent 00", "Project Type Detector"),
    ("agent 00", "project-type-detector"),
    # File references
    ("05c_api_specification", "10_api_specification"),
    ("05c_api_client_specification", "10_api_client_specification"),
    ("05c_openapi_validation_report", "10_openapi_validation_report"),
    ("09b_implementation_contract", "11_implementation_contract"),
    # Validator script references
    ("validate-agent-06bis", "validate-agent-config-analyzer"),
    ("validate-agent-07bis", "validate-agent-hidden-complexity"),
    ("validate-agent-00", "validate-agent-detector"),
    # Agent file references
    ("05c-api-first-specification-agent", "10-api-specification"),
    ("09b-implementation-contract-generator-agent", "11-implementation-contract"),
    ("backend-fastapi-dev", "14-backend-development"),
    ("frontend-test-auditor", "15-frontend-test"),
    ("backend-test-agent", "13-backend-test"),
    ("frontend-development", "16-frontend-development"),
    ("06bis-configuration-analyzer", "configuration-analyzer"),
    ("07bis-hidden-complexity-analyzer", "hidden-complexity-analyzer"),
    ("00-project-type-detector", "project-type-detector"),
    ("04c-agent-introspection-debugging", "agent-introspection-debugging"),
]


def rename_files():
    """Rename agent files according to RENAME_MAP."""
    renamed = 0
    for old_name, new_name in RENAME_MAP.items():
        old_path = AGENTS_DIR / old_name
        new_path = AGENTS_DIR / new_name

        if old_name == new_name:
            continue

        if not old_path.exists():
            print(f"  SKIP (not found): {old_name}")
            continue

        if new_path.exists() and old_path != new_path:
            print(f"  CONFLICT: {new_name} already exists, removing old")
            old_path.unlink()
            renamed += 1
            continue

        # Use git mv for proper tracking
        os.system(f'cd "{FRAMEWORK_ROOT}" && git mv "agents/{old_name}" "agents/{new_name}" 2>/dev/null')
        if new_path.exists():
            print(f"  RENAMED: {old_name} -> {new_name}")
            renamed += 1
        else:
            # Fallback to regular rename
            shutil.move(str(old_path), str(new_path))
            print(f"  MOVED: {old_name} -> {new_name}")
            renamed += 1

    return renamed


def update_frontmatter():
    """Update the 'name:' field in agent frontmatter."""
    updated = 0
    for agent_file in AGENTS_DIR.glob("*.md"):
        content = agent_file.read_text(encoding="utf-8", errors="replace")

        for old_name, new_name in FRONTMATTER_MAP.items():
            if f"name: {old_name}" in content:
                content = content.replace(f"name: {old_name}", f"name: {new_name}")
                updated += 1

        agent_file.write_text(content, encoding="utf-8")

    return updated


def update_cross_references():
    """Update agent references across all files in the repo."""
    updated_files = 0

    # Files to scan
    scan_patterns = [
        "agents/*.md",
        "skills/*.md",
        "scripts/workflow/*.sh",
        "scripts/workflow/*.py",
        "scripts/hooks/*",
        "scripts/*.sh",
        ".claude/hooks/*.sh",
        ".gitlab/ci/*.yml",
        ".gitlab-ci.yml",
        "CLAUDE.md",
        "README.md",
        "AGENT_SEQUENCE.md",
        "install.py",
    ]

    files_to_update = set()
    for pattern in scan_patterns:
        files_to_update.update(FRAMEWORK_ROOT.glob(pattern))

    for filepath in sorted(files_to_update):
        if not filepath.is_file():
            continue
        try:
            content = filepath.read_text(encoding="utf-8", errors="replace")
        except Exception:
            continue

        original = content
        for old_text, new_text in TEXT_REPLACEMENTS:
            if old_text in content:
                content = content.replace(old_text, new_text)

        if content != original:
            filepath.write_text(content, encoding="utf-8")
            print(f"  UPDATED: {filepath.relative_to(FRAMEWORK_ROOT)}")
            updated_files += 1

    return updated_files


def rename_validator_scripts():
    """Rename validate-agent-XX.sh scripts to match new numbering."""
    workflow_dir = FRAMEWORK_ROOT / "scripts" / "workflow"

    validator_renames = {
        "validate-agent-06bis.sh": "validate-agent-config-analyzer.sh",
        "validate-agent-07bis.sh": "validate-agent-hidden-complexity.sh",
        "validate-agent-00.sh": "validate-agent-detector.sh",
    }

    renamed = 0
    for old_name, new_name in validator_renames.items():
        old_path = workflow_dir / old_name
        new_path = workflow_dir / new_name
        if old_path.exists():
            os.system(f'cd "{FRAMEWORK_ROOT}" && git mv "scripts/workflow/{old_name}" "scripts/workflow/{new_name}" 2>/dev/null')
            if not new_path.exists():
                shutil.move(str(old_path), str(new_path))
            print(f"  RENAMED: {old_name} -> {new_name}")
            renamed += 1

    return renamed


def main():
    print("=" * 60)
    print("RedWork Agent Renaming")
    print("=" * 60)

    print("\n1. Renaming agent files...")
    n = rename_files()
    print(f"   {n} files renamed\n")

    print("2. Updating frontmatter...")
    n = update_frontmatter()
    print(f"   {n} frontmatter entries updated\n")

    print("3. Renaming validator scripts...")
    n = rename_validator_scripts()
    print(f"   {n} scripts renamed\n")

    print("4. Updating cross-references...")
    n = update_cross_references()
    print(f"   {n} files updated\n")

    print("=" * 60)
    print("Renaming complete.")
    print("Review changes with: git diff --stat")
    print("=" * 60)


if __name__ == "__main__":
    main()
