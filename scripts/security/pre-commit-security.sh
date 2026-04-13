#!/bin/bash
# RedWork Pre-Commit Security Hook
# Runs secret scanning on staged files before allowing commit.
#
# Install: copy to .git/hooks/pre-commit or reference from install-workflow-hooks.sh
#
# Exit codes:
#   0 = clean, commit proceeds
#   1 = secrets found, commit blocked

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate scan-secrets.sh relative to this hook
# When installed as git hook, scanner is in the framework scripts
SCANNER=""
POSSIBLE_PATHS=(
    "$SCRIPT_DIR/../security/scan-secrets.sh"
    "$SCRIPT_DIR/../../scripts/security/scan-secrets.sh"
    "$HOME/.claude/redwork/scripts/security/scan-secrets.sh"
)

for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path" ]; then
        SCANNER="$path"
        break
    fi
done

if [ -z "$SCANNER" ]; then
    echo "WARNING: scan-secrets.sh not found. Skipping secret scan."
    echo "Install RedWork framework to enable: python install.py install"
    exit 0
fi

echo "Running secret scan on staged files..."
bash "$SCANNER" --staged

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "COMMIT BLOCKED: Secrets detected in staged files."
    echo "Fix the issues above, then try again."
    echo "To skip (NOT recommended): git commit --no-verify"
fi

exit $EXIT_CODE
