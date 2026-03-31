# Workflow Test Guide - 2 Connected Agents

Guide to test the complete workflow with Agent 01 and Agent 02 connected.

---

## How It Works

```
GitLab Pipeline (Running)                  You (Local)
========================                   ============

1. Click "Run" on agent_01
   Status: running
   Polling every 30s for file...
                                    -->    2. Execute agent_01 in Claude Code
                                           Generate: 01_product_discovery.md

                                    -->    3. git add 01_product_discovery.md
                                           git commit -m "docs: agent_01"
                                           git push origin framework

4. Detects file in next fetch
   Validates: Product Vision, Problem Statement, etc.
   Status: success (green)

5. AUTO-STARTS agent_02
   Status: running
   Polling every 30s for file...
                                    -->    6. Execute agent_02 in Claude Code
                                           Generate: 02_domain_model.md

                                    -->    7. git add 02_domain_model.md
                                           git commit -m "docs: agent_02"
                                           git push origin framework

8. Detects file in next fetch
   Validates: Domain Entities, Value Objects
   Status: success (green)

BOTH AGENTS COMPLETED
```

---

## Step-by-Step Test

### Step 1: Start Pipeline in GitLab

1. Go to: https://gitlab.com/rojored7-group/redwork/-/pipelines
2. Click "Run pipeline"
3. Branch: framework
4. Click "Run pipeline"
5. You will see TWO nodes:
   - agent_01_product_discovery (with Play button)
   - agent_02_domain_modeling (grayed out, waiting for agent_01)

### Step 2: Start Agent 01

1. Click the Play button on agent_01_product_discovery
2. The job starts running (blue/spinning icon)
3. Click on the job to see logs
4. You will see:
   ```
   Agent 01 - Product Discovery
   Waiting for 01_product_discovery.md
   [0/3600] Checking if 01_product_discovery.md exists...
   File not found yet. Waiting 30 seconds...
   [30/3600] Checking if 01_product_discovery.md exists...
   ...
   ```

### Step 3: Execute Agent 01 Locally

In Claude Code (this conversation), say:

```
Execute agent 01 product discovery for a task management application
```

Claude will generate the file: 01_product_discovery.md

### Step 4: Commit (Hook Auto-Pushes)

```bash
git add 01_product_discovery.md
git commit -m "docs: agent_01 product discovery completed"
```

The post-commit hook will:
1. Detect 01_product_discovery.md
2. Run validation
3. If PASSED: Automatically push to GitLab
4. You will see: "Agent 01 pushed to GitLab successfully"

### Step 5: Watch GitLab Detect It

Go back to the GitLab pipeline log. Within 30 seconds you will see:

```
[180/3600] Checking if 01_product_discovery.md exists...
File detected: 01_product_discovery.md
Running validation...
Validation PASSED
Agent 01 COMPLETED
```

The agent_01 node turns GREEN.

### Step 6: Agent 02 Auto-Starts

Immediately after agent_01 completes, agent_02 will AUTO-START (no need to click Play).

You will see agent_02 logs:

```
Agent 02 - Domain Modeling
Waiting for 02_domain_model.md
[0/3600] Checking if 02_domain_model.md exists...
File not found yet. Waiting 30 seconds...
```

### Step 7: Execute Agent 02 Locally

In Claude Code, say:

```
Execute agent 02 domain modeling based on 01_product_discovery.md
```

Claude will generate: 02_domain_model.md

### Step 8: Commit (Hook Auto-Pushes)

```bash
git add 02_domain_model.md
git commit -m "docs: agent_02 domain modeling completed"
```

The post-commit hook will:
1. Detect 02_domain_model.md
2. Run validation
3. If PASSED: Automatically push to GitLab
4. You will see: "Agent 02 pushed to GitLab successfully"

### Step 9: Watch Agent 02 Complete

GitLab will detect the file within 30 seconds:

```
[150/3600] Checking if 02_domain_model.md exists...
File detected: 02_domain_model.md
Running validation...
Validation PASSED
Agent 02 COMPLETED
```

The agent_02 node turns GREEN.

---

## Expected Timeline

- Agent 01 waits: Up to 1 hour (3600s) or until you push
- Detection time: Max 30 seconds after your push
- Agent 02 starts: Immediately after agent_01 completes
- Agent 02 waits: Up to 1 hour or until you push

Total test time: 5-10 minutes (if you work quickly)

---

## What Gets Validated

### Agent 01
- File exists: 01_product_discovery.md
- Has section: "Product Vision"
- Has section: "Problem Statement"
- Has section: "System Objectives"

### Agent 02
- File exists: 02_domain_model.md
- Has section: "Domain Entities"
- Has section: "Value Objects"

---

## Troubleshooting

### Pipeline times out after 1 hour

You took too long. Restart the pipeline and work faster.

### Validation fails

Check the error message in GitLab logs. Fix the file and push again.
The pipeline will detect the new version in the next fetch.

### Agent 02 doesn't auto-start

Check that agent_01 completed successfully (green).
If agent_01 failed (red), agent_02 won't start.

---

## Files You Will Create

After this test, you will have:
- 01_product_discovery.md (Agent 01 output)
- 02_domain_model.md (Agent 02 output)
- Both committed to framework branch

---

## Next Steps

If this works, we will:
1. Add the remaining 18 agents
2. Connect them all in sequence
3. You can execute the complete workflow from start to finish

---

Created: 2026-03-31
Purpose: Test workflow with 2 connected agents
