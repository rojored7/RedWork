# Workflow Usage Guide - Agent 01

Quick guide to use the automated workflow with Agent 01.

---

## Setup (One-time)

Already done:
- workflow-status.json created
- Validation script for agent_01 created
- Post-commit hook installed

---

## How to Execute Agent 01

### Step 1: Run in GitLab (Optional - just for visualization)

1. Go to: https://gitlab.com/rojored7-group/redwork/-/pipelines
2. Click "Run pipeline"
3. Select branch: framework
4. Click "Run pipeline"
5. You will see agent_01_product_discovery in the graph

### Step 2: Execute Agent Locally with Claude Code

Open Claude Code and say:

```
Execute agent 01 product discovery for a task management system
```

Claude Code will:
- Ask you questions OR work autonomously (depending on mode)
- Generate: 01_product_discovery.md

### Step 3: Commit the Output

```bash
git add 01_product_discovery.md
git commit -m "docs: agent_01 product discovery completed"
```

### Step 4: Hook Runs Automatically

The post-commit hook will:
1. Detect 01_product_discovery.md in the commit
2. Run validation:
   - File exists
   - Has required sections (Product Vision, Problem Statement, etc.)
   - Has sufficient content (100+ lines)
3. If validation PASSES:
   - Updates workflow-status.json
   - Commits the status update
   - Pushes to GitLab
4. If validation FAILS:
   - Shows error message
   - Does NOT update status
   - You need to fix and commit again

### Step 5: Check GitLab

GitLab will:
- Receive the push with updated workflow-status.json
- Mark agent_01_product_discovery as completed (green)
- Unlock agent_02_domain_modeling

---

## Expected Output

After successful execution:

```bash
======================================
POST-COMMIT: Workflow Automation
======================================
Detected: 01_product_discovery.md

======================================
Validating Agent 01 - Product Discovery
======================================
✓ File exists: 01_product_discovery.md
✓ All required sections present
✓ File has sufficient content (150 lines)
======================================
Agent 01 validation PASSED
======================================

Validation PASSED. Updating workflow status...

======================================
Updating workflow status for: agent_01_product_discovery
======================================
✓ Status file updated
✓ Status committed
✓ Status pushed to GitLab
======================================
Workflow status updated successfully
======================================

Agent 01 workflow automation completed
======================================
```

---

## Troubleshooting

### Hook doesn't run

Check if installed:
```bash
ls -la .git/hooks/post-commit
```

Reinstall if missing:
```bash
bash scripts/install-workflow-hooks.sh
```

### Validation fails

Check what's missing:
```bash
bash scripts/workflow/validate-agent-01.sh
```

Fix the file and commit again.

### Push fails

Make sure you have push permissions:
```bash
git remote -v
git push origin framework
```

---

## Files Involved

- `workflow-status.json` - Tracks agent completion status
- `scripts/workflow/validate-agent-01.sh` - Validates agent_01 output
- `scripts/workflow/update-workflow-status.sh` - Updates status JSON
- `scripts/hooks/post-commit-workflow` - Post-commit hook
- `.git/hooks/post-commit` - Installed hook (not versioned)

---

## Next Steps

After Agent 01 completes:
1. Execute Agent 02 (Domain Modeling)
2. Repeat the same process
3. We will create validation scripts for other agents as needed

---

Created: 2026-03-31
Purpose: Quick usage guide for workflow automation
