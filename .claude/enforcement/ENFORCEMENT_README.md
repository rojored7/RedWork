# Enforcement System

## Purpose

This directory contains **ENFORCEMENT** mechanisms that **PREVENT** unauthorized changes to critical project configuration.

## Why Enforcement?

```
PROBLEM: Agents (including Claude) modify configuration arbitrarily
         - Change ports without authorization
         - Break integration between services
         - Cause 502 errors and deployment failures

SOLUTION: AUTOMATED ENFORCEMENT that BLOCKS unauthorized changes
          - Validators check configuration matches official spec
          - Pre-commit hooks BLOCK commits with violations
          - Post-commit hooks verify no violations slipped through
```

## Enforcement Mechanisms

### 1. Port Configuration Enforcement

**File**: `pre-commit-port-validation.sh`

**What it does**:
- Runs BEFORE every git commit
- Validates all ports in code match `runtime-infrastructure.json`
- **BLOCKS commit** if unauthorized port changes detected

**Files validated**:
- `backend/src/main.ts` - Backend listen port
- `frontend/vite.config.ts` - Frontend port and proxy target
- `backend/.env*` - Environment variable ports
- `docker-compose.yml` - Container port mappings

**How to use**:
```bash
# Install as git hook
ln -sf ../../.claude/enforcement/pre-commit-port-validation.sh .git/hooks/pre-commit

# Run manually
bash .claude/enforcement/pre-commit-port-validation.sh
```

**Expected behavior**:
```bash
# If ports are valid:
✅ Port configuration valid - Commit allowed

# If ports are invalid:
❌❌❌ COMMIT BLOCKED ❌❌❌
Your commit contains UNAUTHORIZED port changes.
```

### 2. Configuration Validator

**File**: `../validators/validate-port-configuration.sh`

**What it does**:
- Reads official port configuration from `runtime-infrastructure.json`
- Checks EVERY file that might contain port configuration
- Reports ALL mismatches

**Can be run standalone**:
```bash
bash .claude/validators/validate-port-configuration.sh
```

## Installation

### Automatic Installation (Recommended)

```bash
# Run setup script
bash scripts/setup-enforcement-system.sh
```

This will:
1. Install all validators
2. Install git pre-commit hooks
3. Verify enforcement is active
4. Run initial validation

### Manual Installation

```bash
# Install pre-commit hook
ln -sf ../../.claude/enforcement/pre-commit-port-validation.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

# Make validators executable
chmod +x .claude/validators/*.sh
chmod +x .claude/enforcement/*.sh

# Test enforcement
bash .claude/validators/validate-port-configuration.sh
```

## How Enforcement Works

### Before Commit:

```
Developer/Agent tries to commit
         ↓
Pre-commit hook runs
         ↓
Port validator checks configuration
         ↓
    ┌────┴────┐
    │         │
  Valid    Invalid
    │         │
    ↓         ↓
Commit    BLOCKED
Allowed   with error
```

### Validation Process:

1. **Read official config** from `runtime-infrastructure.json`
2. **Scan all files** that might contain ports:
   - TypeScript config files
   - Environment files
   - Docker config
3. **Compare ports** in code vs official config
4. **Report violations** with exact file/line
5. **Block or allow** based on validation result

## Official Port Configuration

**Source of Truth**: `.project-orchestration/runtime-infrastructure.json`

```json
{
  "services": [
    {
      "service_name": "Backend API",
      "final_external_port": 8010  ← OFFICIAL
    },
    {
      "service_name": "Frontend Application",
      "final_external_port": 3010  ← OFFICIAL
    },
    {
      "service_name": "PostgreSQL Database",
      "final_external_port": 5434  ← OFFICIAL
    },
    {
      "service_name": "Redis Cache",
      "final_external_port": 6381  ← OFFICIAL
    }
  ]
}
```

**NO CODE CAN OVERRIDE THESE PORTS WITHOUT AUTHORIZATION**

## When Validation Fails

