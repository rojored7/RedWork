#!/bin/bash
# ============================================================================
# validate-no-nestjs-contamination.sh
# ============================================================================
# Validates that critical framework files do not contain NestJS references
# (except when explicitly marked as PROHIBITED or as a violation example).
#
# Framework mandate: Backend MUST be FastAPI (Python). NestJS is PROHIBITED.
#
# This script is a GATE that prevents regression of the FastAPI mandate.
# Runs in post-commit hook and CI pipeline.
#
# Exit codes:
#   0 = PASS (no contamination detected)
#   1 = FAIL (contamination found, must fix before proceeding)
# ============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRAMEWORK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "============================================================================"
echo "FastAPI Mandate Validator - NestJS Contamination Check"
echo "============================================================================"
echo "Framework root: $FRAMEWORK_ROOT"
echo ""

# ----------------------------------------------------------------------------
# Files that MUST be clean (no NestJS references at all, except prohibited)
# ----------------------------------------------------------------------------
CRITICAL_FILES=(
  "agents/architecture-decision.md"
  "agents/05c-api-first-specification-agent.md"
  "agents/backend-fastapi-dev.md"
  "agents/09b-implementation-contract-generator-agent.md"
  "agents/04b-security-by-design-agent.md"
  "agents/sprint-orchestrator.md"
  "agents/backend-test-agent.md"
  "skills/openapi-code-generation.md"
  "skills/configuration-management.md"
  "skills/security-best-practices.md"
  "skills/ddd-clean-architecture.md"
  "skills/typescript-quality-standards.md"
  "scripts/hooks/post-wave-4-api.sh"
)

# ----------------------------------------------------------------------------
# Patterns that indicate NestJS usage (forbidden unless marked PROHIBITED)
# ----------------------------------------------------------------------------
FORBIDDEN_PATTERNS=(
  "NestJS"
  "nestjs"
  "@nestjs"
  "class-validator"
  "@Injectable"
  "@UseGuards"
  "@UseInterceptors"
  "ValidationPipe"
  "NestFactory"
  "INestApplication"
  "ThrottlerModule"
  "ThrottlerGuard"
  "ConfigModule"
  "TypeOrmModule"
  "JwtService.*@nestjs"
)

# ----------------------------------------------------------------------------
# Allowed context patterns (NestJS is OK when marked this way)
# ----------------------------------------------------------------------------
ALLOWED_CONTEXT='PROHIBITED|DO NOT|NOT RECOMMEND|violation|FP-001|instead of|AVOID|REPLACE|replaced|was removed|legacy detection|Framework detection|in dependencies'

TOTAL_ERRORS=0
TOTAL_WARNINGS=0

# ----------------------------------------------------------------------------
# Check each critical file
# ----------------------------------------------------------------------------
for rel_path in "${CRITICAL_FILES[@]}"; do
  file="$FRAMEWORK_ROOT/$rel_path"

  if [ ! -f "$file" ]; then
    echo "WARN: File not found: $rel_path (skipping)"
    TOTAL_WARNINGS=$((TOTAL_WARNINGS + 1))
    continue
  fi

  FILE_ERRORS=0

  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    # Find lines with the forbidden pattern that are NOT in allowed context
    matches=$(grep -n -i "$pattern" "$file" 2>/dev/null | grep -v -iE "$ALLOWED_CONTEXT" || true)

    if [ -n "$matches" ]; then
      if [ $FILE_ERRORS -eq 0 ]; then
        echo ""
        echo "FAIL: $rel_path"
      fi
      echo "  Pattern '$pattern' found in non-prohibited context:"
      echo "$matches" | head -5 | sed 's/^/    /'
      FILE_ERRORS=$((FILE_ERRORS + 1))
      TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    fi
  done

  if [ $FILE_ERRORS -eq 0 ]; then
    echo "OK: $rel_path"
  fi
done

# ----------------------------------------------------------------------------
# Verify FastAPI mandate exists in Agent 04
# ----------------------------------------------------------------------------
echo ""
echo "----------------------------------------------------------------------------"
echo "Verifying FastAPI mandate in Agent 04..."
echo "----------------------------------------------------------------------------"

ARCH_FILE="$FRAMEWORK_ROOT/agents/architecture-decision.md"

if ! grep -q "NON-NEGOTIABLE.*FastAPI" "$ARCH_FILE"; then
  echo "FAIL: Agent 04 missing FastAPI mandate"
  echo "  Expected: 'NON-NEGOTIABLE: All backend services MUST use FastAPI'"
  echo "  Location: $ARCH_FILE section 'Technology Stack Recommendations'"
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
else
  echo "OK: Agent 04 contains FastAPI mandate"
fi

if ! grep -q "PROHIBITED.*NestJS\|NestJS.*PROHIBITED" "$ARCH_FILE"; then
  echo "FAIL: Agent 04 missing NestJS prohibition"
  echo "  Expected: 'NestJS (TypeScript) - PROHIBITED for backend'"
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
else
  echo "OK: Agent 04 explicitly prohibits NestJS"
fi

# ----------------------------------------------------------------------------
# Final verdict
# ----------------------------------------------------------------------------
echo ""
echo "============================================================================"
echo "VALIDATION SUMMARY"
echo "============================================================================"
echo "Errors:   $TOTAL_ERRORS"
echo "Warnings: $TOTAL_WARNINGS"
echo ""

if [ $TOTAL_ERRORS -gt 0 ]; then
  echo "RESULT: FAIL - NestJS contamination detected in framework"
  echo ""
  echo "ACTION REQUIRED:"
  echo "  1. Review files listed above"
  echo "  2. Replace NestJS/TypeScript backend code with FastAPI/Python equivalents"
  echo "  3. Ensure any remaining NestJS mentions are in 'PROHIBITED' context only"
  echo "  4. Re-run this validator until it passes"
  echo ""
  echo "The framework mandate is: Backend MUST use FastAPI. No exceptions."
  exit 1
fi

echo "RESULT: PASS - No NestJS contamination detected"
echo "Framework FastAPI mandate is intact."
exit 0
