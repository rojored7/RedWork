# Claude Enforcement System - Validators & Git Hooks

**Version**: 1.0
**Created**: 2026-03-26
**Purpose**: Automated quality validation and git pre-commit enforcement

---

## Overview

This directory contains the **Quality Gate Enforcement System** - a set of bash scripts that validate code quality and prevent bad code from being committed.

## Directory Structure

```
.claude/
├── README.md                           # This file
├── validators/
│   ├── validate-frontend.sh           # Frontend validation (ESLint + TypeScript)
│   └── validate-backend.sh            # Backend validation (ESLint + Compilation)
└── enforcement/
    ├── enforce-gates.sh               # Master orchestrator (runs all validators)
    └── install-git-hooks.sh           # Installs pre-commit hooks
```

## Components

### 1. Validators (`validators/`)

Individual validation scripts for frontend and backend.

#### `validate-frontend.sh`

Validates frontend code quality:
- **GATE 1**: ESLint (0 errors required, warnings allowed)
- **GATE 2**: TypeScript type-check via `npm run type-check` (0 errors required)

**Usage**:
```bash
bash .claude/validators/validate-frontend.sh
```

**Exit Code**:
- `0` = All gates passed
- `1` = One or more gates failed

#### `validate-backend.sh`

Validates backend code quality:
- **GATE 1**: ESLint (0 errors required, warnings allowed)
- **GATE 2**: TypeScript compilation via `npm run build` (0 errors required)

**Usage**:
```bash
bash .claude/validators/validate-backend.sh
```

**Exit Code**:
- `0` = All gates passed
- `1` = One or more gates failed

### 2. Enforcement (`enforcement/`)

Master orchestration and git hook installation.

#### `enforce-gates.sh`

Master script that runs both validators and reports overall status.

**Usage**:
```bash
# Run all gates
bash .claude/enforcement/enforce-gates.sh

# Skip frontend validation
bash .claude/enforcement/enforce-gates.sh --skip-frontend

# Skip backend validation
bash .claude/enforcement/enforce-gates.sh --skip-backend

# Show help
bash .claude/enforcement/enforce-gates.sh --help
```

**Exit Code**:
- `0` = All gates passed (100% quality achieved)
- `1` = One or more gates failed

**Features**:
- Beautiful colored terminal output with Unicode box drawing
- Clear pass/fail indicators
- Detailed error reporting
- Supports partial execution with flags

#### `install-git-hooks.sh`

Installs pre-commit hook that runs quality gates automatically.

**Usage**:
```bash
bash .claude/enforcement/install-git-hooks.sh
```

**What It Does**:
1. Creates `.git/hooks/pre-commit` script
2. Makes it executable
3. Hook runs `enforce-gates.sh` before every commit
4. Blocks commits if quality gates fail

**Uninstall**:
```bash
rm .git/hooks/pre-commit
```

## Quick Start

### First Time Setup

```bash
# 1. Make scripts executable (if needed)
chmod +x .claude/validators/*.sh
chmod +x .claude/enforcement/*.sh

# 2. Install git hooks
bash .claude/enforcement/install-git-hooks.sh

# 3. Verify installation
bash .claude/enforcement/enforce-gates.sh
```

### Daily Usage

With pre-commit hooks installed, validation happens automatically:

```bash
git add .
git commit -m "feat: your message"

# Quality gates run automatically
# Commit proceeds if gates pass
# Commit aborted if gates fail
```

## Workflow Examples

### Example 1: Successful Commit

```bash
$ git commit -m "feat: add new feature"

Running pre-commit quality gates...

╔════════════════════════════════════════════════════════════╗
║            🛡️  QUALITY GATE ENFORCEMENT  🛡️              ║
║         Ensuring 100% Quality Standards                   ║
╚════════════════════════════════════════════════════════════╝

[GATE 1/2] Frontend Validation
✓ ESLint passed (0 errors, 14 warnings)
✓ TypeScript type-check passed (0 errors)
✓ GATE 1 PASSED

[GATE 2/2] Backend Validation
✓ ESLint passed (0 errors, 127 warnings)
✓ TypeScript compilation passed (0 errors)
✓ GATE 2 PASSED

╔════════════════════════════════════════════════════════════╗
║           ✓✓✓ ALL GATES PASSED ✓✓✓                        ║
║         100% Quality Standards Met                         ║
╚════════════════════════════════════════════════════════════╝

✓ Pre-commit checks passed. Proceeding with commit.

[main abc1234] feat: add new feature
 3 files changed, 50 insertions(+)
```

