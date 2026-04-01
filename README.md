# Framework Agents - Complete Development Automation

Automated workflow with 21 specialized agents for full-stack development with GitLab CI/CD integration and auto-learning.

---

## What This Does

Automates the complete development lifecycle:
- Discovery: Product → Domain → Architecture → Design
- Planning: Epics → User Stories → Technical Tasks → Sprints
- Development: Backend + Frontend + Tests
- Quality: Integration → E2E → Security → Linting
- Learning: Auto-detect patterns → Generate new skills

**Result**: Production-ready application with 100% test coverage, quality, and continuous improvement.

---

## Quick Start

### 1. Clone Framework

```bash
git clone https://gitlab.com/rojored7-group/redwork.git framework-agents
cd framework-agents
```

### 2. Create New Project

```bash
bash init-new-project.sh my-project
```

Creates:
```
../my-project/
├── .framework/          # Framework (agents, scripts, hooks)
├── .learning/           # Learning data (Agent 21, NOT committed)
├── outputs/             # Agent outputs (*.md files)
├── backend/             # Your backend code
├── frontend/            # Your frontend code
├── .gitlab-ci.yml       # CI/CD pipeline
└── README.md            # Project README
```

### 3. Setup Project

```bash
cd ../my-project
bash .framework/scripts/install-workflow-hooks.sh
```

### 4. Push to GitLab

```bash
git remote add origin https://gitlab.com/your-group/my-project.git
git push -u origin main
```

### 5. Start Pipeline

Go to GitLab Pipelines → Run pipeline → Click Play on agent_01

### 6. Execute First Agent

In Claude Code:
```
lanza el agente 01-product-discovery quiero un LMS
```

Output: `outputs/01_product_discovery.md`

### 7. Auto-Commit

```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
```

Automatically:
- Validates file
- Commits
- Pushes to GitLab
- Pipeline detects (30s max)
- Marks agent complete
- Starts next agent

### 8. Continue

Repeat for agents 02-05 (Discovery phase complete).

---

## Workflow Automation

```
Execute Agent (Claude Code)
   ↓
Generate output file
   ↓
Auto-commit script
   ↓
Post-commit hook validates
   ↓
Push to GitLab
   ↓
Pipeline detects (30s)
   ↓
Validates content
   ↓
Marks complete
   ↓
Next agent auto-starts
```

**Completely automated after agent execution.**

---

## Available Agents

### Discovery Phase (01-05) - Currently Configured
1. **Product Discovery** → `01_product_discovery.md`
2. **Domain Modeling** → `02_domain_model.md`
3. **Context Mapping** → `03_context_map.md`
4. **Architecture Decision** → `04_architecture_decision.md`
5. **Service Design** → `05_service_design.md`

### Planning Phase (06-09) - To Be Configured
6. Epic Generation
7. User Story Generation
8. Tech Lead Delivery
9. Sprint Orchestrator

### Infrastructure (12) - To Be Configured
12. Infrastructure Deployment

### Development (10-11, 13-14, 20) - To Be Configured
10. Backend Development
11. Frontend Development
13. Backend Test Agent
14. Frontend Test Auditor
20. Linting Validator

### Testing (15-16, 18) - To Be Configured
15. Integration Test Validator
16. E2E Test Validator
18. Smoke Test Validator

### Quality (19-20) - To Be Configured
19. Security Review Agent
20. Final Linting

### Learning & Optimization (21) - Configured
21. **Learning Agent** → Analyzes patterns → Proposes new skills

---

## Auto-Learning System

**Agent 21** runs periodically to analyze your project:
- Git history (agent execution patterns)
- Agent outputs (content structures)
- Error logs (problems and solutions)

**Proposes new skills** when patterns detected ≥3 times:
- Saves in `.learning/proposed-skills/`
- You review and approve
- Approved skills become part of framework

**Usage**:
```bash
# In Claude Code (every 2-3 weeks)
lanza el agente 21-learning-agent

# Review proposals
ls .learning/proposed-skills/

# Approve a skill
cp .learning/proposed-skills/09-skill-name.md \
   .framework/agents/workflow-orchestrator/skills/
```

See `learning/README.md` for complete documentation.

---

## Commands Reference

### Create New Project
```bash
bash init-new-project.sh <project-name>
```

### Install Hooks
```bash
bash .framework/scripts/install-workflow-hooks.sh
```

### Execute Agent (in Claude Code)
```
lanza el agente <agent-name> [context]
```