```bash
❌ UNAUTHORIZED PORT CHANGE in frontend/vite.config.ts (proxy target)
   Found: localhost:8020
   Expected: localhost:8010 (from runtime-infrastructure.json)
```

### How to Fix:

#### Option 1: Fix the Code (Usual Case)

```bash
# The code is wrong, official config is correct
# Fix code to match runtime-infrastructure.json

# Example:
# In frontend/vite.config.ts, change:
target: 'http://localhost:8020'  ❌
# To:
target: 'http://localhost:8010'  ✅
```

#### Option 2: Update Official Config (Rare)

```bash
# If ports LEGITIMATELY need to change:

# 1. Update runtime-infrastructure.json FIRST
# 2. Document WHY ports changed
# 3. Update all code to match new config
# 4. Validation will pass once everything matches
```

## Bypassing Enforcement (NEVER DO THIS)

```bash
# ❌ WRONG: Disable enforcement
git commit --no-verify

# ✅ RIGHT: Fix the configuration
# Edit files to match runtime-infrastructure.json
git commit
```

**Bypassing enforcement will cause**:
- 502 Bad Gateway errors
- Integration failures between services
- E2E test failures
- Production incidents

## Enforcement Reports

When validation fails, you'll see:

```
============================================================
❌❌❌ PORT CONFIGURATION VALIDATION FAILED ❌❌❌

UNAUTHORIZED port changes detected: 2 error(s)

⚠️  CRITICAL ENFORCEMENT:
   - Ports MUST match runtime-infrastructure.json
   - NO arbitrary port changes allowed
   - This is a BLOCKING error

To fix:
  1. Review runtime-infrastructure.json for official ports
  2. Update code to match official configuration
  3. If ports MUST change, update runtime-infrastructure.json FIRST
  4. Then update code to match

============================================================
```

## Testing Enforcement

```bash
# Test validator directly
bash .claude/validators/validate-port-configuration.sh

# Test pre-commit hook
bash .claude/enforcement/pre-commit-port-validation.sh

# Make an invalid change and try to commit
# Edit frontend/vite.config.ts, change port to 9999
# Try: git commit -m "test"
# Expected: Commit BLOCKED
```

## Integration with Claude Code

When Claude Code (or any agent) tries to:
1. Modify port configuration
2. Commit changes

**Enforcement activates**:
- Validates configuration
- Blocks commit if invalid
- Forces agent to fix configuration

**This prevents**:
- Arbitrary port changes
- Service integration breakage
- 502 errors from proxy misconfiguration

## Maintenance

### Adding New Validation Rules

Edit: `.claude/validators/validate-port-configuration.sh`

Add new checks following existing pattern:

```bash
# Validate new-config-file.yml
echo "Validating new-config-file.yml..."
FOUND_PORT=$(grep -oP 'some_port:\s*\K\d+' new-config-file.yml)

if [ "$FOUND_PORT" != "$OFFICIAL_BACKEND_PORT" ]; then
    echo "❌ UNAUTHORIZED PORT in new-config-file.yml"
    ERRORS=$((ERRORS + 1))
fi
```

### Updating Official Config

```bash
# When ports legitimately change:

# 1. Update runtime-infrastructure.json
# 2. Document change in git commit message
# 3. Update all code to match
# 4. Run validator to confirm
bash .claude/validators/validate-port-configuration.sh
```

## Summary

```
┌──────────────────────────────────────────────────────────┐
│  ENFORCEMENT = AUTOMATIC PREVENTION OF BAD CHANGES       │
│                                                          │
│  Official Config (runtime-infrastructure.json)           │
│         ↓                                                │
│  Validator checks code matches config                   │
│         ↓                                                │
│  Pre-commit hook blocks invalid commits                 │
│         ↓                                                │
│  NO unauthorized port changes possible                  │
└──────────────────────────────────────────────────────────┘
```

**Result**: Configuration stays consistent, no 502 errors, no broken integrations.
