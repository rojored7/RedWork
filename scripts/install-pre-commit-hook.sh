#!/bin/bash
# Install pre-commit hook that enforces 100% quality standard

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_DIR="$PROJECT_ROOT/.git/hooks"

echo "🔧 Installing Pre-Commit Hook..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOK_DIR"

# Create the pre-commit hook
cat > "$HOOK_DIR/pre-commit" << 'HOOK_EOF'
#!/bin/bash
# Pre-commit hook that enforces 100% quality standard
# This hook REJECTS commits if code doesn't meet quality gates

set -e

echo "🚀 PRE-COMMIT VALIDATION: Checking code quality..."
echo ""

FAILED_GATES=()

# GATE 1: Backend Compilation
echo "🏗️  GATE 1: Backend Compilation..."
cd backend
if ! npm run build > /tmp/pre-commit-build.log 2>&1; then
  echo "❌ GATE 1 FAILED: Backend does not compile"
  echo ""
  cat /tmp/pre-commit-build.log | tail -20
  FAILED_GATES+=("Backend Compilation")
  cd ..
else
  echo "✅ GATE 1 PASSED: Backend compiles (0 errors)"
  cd ..
fi

# GATE 2: Backend Tests
echo "🧪 GATE 2: Backend Tests..."
cd backend
TEST_OUTPUT=$(npm test 2>&1 || true)
if echo "$TEST_OUTPUT" | grep -q "failing"; then
  echo "❌ GATE 2 FAILED: Backend tests failing"
  echo ""
  echo "$TEST_OUTPUT" | grep -A 10 "failing"
  FAILED_GATES+=("Backend Tests")
  cd ..
else
  TESTS_PASSED=$(echo "$TEST_OUTPUT" | grep "Tests:" | awk '{print $2}' || echo "0")
  echo "✅ GATE 2 PASSED: All backend tests passing ($TESTS_PASSED tests)"
  cd ..
fi

# GATE 3: Backend Linting
echo "🔍 GATE 3: Backend Linting..."
cd backend
if ! npm run lint > /tmp/pre-commit-lint-backend.log 2>&1; then
  echo "❌ GATE 3 FAILED: Backend linting errors"
  echo ""
  cat /tmp/pre-commit-lint-backend.log | tail -20
  FAILED_GATES+=("Backend Linting")
  cd ..
else
  echo "✅ GATE 3 PASSED: Backend linting clean"
  cd ..
fi

# GATE 4: Frontend TypeScript
echo "📝 GATE 4: Frontend TypeScript..."
cd frontend
if ! npm run type-check > /tmp/pre-commit-types.log 2>&1; then
  echo "❌ GATE 4 FAILED: TypeScript errors"
  echo ""
  cat /tmp/pre-commit-types.log | tail -20
  FAILED_GATES+=("Frontend TypeScript")
  cd ..
else
  echo "✅ GATE 4 PASSED: TypeScript clean (0 errors)"
  cd ..
fi

# GATE 5: Frontend Build
echo "🏗️  GATE 5: Frontend Build..."
cd frontend
if ! npm run build > /tmp/pre-commit-build-frontend.log 2>&1; then
  echo "❌ GATE 5 FAILED: Frontend build failed"
  echo ""
  cat /tmp/pre-commit-build-frontend.log | tail -20
  FAILED_GATES+=("Frontend Build")
  cd ..
else
  echo "✅ GATE 5 PASSED: Frontend builds successfully"
  cd ..
fi

# GATE 6: Frontend Tests
echo "🧪 GATE 6: Frontend Tests..."
cd frontend
FRONTEND_TEST_OUTPUT=$(npm test -- --run 2>&1 || true)
if echo "$FRONTEND_TEST_OUTPUT" | grep -q "failed"; then
  echo "❌ GATE 6 FAILED: Frontend tests failing"
  echo ""
  echo "$FRONTEND_TEST_OUTPUT" | grep -A 10 "failed"
  FAILED_GATES+=("Frontend Tests")
  cd ..
else
  echo "✅ GATE 6 PASSED: All frontend tests passing"
  cd ..
fi

# GATE 7: Frontend Linting
echo "🔍 GATE 7: Frontend Linting..."
cd frontend
if ! npm run lint > /tmp/pre-commit-lint-frontend.log 2>&1; then
  echo "❌ GATE 7 FAILED: Frontend linting errors"
  echo ""
  cat /tmp/pre-commit-lint-frontend.log | tail -20
  FAILED_GATES+=("Frontend Linting")
  cd ..
else
  echo "✅ GATE 7 PASSED: Frontend linting clean"
  cd ..
fi

# SUMMARY
echo ""
echo "═══════════════════════════════════════════════════════"

if [ ${#FAILED_GATES[@]} -eq 0 ]; then
  echo "✅✅✅ PRE-COMMIT PASSED: All gates passed ✅✅✅"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "✅ Commit allowed"
  exit 0
else
  echo "❌❌❌ PRE-COMMIT FAILED: Commit REJECTED ❌❌❌"
  echo ""
  echo "Failed Gates:"
  for gate in "${FAILED_GATES[@]}"; do
    echo "  - $gate"
  done
  echo ""
  echo "❌ FIX ALL FAILED GATES BEFORE COMMITTING"
  echo "═══════════════════════════════════════════════════════"
  echo ""
  echo "To bypass this check (NOT RECOMMENDED), use:"
  echo "  git commit --no-verify"
  echo ""
  exit 1
fi
HOOK_EOF

# Make the hook executable
chmod +x "$HOOK_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "📍 Location: $HOOK_DIR/pre-commit"
echo ""
echo "🔒 This hook will now run before every commit and REJECT commits if:"
echo "  - Backend doesn't compile"
echo "  - Backend tests fail"
echo "  - Backend linting fails"
echo "  - Frontend doesn't compile"
echo "  - Frontend tests fail"
echo "  - Frontend linting fails"
echo ""
echo "💡 To test the hook, try making a commit:"
echo "  git add ."
echo "  git commit -m \"test commit\""
echo ""
echo "🚨 To bypass (NOT RECOMMENDED), use:"
echo "  git commit --no-verify"
echo ""