### Example 2: Failed Commit

```bash
$ git commit -m "feat: add buggy feature"

Running pre-commit quality gates...

╔════════════════════════════════════════════════════════════╗
║            🛡️  QUALITY GATE ENFORCEMENT  🛡️              ║
╚════════════════════════════════════════════════════════════╝

[GATE 1/2] Frontend Validation
✗ ESLint failed with errors

/path/to/file.ts
  42:5  error  'x' is defined but never used  @typescript-eslint/no-unused-vars

✗ GATE 1 FAILED

╔════════════════════════════════════════════════════════════╗
║           ✗✗✗ GATES FAILED ✗✗✗                            ║
║         Fix errors above before proceeding                 ║
╚════════════════════════════════════════════════════════════╝

✗ Pre-commit checks failed. Commit aborted.

Fix the errors above before committing.

To bypass this check (NOT recommended):
  git commit --no-verify
```

### Example 3: Manual Validation During Development

```bash
# Check if your code is ready to commit
$ bash .claude/enforcement/enforce-gates.sh

# If it fails, fix errors and check again
$ bash .claude/enforcement/enforce-gates.sh

# Once it passes, commit
$ git commit -m "..."
```

## Bypassing Checks

### When to Bypass

**ONLY bypass in these scenarios**:
- Emergency hotfix to production
- Experimental branch not intended for merge
- Known false positive from tooling (rare)

**NEVER bypass for**:
- "I'll fix it later"
- "It's just a warning"
- "Works on my machine"

### How to Bypass

```bash
# Bypass pre-commit hook
git commit --no-verify -m "emergency: production hotfix"

# Or disable hook temporarily
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
# Your commits...
mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
```

## Troubleshooting

### Scripts Not Executable

**Symptom**: `Permission denied`

**Solution**:
```bash
chmod +x .claude/validators/*.sh
chmod +x .claude/enforcement/*.sh
```

### Pre-commit Hook Not Running

**Symptom**: Commits succeed without validation

**Solution**:
```bash
# Check if hook exists
ls -la .git/hooks/pre-commit

# Reinstall
bash .claude/enforcement/install-git-hooks.sh

# Verify executable
chmod +x .git/hooks/pre-commit
```

### ESLint Errors Not Showing

**Symptom**: "ESLint failed" but no details

**Solution**:
```bash
# View detailed ESLint output
cat /tmp/frontend-lint.log
cat /tmp/backend-lint.log

# Or run ESLint directly
cd frontend && npm run lint
cd backend && npm run lint
```

### TypeScript Errors Not Showing

**Symptom**: "Type-check failed" but no details

**Solution**:
```bash
# View detailed TypeScript output
cat /tmp/frontend-typecheck.log
cat /tmp/backend-build.log

# Or run directly
cd frontend && npm run type-check
cd backend && npm run build
```

### "command not found" Errors

**Symptom**: Scripts can't find `npm` or `bash`

**Solution**:
```bash
# Ensure Node.js is in PATH
which npm
which node

# If not found
export PATH="$PATH:/usr/local/bin"

# Run scripts explicitly with bash
bash .claude/enforcement/enforce-gates.sh
```

## Quality Standards

### What Must Pass (0 Errors Required)

| Check | Tool | Frontend | Backend |
|-------|------|----------|---------|
| Linting | ESLint | ✅ 0 errors | ✅ 0 errors |
| Type Safety | TypeScript | ✅ 0 type errors | ✅ 0 type errors |
| Compilation | tsc/build | ✅ Must compile | ✅ Must compile |

### What's Allowed (Informational)

| Check | Frontend | Backend |
|-------|----------|---------|
| Warnings | ✅ Allowed (14 warnings) | ✅ Allowed (127 warnings) |
| TODO comments | ✅ Allowed | ✅ Allowed |