### Auto-Commit Output
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/<file>
```

### Validate Manually
```bash
bash .framework/scripts/workflow/validate-agent-XX.sh
```

---

## Project Structure

```
my-project/
├── .framework/
│   ├── agents/                      # 20 specialized agents
│   │   ├── 01-product-discovery.md
│   │   ├── 02-domain-modeling-agent.md
│   │   └── ... (18 more)
│   └── scripts/
│       ├── install-workflow-hooks.sh
│       ├── workflow/
│       │   ├── validate-agent-01.sh ... 05.sh
│       │   ├── auto-commit-agent-output.sh
│       │   └── update-workflow-status.sh
│       └── hooks/
│           └── post-commit-workflow
│
├── outputs/                         # Agent outputs
│   ├── 01_product_discovery.md
│   ├── 02_domain_model.md
│   └── ...
│
├── backend/                         # Backend code
├── frontend/                        # Frontend code
├── .gitlab-ci.yml                   # Pipeline config
└── README.md                        # Project README
```

---

## How It Works

### 1. Agent Execution
Execute agent in Claude Code with your project idea.

### 2. Auto-Commit Script
```bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
```
- Detects which agent (01-05)
- Creates commit with proper message
- Triggers post-commit hook

### 3. Post-Commit Hook (Automatic)
- Validates file has required sections
- Pushes to GitLab if valid
- Shows error if validation fails

### 4. GitLab Pipeline (Automatic)
- Polls for file every 30 seconds
- Detects file when pushed
- Validates content
- Marks agent as complete
- Auto-starts next agent

### 5. Next Agent
Repeat process for next agent.

---

## Validation Rules

Each agent validates specific sections:

**Agent 01**: Product Vision, Problem Statement, System Objectives
**Agent 02**: Domain Entities, Value Objects
**Agent 03**: Bounded Contexts, Context Relationships
**Agent 04**: Architecture Pattern, Deployment Strategy, Technology Stack
**Agent 05**: Service Design, Clean Architecture, Domain Layer

---

## Troubleshooting

### Hooks Not Running
```bash
# Verify installed
ls -la .git/hooks/post-commit

# Reinstall
bash .framework/scripts/install-workflow-hooks.sh
```

### Pipeline Not Detecting File
- Check file is in `outputs/` directory
- Check file pushed: `git log --oneline`
- Wait up to 30 seconds for polling
- Check pipeline running in GitLab

### Validation Fails
```bash
# Run validator manually
bash .framework/scripts/workflow/validate-agent-01.sh

# Check error message
# Fix file
# Recommit
```

### Agent Won't Execute
- Check agent file exists in `.framework/agents/`
- Use correct agent name
- Provide context from previous agent

---

## Essential Files

Framework requires only these files:

```
Framework/
├── README.md                              # This file
├── CLAUDE.md                              # Claude Code instructions
├── init-new-project.sh                    # Project setup
├── .gitlab-ci.yml                         # Pipeline template
├── workflow-status.json                   # Status tracker
├── .gitignore                             # Git ignore rules
│
├── agents/                                # 21 agents
│   ├── 01-product-discovery.md
│   ├── 21-learning-agent.md
│   └── ... (19 more)
│
├── learning/                              # Learning system
│   └── README.md
│
└── scripts/
    ├── install-workflow-hooks.sh
    ├── workflow/
    │   ├── validate-agent-01.sh ... 05.sh
    │   ├── auto-commit-agent-output.sh
    │   └── update-workflow-status.sh
    └── hooks/
        └── post-commit-workflow
```

**Total: ~40 files**

---

## Benefits

- **Automated**: Minimal manual intervention
- **Quality**: 100% validation at every step
- **Traceable**: GitLab shows complete flow
- **Reusable**: One framework, infinite projects
- **Self-Improving**: Learns patterns and generates new skills
- **Tested**: Working Discovery phase (agents 01-05) + Learning Agent

---

## Status

**Working**:
- Discovery phase (agents 01-05) - Fully configured
- Learning Agent (agent 21) - Fully configured

**Pending**: Planning, Infrastructure, Development, Testing, Quality phases

**Next**: Configure remaining 15 agents with same pattern.

---

## Support

- Framework: https://gitlab.com/rojored7-group/redwork
- Issues: Create issue in framework repo
- Agents: See `agents/README.md`
- Learning System: See `learning/README.md`

---

**Version**: 1.1.0
**Created**: 2026-03-31
**Updated**: 2026-04-01 (Added Learning Agent)
**Status**: Discovery Phase + Learning System Complete
