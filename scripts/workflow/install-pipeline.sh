#!/bin/bash
# ============================================================================
# install-pipeline.sh - Install Framework Pipeline to Existing Project
# ============================================================================
# Use this script to install or update the Framework GitLab CI/CD pipeline
# on an existing project (not a new one created by init-new-project.sh).
#
# Usage:
#   bash scripts/workflow/install-pipeline.sh [TARGET_PROJECT_PATH] [MODE]
#
# Arguments:
#   TARGET_PROJECT_PATH   Path to the target project (default: current dir)
#   MODE                  'copy' (default) or 'remote'
#                          - copy:   Copies full .gitlab-ci.yml to project
#                          - remote: Installs minimal include-based template
#
# Examples:
#   # Install full pipeline to current directory
#   bash install-pipeline.sh
#
#   # Install remote include to another project
#   bash install-pipeline.sh ../my-other-project remote
#
#   # Force reinstall (overwrites existing)
#   bash install-pipeline.sh ../my-project copy --force
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET="${1:-$(pwd)}"
MODE="${2:-copy}"
FORCE=""
for arg in "$@"; do
  [ "$arg" = "--force" ] && FORCE="yes"
done

# Convert to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd)" || {
  echo "ERROR: Target path does not exist: $1"
  exit 1
}

echo "============================================================"
echo "  Framework Pipeline Installer"
echo "============================================================"
echo "  Framework:  $FRAMEWORK_ROOT"
echo "  Target:     $TARGET"
echo "  Mode:       $MODE"
echo "============================================================"
echo ""

# ----------------------------------------------------------------------------
# Safety checks
# ----------------------------------------------------------------------------
if [ "$TARGET" = "$FRAMEWORK_ROOT" ]; then
  echo "ERROR: Cannot install pipeline onto the Framework itself"
  echo "       The Framework already has its own .gitlab-ci.yml"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "ERROR: Target directory does not exist: $TARGET"
  exit 1
fi

# Warn if existing pipeline
if [ -f "$TARGET/.gitlab-ci.yml" ] && [ -z "$FORCE" ]; then
  echo "WARN: $TARGET/.gitlab-ci.yml already exists"
  echo ""
  read -p "Overwrite? [y/N] " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Use --force to skip this prompt."
    exit 0
  fi

  # Backup existing
  BACKUP="$TARGET/.gitlab-ci.yml.backup-$(date +%Y%m%d-%H%M%S)"
  cp "$TARGET/.gitlab-ci.yml" "$BACKUP"
  echo "  Backup created: $BACKUP"
fi

# ----------------------------------------------------------------------------
# Install pipeline (mode: copy)
# ----------------------------------------------------------------------------
if [ "$MODE" = "copy" ]; then
  echo "Installing full pipeline (copy mode)..."

  cp "$FRAMEWORK_ROOT/.gitlab-ci.yml" "$TARGET/.gitlab-ci.yml"
  echo "  OK - .gitlab-ci.yml copied ($(wc -l < "$TARGET/.gitlab-ci.yml") lines)"

  # Copy child pipeline definitions (parent-child architecture)
  if [ -d "$FRAMEWORK_ROOT/.gitlab/ci" ]; then
    mkdir -p "$TARGET/.gitlab/ci"
    cp "$FRAMEWORK_ROOT/.gitlab/ci/"*.yml "$TARGET/.gitlab/ci/"
    CHILD_COUNT=$(ls "$TARGET/.gitlab/ci/"*.yml 2>/dev/null | wc -l)
    echo "  OK - $CHILD_COUNT child pipeline files copied to .gitlab/ci/"
  fi

  mkdir -p "$TARGET/scripts/workflow"

  # Critical validation scripts needed by the pipeline
  for script in validate-no-nestjs-contamination.sh pipeline-helper.sh; do
    if [ -f "$FRAMEWORK_ROOT/scripts/workflow/$script" ]; then
      cp "$FRAMEWORK_ROOT/scripts/workflow/$script" "$TARGET/scripts/workflow/"
      chmod +x "$TARGET/scripts/workflow/$script"
      echo "  OK - scripts/workflow/$script"
    fi
  done

  # Agent validators (validate-agent-*.sh)
  COUNT=0
  for script in "$FRAMEWORK_ROOT/scripts/workflow/"validate-agent-*.sh; do
    [ -f "$script" ] || continue
    cp "$script" "$TARGET/scripts/workflow/"
    chmod +x "$TARGET/scripts/workflow/$(basename "$script")"
    COUNT=$((COUNT + 1))
  done
  echo "  OK - $COUNT agent validators copied"

# ----------------------------------------------------------------------------
# Install pipeline (mode: remote)
# ----------------------------------------------------------------------------
elif [ "$MODE" = "remote" ]; then
  echo "Installing remote include template (remote mode)..."

  if [ ! -f "$FRAMEWORK_ROOT/templates/gitlab-ci-remote-include.yml" ]; then
    echo "ERROR: Template not found: templates/gitlab-ci-remote-include.yml"
    exit 1
  fi

  cp "$FRAMEWORK_ROOT/templates/gitlab-ci-remote-include.yml" "$TARGET/.gitlab-ci.yml"
  echo "  OK - Minimal remote include template installed"
  echo ""
  echo "  IMPORTANT: Edit $TARGET/.gitlab-ci.yml and update:"
  echo "    project: 'rojored7-group/framework'  <- change to your Framework path"

else
  echo "ERROR: Unknown mode: $MODE"
  echo "       Use 'copy' or 'remote'"
  exit 1
fi

# ----------------------------------------------------------------------------
# Create outputs directory if missing
# ----------------------------------------------------------------------------
if [ ! -d "$TARGET/outputs" ]; then
  mkdir -p "$TARGET/outputs"
  echo "  OK - outputs/ directory created"
fi

# ----------------------------------------------------------------------------
# Final report
# ----------------------------------------------------------------------------
echo ""
echo "============================================================"
echo "  INSTALLATION COMPLETE"
echo "============================================================"
echo ""
echo "Next steps:"
echo ""
echo "  1. Review the installed pipeline:"
echo "     cat $TARGET/.gitlab-ci.yml"
echo ""
if [ "$MODE" = "copy" ]; then
echo "  2. Validate pipeline syntax (requires python + pyyaml):"
echo "     cd $TARGET"
echo "     bash scripts/workflow/pipeline-helper.sh validate"
echo "     bash scripts/workflow/pipeline-helper.sh visualize"
echo ""
fi
echo "  3. Commit and push to GitLab:"
echo "     cd $TARGET"
echo "     git add .gitlab-ci.yml scripts/workflow/ outputs/"
echo "     git commit -m 'ci: install Framework pipeline v2.0'"
echo "     git push"
echo ""
echo "  4. Run pipeline in GitLab UI:"
echo "     - Go to CI/CD > Pipelines"
echo "     - Click 'Run pipeline'"
echo "     - Click Play on 'agent:01-product-discovery' (manual start)"
echo ""
echo "============================================================"
