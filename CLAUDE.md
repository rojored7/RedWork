# CLAUDE.md - Instructions for Claude Code

Instructions for Claude Code when working with this framework.

---

## Framework Overview

This is a **Framework Repository** containing 20 specialized agents for automated full-stack development.

**Purpose**: Create new projects with complete automation from idea to production.

**DO NOT** develop here. This repo contains the framework itself.

---

## How to Use This Framework

### When User Says: "Create a new project"

1. Run initialization script:
```bash
bash init-new-project.sh <project-name>
```

2. Navigate to new project:
```bash
cd ../<project-name>
```

3. Install hooks:
```bash
bash .framework/scripts/install-workflow-hooks.sh
```

4. User pushes to GitLab
5. User starts pipeline
6. Execute agents one by one

---

## When User Says: "Execute agent XX"

### Example: "lanza el agente 01-product-discovery quiero un LMS"

1. **Invoke Task tool** with agent:
```
subagent_type: 01-product-discovery
prompt: Create comprehensive product discovery for LMS...
```

2. **Agent generates** file in outputs/ (if in project) or root (if in framework)

3. **Run auto-commit**:
```bash
bash scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
```

OR if in framework root:
```bash
bash scripts/workflow/auto-commit-agent-output.sh 01_product_discovery.md
```

4. **Post-commit hook runs automatically**:
- Validates file
- Pushes to GitLab
- Shows success/error

5. **GitLab pipeline**:
- Detects file (30s max)
- Validates
- Marks complete
- Starts next agent

---

## Agent Execution Pattern

**ALL agents follow this pattern:**

```
User: "lanza el agente XX [context]"
  ↓
You: Invoke Task tool with agent XX
  ↓
Agent generates output file
  ↓
You: Run auto-commit script
  ↓
Hook validates and pushes
  ↓
GitLab detects and completes
  ↓
Next agent auto-starts
```

---

## Available Agents (Discovery Phase)

### Agent 01: Product Discovery
```
User: "lanza el agente 01-product-discovery quiero un [PROJECT]"
Output: outputs/01_product_discovery.md
Auto-commit: bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
```

### Agent 02: Domain Modeling
```
User: "lanza el agente 02-domain-modeling-agent basado en 01_product_discovery.md"
Output: outputs/02_domain_model.md
Auto-commit: bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/02_domain_model.md
```

### Agent 03: Context Mapping
```
User: "lanza el agente context-mapping-agent basado en 02_domain_model.md"
Output: outputs/03_context_map.md
Auto-commit: bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/03_context_map.md
```

### Agent 04: Architecture Decision
```
User: "lanza el agente architecture-decision basado en 03_context_map.md"
Output: outputs/04_architecture_decision.md
Auto-commit: bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/04_architecture_decision.md
```

### Agent 05: Service Design
```
User: "lanza el agente service-design-architect basado en 04_architecture_decision.md"
Output: outputs/05_service_design.md
Auto-commit: bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/05_service_design.md
```

---

## IMPORTANT Rules

### 1. Never Use Emojis
User has specified: NO EMOJIS in responses or code.

### 2. Never Put Names in Credentials
When doing git push, never include personal names in commit credentials.

### 3. Always Run Auto-Commit
After agent generates file, ALWAYS run:
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/<file>
```

### 4. Check Working Directory
If in framework root: `outputs/` may not exist, use root path.
If in project: Always use `outputs/` prefix.

### 5. Agent Sequence Matters
Agents must run in order:
01 → 02 → 03 → 04 → 05

Each agent depends on previous output.

---

## File Locations

### Framework Repository
```
Framework/
├── agents/              # Agent definitions (read-only)
├── scripts/             # Automation scripts
└── init-new-project.sh  # Creates new projects
```

### Project Repository
```
my-project/
├── .framework/          # Copy of framework (don't edit)
├── outputs/             # Agent outputs GO HERE
├── backend/             # Backend code
├── frontend/            # Frontend code
└── .gitlab-ci.yml       # Pipeline config
```

---

## Commands You Will Use

### 1. Create Project
```bash
bash init-new-project.sh <name>
```

### 2. Install Hooks
```bash
bash .framework/scripts/install-workflow-hooks.sh
```

### 3. Execute Agent
Use Task tool with appropriate agent.

### 4. Auto-Commit
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/<file>
```

### 5. Validate Manually (if needed)
```bash
bash .framework/scripts/workflow/validate-agent-01.sh
```

---

## Troubleshooting

### "File not found" in auto-commit
Check if file is in outputs/ or root:
```bash
ls -la outputs/
ls -la *.md
```

### "Validation failed"
Run validator manually to see error:
```bash
bash .framework/scripts/workflow/validate-agent-01.sh
```

### "Hook not running"
Reinstall:
```bash
bash .framework/scripts/install-workflow-hooks.sh
```

---

## Workflow States

### State 1: Framework Repo
- User is in framework-agents/
- Agents execute here create files at root
- Use root paths in auto-commit

### State 2: Project Repo
- User created project with init-new-project.sh
- User is in my-project/
- Agents execute here create files in outputs/
- Use outputs/ prefix in auto-commit

**Always check current directory before running commands.**

---

## Success Indicators

After auto-commit, you should see:
```
Validation PASSED
Agent XX pushed to GitLab successfully
Pipeline will detect it within 30 seconds
```

If not, something went wrong. Check validation output.

---

## Next Steps After Discovery Phase

Once agents 01-05 complete:
1. Configure agents 06-09 (Planning)
2. Configure agent 12 (Infrastructure)
3. Configure agents 10-11, 13-14, 20 (Development)
4. Configure agents 15-16, 18 (Testing)
5. Configure agents 19-20 (Quality)

Each phase follows same pattern as Discovery.

---

**Remember**: Keep it simple, no emojis, always auto-commit, check directory context.