**Note**: While warnings are currently allowed, the goal is to reduce them progressively over sprints.

## Integration with CI/CD

The enforcement system is integrated with GitHub Actions:

**File**: `.github/workflows/ci.yml`

**Integration Points**:
- Linting jobs run ESLint without bypasses
- Type-checking jobs run TypeScript validation without bypasses
- Failed checks block merges

**Removed Bypasses**:
```yaml
# BEFORE (allowed failures)
npm run lint || true

# AFTER (enforces quality)
npm run lint
```

## Maintenance

### Updating Validators

To modify validation logic:

1. Edit validator scripts:
```bash
vim .claude/validators/validate-frontend.sh
vim .claude/validators/validate-backend.sh
```

2. Test changes:
```bash
bash .claude/enforcement/enforce-gates.sh
```

3. Commit updates:
```bash
git add .claude/validators/
git commit -m "refactor: improve validator logic"
```

### Adding New Gates

To add additional quality checks:

1. Add to validator script:
```bash
# Example: Add security audit to validate-backend.sh

echo -e "${YELLOW}[3/3] Running security audit...${NC}"
if npm audit --audit-level=high > /tmp/backend-audit.log 2>&1; then
    echo -e "${GREEN}✓ Security audit passed${NC}"
else
    echo -e "${RED}✗ Security audit failed${NC}"
    cat /tmp/backend-audit.log
    VALIDATION_FAILED=1
fi
```

2. Update documentation
3. Test thoroughly
4. Deploy to projects

### Monitoring Effectiveness

Track enforcement impact:

```bash
# Check bypassed commits
git log --all --grep="--no-verify"

# Check warning trends
cd frontend && npm run lint 2>&1 | grep "warning" | wc -l
cd backend && npm run lint 2>&1 | grep "warning" | wc -l

# Check CI/CD failure rate
# → GitHub Actions → View workflow history
```

## FAQ

**Q: Why are warnings allowed but errors aren't?**

A: Warnings indicate potential issues but don't break functionality. Errors indicate actual problems. We enforce 0 errors to ensure code quality while allowing flexibility for warnings that can be progressively fixed.

**Q: Can I disable specific ESLint rules?**

A: Yes, but only after team discussion. Edit `.eslintrc.cjs` or `eslint.config.mjs`:
```javascript
rules: {
  '@typescript-eslint/no-unused-vars': 'warn',  // Downgrade to warning
  'react/no-unescaped-entities': 'off',         // Disable
}
```

**Q: What if I need to commit urgently but gates are failing?**

A: Use `--no-verify` but create a follow-up task:
```bash
git commit --no-verify -m "fix: urgent production hotfix"
# Then immediately create issue to fix quality
```

**Q: How do I know which gate failed?**

A: Output is color-coded and clearly labeled:
```
[GATE 1/2] Frontend Validation
✗ GATE 1 FAILED: Frontend validation failed
```

**Q: Can gates run in parallel for speed?**

A: Currently sequential for clarity. To parallelize, modify `enforce-gates.sh`:
```bash
bash "$VALIDATORS_DIR/validate-frontend.sh" &
FRONTEND_PID=$!
bash "$VALIDATORS_DIR/validate-backend.sh" &
BACKEND_PID=$!
wait $FRONTEND_PID
wait $BACKEND_PID
```

## Best Practices

### ✅ DO

- Run `enforce-gates.sh` before committing
- Fix errors immediately (don't accumulate technical debt)
- Keep dependencies updated
- Use specific ESLint disables, not blanket disables
- Document why you bypass (if you must)

### ❌ DON'T

- Bypass quality gates without good reason
- Accumulate warnings indefinitely
- Disable entire ESLint rulesets
- Skip verification after code changes
- Commit with `--no-verify` as a habit

## Support

For issues or questions:

1. Check this README
2. Check full documentation: `docs/ENFORCEMENT_SYSTEM_GUIDE.md`
3. View validator logs in `/tmp/`
4. Run validators directly for detailed output

---

**System Version**: 1.0
**Last Updated**: 2026-03-26
**Maintained By**: Development Team
