# Discovery Phase - 5 Agents Ready

Complete configuration for Discovery phase with automated workflow.

---

## Configured Agents

1. **Agent 01 - Product Discovery** → `01_product_discovery.md`
2. **Agent 02 - Domain Modeling** → `02_domain_model.md`
3. **Agent 03 - Context Mapping** → `03_context_map.md`
4. **Agent 04 - Architecture Decision** → `04_architecture_decision.md`
5. **Agent 05 - Service Design** → `05_service_design.md`

---

## How to Execute Each Agent

### Agent 01
```
Execute: "lanza el agente 01-product-discovery quiero un [YOUR_PROJECT]"
Output: 01_product_discovery.md
Auto-commit: bash scripts/workflow/auto-commit-agent-output.sh 01_product_discovery.md
```

### Agent 02
```
Execute: "lanza el agente 02-domain-modeling-agent basado en 01_product_discovery.md"
Output: 02_domain_model.md
Auto-commit: bash scripts/workflow/auto-commit-agent-output.sh 02_domain_model.md
```

### Agent 03
```
Execute: "lanza el agente context-mapping-agent basado en 02_domain_model.md"
Output: 03_context_map.md
Auto-commit: bash scripts/workflow/auto-commit-agent-output.sh 03_context_map.md
```

### Agent 04
```
Execute: "lanza el agente architecture-decision basado en 03_context_map.md"
Output: 04_architecture_decision.md
Auto-commit: bash scripts/workflow/auto-commit-agent-output.sh 04_architecture_decision.md
```

### Agent 05
```
Execute: "lanza el agente service-design-architect basado en 04_architecture_decision.md"
Output: 05_service_design.md
Auto-commit: bash scripts/workflow/auto-commit-agent-output.sh 05_service_design.md
```

---

## Automated Workflow

### For Each Agent:

1. **Execute agent** via Claude Code
2. **Auto-commit script** runs:
   - Detects output file
   - Commits with proper message
3. **Post-commit hook** runs:
   - Validates file content
   - Pushes to GitLab automatically
4. **GitLab pipeline** (30s max):
   - Detects file
   - Validates required sections
   - Marks agent as completed
   - Auto-starts next agent

### Complete Flow:

```
Agent 01 (manual start)
   ↓ (completes)
Agent 02 (auto-starts)
   ↓ (completes)
Agent 03 (auto-starts)
   ↓ (completes)
Agent 04 (auto-starts)
   ↓ (completes)
Agent 05 (auto-starts)
   ↓ (completes)
DISCOVERY PHASE COMPLETE
```

---

## Validators

Each agent has validation checking:

**Agent 01**:
- Product Vision
- Problem Statement
- System Objectives

**Agent 02**:
- Domain Entities
- Value Objects

**Agent 03**:
- Bounded Contexts
- Context Relationships

**Agent 04**:
- Architecture Pattern
- Deployment Strategy
- Technology Stack

**Agent 05**:
- Service Design
- Clean Architecture
- Domain Layer

---

## Files Created

- `scripts/workflow/validate-agent-01.sh` (already existed)
- `scripts/workflow/validate-agent-02.sh` (already existed)
- `scripts/workflow/validate-agent-03.sh` (NEW)
- `scripts/workflow/validate-agent-04.sh` (NEW)
- `scripts/workflow/validate-agent-05.sh` (NEW)
- `scripts/workflow/auto-commit-agent-output.sh` (updated)
- `scripts/hooks/post-commit-workflow` (updated)
- `.gitlab-ci.yml` (updated with 5 agents)

---

## GitLab Pipeline

View at: https://gitlab.com/rojored7-group/redwork/-/pipelines

You will see:
- 5 nodes in sequence
- Each with polling status
- Auto-progression when files detected

---

## Current State

- Agent 01 already executed (01_product_discovery.md exists)
- Ready to continue with Agent 02

---

## Next Steps

1. Go to GitLab and start pipeline (if not already running)
2. Execute Agent 02: Domain Modeling
3. Watch automatic progression through all 5 agents

---

Created: 2026-03-31
Status: Complete and tested
Phase: Discovery (Agents 01-05)
