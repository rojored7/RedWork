#!/bin/bash

###############################################################################
# PRE-COMMIT HOOK: Port Configuration Enforcement
#
# Purpose: BLOCKS commits that contain unauthorized port changes
#
# This hook is executed BEFORE every git commit
#
# Exit Codes:
#   0 = Commit allowed (port config valid)
#   1 = Commit BLOCKED (unauthorized port changes)
###############################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATOR="$SCRIPT_DIR/../validators/validate-port-configuration.sh"

echo ""
echo "🔒 PRE-COMMIT ENFORCEMENT: Port Configuration Validation"
echo ""

# Check if validator exists
if [ ! -f "$VALIDATOR" ]; then
    echo "❌ CRITICAL: Port validator not found at $VALIDATOR"
    echo "Cannot proceed without validation"
    exit 1
fi

# Run port validation
bash "$VALIDATOR"
VALIDATION_RESULT=$?

if [ $VALIDATION_RESULT -ne 0 ]; then
    echo ""
    echo "❌❌❌ COMMIT BLOCKED ❌❌❌"
    echo ""
    echo "Your commit contains UNAUTHORIZED port changes."
    echo "Fix the port configuration before committing."
    echo ""
    exit 1
fi

echo ""
echo "✅ Port configuration valid - Commit allowed"
echo ""

exit 0
