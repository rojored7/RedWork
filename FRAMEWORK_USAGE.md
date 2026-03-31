# Framework Usage Guide

Complete guide to use the Framework for new projects.

---

## What is This Framework?

A complete automation framework with 20 specialized agents for full-stack development:
- Product Discovery → Architecture → Planning → Development → Testing → Deployment
- Automated workflow with GitLab CI/CD integration
- Quality enforcement with hooks and validation
- Test-driven development (TDD) and Domain-Driven Design (DDD)

---

## Quick Start: Create a New Project

### Step 1: Clone Framework Repository

```bash
git clone https://gitlab.com/rojored7-group/redwork.git framework-agents
cd framework-agents
```

### Step 2: Initialize New Project

```bash
bash init-new-project.sh my-new-project
```

This creates:
```
../my-new-project/
├── .framework/              # Framework (agents, scripts)
├── outputs/                 # Agent outputs go here
├── backend/                 # Your backend code
├── frontend/                # Your frontend code
├── docs/                    # Additional docs
├── .gitlab-ci.yml           # CI/CD pipeline
├── .gitignore              # Git ignore rules
└── README.md               # Project README
```

### Step 3: Setup Project

```bash
cd ../my-new-project

# Install workflow hooks
bash .framework/scripts/install-workflow-hooks.sh
```

### Step 4: Push to GitLab

```bash
# Create new repo in GitLab first, then:
git remote add origin https://gitlab.com/your-group/my-new-project.git
git push -u origin main
```

### Step 5: Start Pipeline

1. Go to: https://gitlab.com/your-group/my-new-project/-/pipelines
2. Click "Run pipeline"
3. Click Play on agent_01_product_discovery

Pipeline starts polling, waiting for your output.

### Step 6: Execute Agent 01

In Claude Code:
```
lanza el agente 01-product-discovery quiero un [YOUR_PROJECT_IDEA]
```

Example:
```
lanza el agente 01-product-discovery quiero un LMS
```

Agent generates: `outputs/01_product_discovery.md`

### Step 7: Auto-Commit

```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
```

Workflow automatically:
- Validates file
- Commits
- Pushes to GitLab

### Step 8: Watch Automation

GitLab pipeline (30s max):
- Detects file
- Validates content
- Marks agent_01 complete
- Auto-starts agent_02

### Step 9: Continue with Agent 02

In Claude Code:
```
lanza el agente 02-domain-modeling-agent basado en outputs/01_product_discovery.md
```

Then:
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/02_domain_model.md
```

### Step 10: Repeat for All Agents

Continue through all 5 Discovery agents:
- 01 Product Discovery
- 02 Domain Modeling
- 03 Context Mapping
- 04 Architecture Decision
- 05 Service Design

---

## Project Structure Explained

### `.framework/` Directory

Contains framework files (DO NOT EDIT):
- `agents/` - 20 specialized agents
- `scripts/workflow/` - Automation scripts
- `scripts/hooks/` - Git hooks

### `outputs/` Directory

Agent outputs go here:
- `01_product_discovery.md`
- `02_domain_model.md`
- `03_context_map.md`
- `04_architecture_decision.md`
- `05_service_design.md`
- etc.

### `backend/` Directory

Your backend application code.

### `frontend/` Directory

Your frontend application code.

### `.gitlab-ci.yml`

CI/CD pipeline configuration. Tracks agent execution.

---

## How the Workflow Works

```
1. Execute Agent (Claude Code)
   ↓
2. Agent generates file in outputs/
   ↓
3. Auto-commit script
   - Commits file
   ↓
4. Post-commit hook
   - Validates file
   - Pushes to GitLab
   ↓
5. GitLab pipeline (polling)
   - Detects file (30s max)
   - Validates content
   - Marks agent complete
   ↓
6. Next agent auto-starts
   ↓
7. Repeat
```

---

## Available Agents

### Discovery Phase (01-05)
1. Product Discovery - Transform idea → requirements
2. Domain Modeling - Create domain entities, VOs, aggregates
3. Context Mapping - Identify bounded contexts
4. Architecture Decision - Choose architecture pattern
5. Service Design - Design Clean Architecture layers

### Planning Phase (06-09)
6. Epic Generation - Generate product epics
7. User Story Generation - Decompose epics → stories + BDD
8. Tech Lead Delivery - Stories → technical tasks
9. Sprint Orchestrator - Organize sprint execution

### Infrastructure (12)
12. Infrastructure Deployment - Setup Docker, DB, Redis

### Development (10-11, 13-14, 20)
10. Backend Development - Implement FastAPI services
11. Frontend Development - Implement React/Vue features
13. Backend Test Agent - Create/audit backend tests
14. Frontend Test Auditor - Create/audit frontend tests
20. Linting Validator - Enforce 0 errors, 0 warnings

### Testing (15-16, 18)
15. Integration Test Validator - Validate backend ↔ DB
16. E2E Test Validator - Validate user flows
18. Smoke Test Validator - Validate critical paths

### Quality (19-20)
19. Security Review Agent - Security audit
20. Final Linting - Final code quality check

---

## Commands Reference

### Initialize New Project
```bash
bash init-new-project.sh <project-name>
```

### Install Hooks
```bash
bash .framework/scripts/install-workflow-hooks.sh
```

### Execute Agent
```
In Claude Code:
lanza el agente <agent-name> [context]
```

### Auto-Commit Output
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/<output-file>
```

### Validate Manually
```bash
bash .framework/scripts/workflow/validate-agent-01.sh
bash .framework/scripts/workflow/validate-agent-02.sh
# etc.
```

---

## Troubleshooting

### Hooks not running

```bash
# Reinstall
bash .framework/scripts/install-workflow-hooks.sh

# Verify
ls -la .git/hooks/post-commit
```

### Pipeline not detecting file

- Check file is in `outputs/` directory
- Check file pushed to GitLab: `git log --oneline`
- Check pipeline is running: GitLab Pipelines page
- Wait up to 30 seconds for polling

### Validation fails

```bash
# Run validator manually
bash .framework/scripts/workflow/validate-agent-01.sh

# Check what's missing
# Fix file
# Recommit
```

---

## Best Practices

1. **Keep framework files unchanged**: Don't edit `.framework/` directory
2. **Use outputs/ for agent outputs**: All .md files go there
3. **Run hooks after each agent**: Use auto-commit script
4. **Monitor GitLab pipeline**: Watch for detection and validation
5. **Follow agent sequence**: Don't skip agents

---

## Updating Framework

If framework gets updated:

```bash
# In framework repo
git pull origin main

# Re-initialize project (backup first!)
bash init-new-project.sh my-project-v2

# Or manually update .framework/ directory
```

---

## Support

- Framework Repo: https://gitlab.com/rojored7-group/redwork
- Issues: Create issue in framework repo
- Documentation: See `.framework/agents/README.md`

---

Created: 2026-03-31
Version: 1.0.0
Framework: Quality Enforcement Framework
