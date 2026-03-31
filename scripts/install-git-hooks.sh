#!/bin/bash
# Install Git Hooks - CAPA 2 Setup
# Run this script ONCE after cloning the repository
#
# Usage: bash scripts/install-git-hooks.sh

set -e

echo ""
echo "📦 INSTALLING GIT HOOKS (CAPA 2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if .git directory exists
if [ ! -d ".git" ]; then
  echo "❌ ERROR: .git directory not found"
  echo "   Run this script from the project root"
  exit 1
fi

# Backup existing hooks if they exist
if [ -f ".git/hooks/pre-commit" ]; then
  echo "📋 Backing up existing pre-commit hook..."
  cp .git/hooks/pre-commit .git/hooks/pre-commit.backup
fi

if [ -f ".git/hooks/pre-push" ]; then
  echo "📋 Backing up existing pre-push hook..."
  cp .git/hooks/pre-push .git/hooks/pre-push.backup
fi

# Install pre-commit hook
echo "🔧 Installing pre-commit hook..."
cat > .git/hooks/pre-commit << 'EOFHOOK'
#!/bin/bash
# PRE-COMMIT HOOK - CAPA 2: Git Hook Enforcement
# This hook runs BEFORE every commit to validate code quality
#
# To bypass (NOT RECOMMENDED): git commit --no-verify

set -e

echo ""
echo "🔒 PRE-COMMIT VALIDATION (CAPA 2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

FAILED_GATES=()

# ============================================
# GATE 1: BACKEND VALIDATION
# ============================================
if [ -d "backend" ]; then
  echo "📦 Validating Backend..."

  # Check if backend has changes
  if git diff --cached --name-only | grep -q "^backend/"; then
    echo "  → Backend files changed, running validations..."

    cd backend

    # Compilation
    echo "  🏗️  Compiling..."
    if ! npm run build > /dev/null 2>&1; then
      echo "  ❌ Backend compilation FAILED"
      FAILED_GATES+=("Backend Compilation")
    else
      echo "  ✅ Compilation OK"
    fi

    # Linting
    echo "  🧹 Linting..."
    if ! npm run lint > /dev/null 2>&1; then
      echo "  ❌ Backend linting FAILED"
      FAILED_GATES+=("Backend Linting")
    else
      echo "  ✅ Linting OK"
    fi

    # Tests
    echo "  🧪 Running tests..."
    if ! npm test > /dev/null 2>&1; then
      echo "  ❌ Backend tests FAILED"
      FAILED_GATES+=("Backend Tests")
    else
      echo "  ✅ Tests OK"
    fi

    cd ..
  else
    echo "  ℹ️  No backend changes, skipping..."
  fi
fi

# ============================================
# GATE 2: FRONTEND VALIDATION
# ============================================
if [ -d "frontend" ]; then
  echo ""
  echo "⚛️  Validating Frontend..."

  # Check if frontend has changes
  if git diff --cached --name-only | grep -q "^frontend/"; then
    echo "  → Frontend files changed, running validations..."

    cd frontend

    # TypeScript check
    echo "  📘 Type checking..."
    if ! npm run type-check > /dev/null 2>&1; then
      echo "  ❌ TypeScript errors found"
      FAILED_GATES+=("Frontend TypeScript")
    else
      echo "  ✅ TypeScript OK"
    fi

    # Build
    echo "  🏗️  Building..."
    if ! npm run build > /dev/null 2>&1; then
      echo "  ❌ Frontend build FAILED"
      FAILED_GATES+=("Frontend Build")
    else
      echo "  ✅ Build OK"
    fi

    # Linting
    echo "  🧹 Linting..."
    if ! npm run lint > /dev/null 2>&1; then
      echo "  ❌ Frontend linting FAILED"
      FAILED_GATES+=("Frontend Linting")
    else
      echo "  ✅ Linting OK"
    fi

    # Tests
    echo "  🧪 Running tests..."
    if ! npm test run > /dev/null 2>&1; then
      echo "  ❌ Frontend tests FAILED"
      FAILED_GATES+=("Frontend Tests")
    else
      echo "  ✅ Tests OK"
    fi

    cd ..
  else
    echo "  ℹ️  No frontend changes, skipping..."
  fi
fi

# ============================================
# RESULT
# ============================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ ${#FAILED_GATES[@]} -eq 0 ]; then
  echo "✅ PRE-COMMIT PASSED - All validations OK"
  echo ""
  echo "Committing changes..."
  exit 0
else
  echo "❌ PRE-COMMIT FAILED - ${#FAILED_GATES[@]} gate(s) failed:"
  echo ""
  for gate in "${FAILED_GATES[@]}"; do
    echo "  ❌ $gate"
  done
  echo ""
  echo "🔧 Fix these issues before committing"
  echo ""
  echo "To bypass (NOT RECOMMENDED):"
  echo "  git commit --no-verify"
  echo ""
  exit 1
fi
EOFHOOK

chmod +x .git/hooks/pre-commit
echo "✅ pre-commit hook installed"

# Install pre-push hook
echo "🔧 Installing pre-push hook..."
cat > .git/hooks/pre-push << 'EOFHOOK2'
#!/bin/bash
# PRE-PUSH HOOK - CAPA 2: Git Hook Enforcement
# This hook runs BEFORE every push to validate sprint baseline
#
# To bypass (NOT RECOMMENDED): git push --no-verify

set -e

echo ""
echo "🔒 PRE-PUSH VALIDATION (CAPA 2)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "⚠️  Running full sprint baseline validation..."
echo "  This may take 2-3 minutes..."
echo ""

# Get current sprint number from branch or use 'current'
SPRINT_NUMBER="current"
if [[ $(git branch --show-current) =~ sprint-([0-9]+) ]]; then
  SPRINT_NUMBER="${BASH_REMATCH[1]}"
fi

# Run sprint baseline enforcer
if [ -f "scripts/enforce-sprint-baseline.sh" ]; then
  bash scripts/enforce-sprint-baseline.sh "$SPRINT_NUMBER"
  EXIT_CODE=$?

  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ PRE-PUSH PASSED - Sprint baseline validated"
    echo ""
    echo "Pushing changes..."
    exit 0
  else
    echo "❌ PRE-PUSH FAILED - Sprint baseline not met"
    echo ""
    echo "🔧 Fix failing gates before pushing"
    echo ""
    echo "To see details:"
    echo "  cat .project-orchestration/sprint-${SPRINT_NUMBER}-baseline-report-*.md"
    echo ""
    echo "To bypass (NOT RECOMMENDED):"
    echo "  git push --no-verify"
    echo ""
    exit 1
  fi
else
  echo "⚠️  WARNING: enforce-sprint-baseline.sh not found"
  echo "   Skipping baseline validation"
  echo ""
  echo "✅ PRE-PUSH PASSED (with warning)"
  exit 0
fi
EOFHOOK2

chmod +x .git/hooks/pre-push
echo "✅ pre-push hook installed"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ GIT HOOKS INSTALLED SUCCESSFULLY"
echo ""
echo "Installed hooks:"
echo "  • pre-commit → Validates code before commits"
echo "  • pre-push → Validates sprint baseline before push"
echo ""
echo "To bypass hooks (NOT RECOMMENDED):"
echo "  git commit --no-verify"
echo "  git push --no-verify"
echo ""
echo "To uninstall:"
echo "  rm .git/hooks/pre-commit .git/hooks/pre-push"
echo ""
