# Framework Agents

**Complete set of 20 specialized agents for full-stack development**

---

## 📊 Quick Stats

- **Total Agents**: 20 agents
- **Total Size**: ~230 KB
- **Coverage**: Product Discovery → Production Deployment
- **Architecture**: DDD, Clean Architecture, Hexagonal Architecture
- **Testing**: Unit, Integration, E2E, Smoke Tests
- **Quality**: Security Review, Linting, 100% Coverage

---

## 🎯 All Agents

### Discovery & Design (01-05)
1. **01-product-discovery** - Transform vague idea → structured requirements
2. **02-domain-modeling-agent** - Create domain model (entities, VOs, aggregates)
3. **03-context-mapping** - Identify bounded contexts (DDD)
4. **04-architecture-decision** - Decide architecture (monolith vs microservices)
5. **05-service-design-architect** - Design service internals (Clean Architecture)

### Planning (06-09)
6. **06-epic-generation** - Generate epics from domain model
7. **07-user-story-generator** - Decompose epics → user stories + BDD
8. **08-tech-lead-delivery** - User stories → technical tasks
9. **09-sprint-orchestrator** - Organize tasks → sprint execution plan

### Backend (10, 13)
10. **10-backend-fastapi-dev** - Implement backend services (FastAPI)
13. **13-backend-test-agent** - Create/audit/repair backend tests

### Frontend (11, 14)
11. **11-frontend-development** - Implement frontend features (React/Vue/etc.)
14. **14-frontend-test-auditor** - Create/audit/repair frontend tests

### Infrastructure & Testing (12, 15, 16, 18)
12. **12-infrastructure-deployment** - Setup Docker, DB, Redis, networks
15. **15-integration-test-validator** - Validate backend ↔ DB integration
16. **16-e2e-test-validator** - Validate end-to-end user flows
18. **18-smoke-test-validator** - Validate critical paths work (real execution)

### Quality & Security (19, 20)
19. **19-security-review-agent** - Security review (auth, APIs, uploads, secrets)
20. **20-linting-validator** - Enforce 0 errors, 0 warnings (BLOCKS progress)

### Orchestration
- **wsl-docker-orchestrator** - Docker orchestration for WSL/Windows
- **workflow-orchestrator/** - Advanced workflow orchestration

---

## 🔄 Workflow Sequence

```
Product Idea
     ↓
01 Product Discovery → 01_product_discovery.md
     ↓
02 Domain Modeling → 02_domain_model.md
     ↓
03 Context Mapping → 03_context_map.md
     ↓
04 Architecture Decision → 04_architecture_decision.md
     ↓
05 Service Design → 05_service_design.md
     ↓
06 Epic Generation → 06_epics/*.md
     ↓
07 User Story Generation → 07_user_stories/**/*.md
     ↓
08 Tech Lead Delivery → 08_implementation_breakdown/**/*.md
     ↓
09 Sprint Orchestrator → 09_sprint_plan/sprint_XX/*.md
     ↓
12 Infrastructure Deployment → docker-compose.yml, Dockerfile, etc.
     ↓
┌────────────────────────────────────┐
│  PARALLEL DEVELOPMENT               │
│  10 Backend Dev + 13 Backend Test   │
│  11 Frontend Dev + 14 Frontend Test │
└────────────────────────────────────┘
     ↓
15 Integration Tests → Validate backend ↔ DB
     ↓
16 E2E Tests → Validate user flows
     ↓
18 Smoke Tests → Validate critical paths
     ↓
19 Security Review → Check vulnerabilities
     ↓
20 Linting Validator → Enforce code quality
     ↓
PRODUCTION READY ✅
```

---

## 📖 Usage

### Method 1: Via Claude Code (Recommended)

When working in a project with Claude Code, agents are automatically available via the Task tool.

**Example**:
```
User: "I need to create the domain model for my e-commerce platform"

Assistant invokes:
- Agent: 02-domain-modeling-agent
- Input: 01_product_discovery.md
- Output: 02_domain_model.md with entities, VOs, aggregates
```

### Method 2: Manual Reference

Read agent files directly to understand:
- What the agent does
- When to invoke it
- What inputs it needs
- What outputs it produces

**Example**:
```bash
# Read backend development agent
cat agents/backend-fastapi-dev.md

# Understand when to invoke it
# Understand what inputs it needs
# Follow the agent's instructions manually
```

---

## 🎯 Agent Details

See `AGENTS_INDEX.md` for complete descriptions of all 20 agents.

---

## 📁 File Structure

```
agents/
├── README.md                          # This file
├── AGENTS_INDEX.md                    # Complete agent index with descriptions
│
├── 01-product-discovery.md            # Phase 1: Discovery
├── 02-domain-modeling-agent.md
├── context-mapping-agent.md           # (03)
├── architecture-decision.md           # (04)
├── service-design-architect.md        # (05)
│
├── epic-generation.md                 # Phase 2: Planning
├── user-story-generator.md            # (07)
├── tech-lead-delivery.md              # (08)
├── sprint-orchestrator.md             # (09)
│
├── backend-fastapi-dev.md             # Phase 3: Backend
├── backend-test-agent.md              # (13)
│
├── frontend-development.md            # Phase 4: Frontend
├── frontend-test-auditor.md           # (14)
│
├── infrastructure-deployment.md       # Phase 5: Infrastructure
├── integration-test-validator.md      # (15)
├── e2e-test-validator.md              # (16)
├── smoke-test-validator.md            # (18)
│
├── security-review-agent.md           # Phase 6: Quality
├── linting-validator.md               # (20)
│
├── wsl-docker-orchestrator.md         # Orchestration
└── workflow-orchestrator/             # Advanced orchestration
```

---

## 🚀 Quick Start

1. **Read this file** to understand all agents
2. **Read AGENTS_INDEX.md** for detailed descriptions
3. **Start with agent 01** (Product Discovery) for new projects
4. **Follow the workflow** sequentially (01 → 02 → 03 → ... → 20)
5. **Use parallel agents** (10+13 and 11+14) for faster development

---

## ✅ Success Criteria

A project using all agents should have:
- ✅ Complete product discovery documentation
- ✅ Comprehensive domain model (DDD)
- ✅ Clear architectural decisions
- ✅ Detailed service designs (Clean Architecture)
- ✅ Well-defined epics and user stories
- ✅ Executable sprint plans
- ✅ Working infrastructure (Docker, DB, Redis)
- ✅ Backend implementation with 100% test coverage
- ✅ Frontend implementation with 100% test coverage
- ✅ Passing integration tests (100%)
- ✅ Passing E2E tests (100%)
- ✅ Passing smoke tests (100%)
- ✅ Security review passed (no CRITICAL/HIGH findings)
- ✅ Linting clean (0 errors, 0 warnings)

**Result**: Production-ready application with 100% quality

---

**Created**: 2026-03-31
**Version**: 1.0.0
**Agents**: 20 specialized agents
**Framework**: Quality Enforcement Framework
