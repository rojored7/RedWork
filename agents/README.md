# Framework Agents

**Complete set of 25 specialized agents for full-stack development with auto-learning, security-by-design, and self-debugging**

---

## 📊 Quick Stats

- **Total Agents**: 25 agents
- **Version**: 1.3 (Self-Debugging Update)
- **Total Size**: ~300 KB
- **Coverage**: Product Discovery → Production Deployment + Auto-Learning
- **Architecture**: DDD, Clean Architecture, Hexagonal Architecture
- **Testing**: Unit, Integration, E2E, Smoke Tests
- **Quality**: Security Review, Linting, 100% Coverage
- **NEW**: 3 preventive validation agents (04b, 05b, 09b)

---

## 🎯 All Agents

### Discovery & Design (01-05c)
1. **01-product-discovery** - Transform vague idea → structured requirements
2. **02-domain-modeling-agent** - Create domain model (entities, VOs, aggregates)
3. **03-context-mapping** - Identify bounded contexts (DDD)
4. **04-architecture-decision** - Decide architecture (FastAPI backend MANDATORY)
5. **04b-security-by-design** - Define OWASP-compliant security requirements (NEW v1.2)
6. **agent-introspection-debugging** - Debug agent failures with structured recovery (NEW v1.3 - AUTO-ACTIVATE ON FAILURES)
7. **05-service-design-architect** - Design service internals (Clean Architecture)
8. **05b-technical-design-validator** - Validate design completeness and security (NEW v1.2 - BLOCKING GATE)
9. **05c-api-first-specification** - Extract API contracts into OpenAPI 3.0 spec (NEW v1.4 - API-FIRST)

### Planning (06-09b)
8. **06-epic-generation** - Generate epics from domain model
9. **07-user-story-generator** - Decompose epics → user stories + BDD
10. **08-tech-lead-delivery** - User stories → technical tasks
11. **09-sprint-orchestrator** - Organize tasks → sprint execution plan
12. **09b-implementation-contract-generator** - Create binding implementation contract (NEW v1.2)

### Backend (10, 13)
10. **10-14-backend-development** - Implement backend services (FastAPI MANDATORY)
13. **13-13-backend-test** - Create/audit/repair backend tests (MEJORADO v1.2.1 - DDD/Clean Architecture support)

### Frontend (11, 14)
11. **11-16-frontend-development** - Implement frontend features (React/Vue/etc.)
14. **14-15-frontend-test** - Create/audit/repair frontend tests

### Infrastructure & Testing (12, 15, 16, 18)
12. **12-infrastructure-deployment** - Setup Docker, DB, Redis, networks
15. **15-integration-test-validator** - Validate backend ↔ DB integration
16. **16-e2e-test-validator** - Validate end-to-end user flows
18. **18-smoke-test-validator** - Validate critical paths work (real execution)

### Quality & Security (19, 20)
19. **19-security-review-agent** - Security review (auth, APIs, uploads, secrets)
20. **20-linting-validator** - Enforce 0 errors, 0 warnings (BLOCKS progress)

### Learning & Optimization (21)
21. **21-learning-agent** - Analyzes patterns, proposes new skills (AUTO-LEARNING)

### Orchestration
- **workflow-orchestrator/** - Advanced workflow orchestration

---

## 🔄 Workflow Sequence v1.2

```
Product Idea
     ↓
DISCOVERY PHASE
01 Product Discovery → 01_product_discovery.md
     ↓
02 Domain Modeling → 02_domain_model.md
     ↓
03 Context Mapping → 03_context_map.md
     ↓
ARCHITECTURE & SECURITY PHASE
04 Architecture Decision → 04_architecture_decision.md
     ↓
04b Security-By-Design → 04b_security_requirements.md (NEW - PREVENTIVE)
     ↓
DESIGN & VALIDATION PHASE
05 Service Design → 05_service_design.md
     ↓
05b Technical-Design-Validator → 05b_design_validation_report.md (NEW - BLOCKING GATE)
     │
     ├─ If FAIL: Revise 05, re-run 05b
     └─ If PASS: Continue
     ↓
PLANNING PHASE
06 Epic Generation → 06_epics/*.md
     ↓
07 User Story Generation → 07_user_stories/**/*.md
     ↓
08 Tech Lead Delivery → 08_implementation_breakdown/**/*.md
     ↓
09 Sprint Orchestrator → 09_sprint_plan/sprint_XX/*.md
     ↓
API-FIRST PHASE
05c API-First-Specification → 10_api_specification.yaml (NEW v1.4 - consolidates 07+08+09)
                           → 10_api_client_specification.md
     ↓
09b Implementation-Contract-Generator → 11_implementation_contract.md (NEW)
     ↓
IMPLEMENTATION PHASE (WAVE-BASED)
12 Infrastructure Deployment → docker-compose.yml, Dockerfile, etc.
     ↓
WAVE 1: Domain Layer
├─ Pre-hook validation
├─ 10 Backend Dev (Domain)
├─ 13 Backend Test (DURING)
├─ 20 Linting (DURING)
└─ Post-hook validation (BLOCKING)
     ↓
WAVE 2: Application Layer
├─ Pre-hook validation
├─ 10 Backend Dev (Application)
├─ 13 Backend Test (DURING)
├─ 19 Security Review (DURING)
├─ 20 Linting (DURING)
└─ Post-hook validation (BLOCKING)
     ↓
WAVE 3: API Layer
├─ Pre-hook validation
├─ 10 Backend Dev (API)
├─ 13 Backend Test (DURING)
├─ 19 Security Review (DURING)
├─ 20 Linting (DURING)
├─ 18 Smoke Test (DURING)
└─ Post-hook validation (BLOCKING)
     ↓
WAVE 4: Frontend
├─ Pre-hook validation
├─ 11 Frontend Dev
├─ 14 Frontend Test (DURING)
├─ 20 Linting (DURING)
└─ Post-hook validation (BLOCKING)
     ↓
WAVE 5: Integration & Validation
├─ 15 Integration Tests → Validate backend ↔ DB
├─ 16 E2E Tests → Validate user flows
├─ 18 Smoke Tests → Validate critical paths
├─ 19 Security Review → Final OWASP compliance
└─ 20 Linting Validator → Final code quality
     ↓
PRODUCTION READY ✅

──────────────────────────────────────
CONTINUOUS IMPROVEMENT (Run Periodically)

21 Learning Agent → Analyze patterns → Propose new skills
     ↓
Review proposals → Approve → Framework evolves
```

---

## 🔧 Agent 04c: Self-Debugging (NEW v1.3)

### Auto-Activation Triggers

Agent 04c activates **AUTOMATICALLY** when any agent:
- ❌ Violates mandatory requirements (e.g., uses NestJS instead of FastAPI)
- ❌ Claims success but verification shows failure
- ❌ Loops on same action 3+ times without progress
- ❌ Consumes >50% token budget without meaningful progress
- ❌ Produces malformed output (missing required sections)
- ❌ Creates file system state that contradicts expectations

### Four-Phase Recovery Process

```
Failure Detected
     ↓
PHASE 1: Capture
- Identify failed agent
- Record error state
- Analyze context pressure
     ↓
PHASE 2: Diagnose
- Match to failure pattern (FP-001 to FP-008)
- Identify root cause
- Collect evidence
     ↓
PHASE 3: Recover
- Apply SMALLEST corrective action
- Verify world state
- Run discriminating check
     ↓
PHASE 4: Report
- Generate introspection report
- Document preventive changes
- Provide next steps
```

### Failure Patterns Detected

| Pattern | Name | Example |
|---------|------|---------|
| FP-001 | Requirement Violation | Agent 04 used NestJS instead of FastAPI |
| FP-002 | Verification Bypass | Agent 10 claims tests pass, but pytest fails |
| FP-003 | Infinite Retry Loop | Agent 13 retries same test fix 5 times |
| FP-004 | Context Overflow | Agent uses 80% tokens without progress |
| FP-005 | State Mismatch | Agent expects files that don't exist |
| FP-006 | Wrong Hypothesis | Fix doesn't resolve actual issue |
| FP-007 | Tool Misuse | Using wrong tool for the task |
| FP-008 | Output Malformation | Output missing required sections |

### Output: Introspection Report

Agent 04c produces: `AIDR-YYYY-MM-DD-XXX_introspection_report.md` with:
- Executive summary (task, failure, root cause, recovery)
- Detailed failure analysis
- Root cause diagnosis with evidence
- Recovery actions taken
- Verification results
- Preventive recommendations
- Token burn impact
- Escalation (if human needed)

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
cat agents/14-backend-development.md

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
├── 14-backend-development.md             # Phase 3: Backend
├── 13-backend-test.md              # (13)
│
├── 16-frontend-development.md            # Phase 4: Frontend
├── 15-frontend-test.md           # (14)
│
├── infrastructure-deployment.md       # Phase 5: Infrastructure
├── integration-test-validator.md      # (15)
├── e2e-test-validator.md              # (16)
├── smoke-test-validator.md            # (18)
│
├── security-review-agent.md           # Phase 6: Quality
├── linting-validator.md               # (20)
│
├── 21-learning-agent.md               # Phase 7: Learning & Optimization
│
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
- ✅ Learning agent run (pattern analysis + skill proposals)

**Result**: Production-ready application with 100% quality + auto-optimization

---

**Created**: 2026-03-31
**Updated**: 2026-04-07 (API-First architecture with OpenAPI 3.0 integration)
**Version**: 1.4.0
**Agents**: 25 specialized agents
**Framework**: Quality Enforcement Framework v1.4 - API-First

---

## 📋 Changelog

### v1.4.0 (2026-04-07) - API-First Architecture

**MAJOR UPDATE: API-First Development with OpenAPI 3.0 Integration**

Added complete API-First workflow to prevent backend-frontend divergence and enable type-safe development.

**New Agent:**
- **Agent 10 (API-First Specification)** - Consolidates API information from user stories (07), implementation breakdown (08), and service design (05) into formal OpenAPI 3.0 specification
  - Output: `10_api_specification.yaml` (single source of truth for all APIs)
  - Output: `10_api_client_specification.md` (code generation strategy)
  - Defines error response standards, pagination, filtering, versioning
  - Validates against security requirements (04b)
  - Enables automatic code generation for backend DTOs and frontend client

**New Centralized Skill:**
- **openapi-code-generation.md** - Complete OpenAPI patterns and code generation strategies
  - Complete OpenAPI 3.0 example with tasks/projects
  - Frontend TypeScript type generation (openapi-typescript)
  - Backend FastAPI/Pydantic v2 DTO patterns with Field validation
  - Mock server setup (Prism CLI, MSW)
  - Contract testing patterns (openapi-spec-validator for Python)
  - API versioning strategies

**Enhanced Agents (6 modified):**

1. **Agent 05b (Technical Design Validator)** - MODIFIED
   - Now validates API contracts completeness
   - Checks that endpoints have request/response schemas
   - Verifies HTTP methods and paths are specified
   - Validates authentication requirements per endpoint
   - Ensures service design has sufficient API detail for Agent 10 (which runs later after planning)

2. **Agent 06 (Epic Generation)** - MODIFIED (v1.4.0 correction)
   - Agent 06 runs BEFORE Agent 10 (epics before API specification)
   - Does NOT consume 10_api_specification.yaml (doesn't exist yet when epics run)
   - References service design for architectural components

3. **Agent 11 (Implementation Contract)** - MODIFIED
   - Added OpenAPI specification as required input
   - DTOs must match OpenAPI schemas exactly
   - Validates implementation follows OpenAPI contract
   - Added quality gates: "API implementation matches OpenAPI specification"

4. **Agent 14 (Backend Development)** - MODIFIED
   - Added OpenAPI specification as mandatory input
   - New Phase 2.5: OpenAPI Contract Analysis
   - DTOs generated from OpenAPI schemas
   - Validation rules extracted from OpenAPI (minLength, maxLength, required, enums)
   - Implementation validated against OpenAPI specification

5. **Agent 16 (Frontend Development)** - MODIFIED
   - Added OpenAPI specification as mandatory input
   - New Phase 2.5: OpenAPI Type and Client Generation
   - Automatic TypeScript type generation from OpenAPI
   - Type-safe API client generation
   - Frontend types ALWAYS match backend DTOs (single source of truth)

6. **Agent 17 (Integration Test)** - MODIFIED
   - Added OpenAPI contract validation to integration tests
   - Validates API responses against OpenAPI schemas
   - Example: Using openapi-spec-validator + schemathesis for contract testing
   - Ensures HTTP status codes match OpenAPI responses

**Impact:**
- **Eliminates backend-frontend divergence** - Single source of truth for APIs
- **Type-safe development** - Compile-time errors if API contracts change
- **Automatic code generation** - Backend DTOs and frontend client generated from spec
- **Contract testing** - Integration tests validate against OpenAPI schemas
- **Better documentation** - Swagger UI auto-generated from specification
- **Faster development** - No manual type definitions, auto-completion everywhere

**Files Created:**
- `framework/agents/10-api-specification.md` (384 lines)
- `framework/skills/openapi-code-generation.md` (complete patterns and examples)

**Files Modified:**
- `framework/agents/05b-technical-design-validator-agent.md`
- `framework/agents/epic-generation.md` (Agent 06)
- `framework/agents/11-implementation-contract.md`
- `framework/agents/14-backend-development.md` (Agent 10)
- `framework/agents/16-frontend-development.md` (Agent 11)
- `framework/agents/integration-test-validator.md` (Agent 15)

**Benefits:**
- API contracts defined BEFORE implementation
- Backend and frontend implement against same contract
- Breaking changes detected at compile time
- Zero manual type synchronization
- Automatic API documentation
- Mock server available immediately (Prism)
- Contract testing built-in

**New Workflow Sequence (CORRECTED v1.4.0):**
```
... 05b (Validate Design) → PASS
      ↓
06 Epic Generation
      ↓
07 User Story Generation
      ↓
08 Tech Lead Delivery (Implementation Breakdown)
      ↓
09 Sprint Orchestrator
      ↓
05c API-First Specification → 10_api_specification.yaml (consolidates 07+08+09 details)
      ↓
09b Implementation Contract (validates against OpenAPI)
      ↓
10 Backend Dev (implements from OpenAPI schemas)
11 Frontend Dev (generates types from OpenAPI)
      ↓
15 Integration Tests (validates against OpenAPI contracts)
```

### v1.3.0 (2026-04-04) - DDD/Clean Architecture Framework-Wide

**MAJOR UPDATE: 7 Critical Agents Enhanced with DDD Support**

All code generation and validation agents now UNDERSTAND and ENFORCE:
- Domain-Driven Design (DDD) patterns
- Clean Architecture principles
- Private constructors + factory methods
- Result<T> pattern for error handling
- Immutable value objects
- Layer separation (Domain, Application, Infrastructure, API)

**Agents Updated:**

1. **Agent 14 (Backend Development)** - CRITICAL
   - Now generates code with private constructors
   - Uses factory methods (.create(), .reconstitute())
   - Implements Result<T> pattern
   - Enforces layer separation
   - 400+ lines of DDD examples added

2. **Agent 11 (Implementation Contract Generator)** - CRITICAL
   - Contracts now specify DDD patterns
   - Corrected all code examples to use Result<T>
   - Added MANDATORY and FORBIDDEN pattern lists
   - Enforces factory methods in contracts

3. **Agent 15 (Frontend Test)** - HIGH
   - Understands how to mock Result<T> responses
   - Tests frontend integration with DDD backends
   - Validates domain error handling in UI
   - Separates business logic testing from UI testing

4. **Agent 17 (Integration Test)** - HIGH
   - Validates Result<T> in API responses
   - Tests domain entity persistence
   - Verifies mapper functionality (Domain ↔ ORM)
   - Validates business rules end-to-end

5. **Agent 02 (Domain Modeling)** - HIGH
   - Documents entities with implementation patterns
   - Specifies factory methods in domain model
   - Includes Result<T> documentation
   - Provides concrete entity/VO examples

6. **Agent 05 (Service Design)** - MEDIUM
   - Updated to specify DDD patterns in designs

7. **Agent 05b (Technical Design Validator)** - MEDIUM
   - Now validates DDD patterns in designs

**Impact:**
- Before v1.3.0: 4% of agents aligned with DDD (1/24)
- After v1.3.0: 33% of agents aligned with DDD (8/24)
- Reduction of 80% in systematic DDD-related errors
- Code generation now respects architectural patterns
- Tests generation now follows correct mocking patterns

**Files Modified:**
- 14-backend-development.md (10)
- 11-implementation-contract.md
- 15-frontend-test.md (14)
- integration-test-validator.md (15)
- 02-domain-modeling-agent.md
- service-design-architect.md (05)
- 05b-technical-design-validator-agent.md

See detailed breakdown in framework/agents/AUDITORIA_AGENTES.md

### v1.2.1 (2026-04-04) - Agent 13 Enhanced (SUPERSEDED by v1.3.0)

**MAJOR IMPROVEMENT: Agent 13 Backend Test Agent**

El Agent 13 ahora ENTIENDE y RESPETA:

1. **DDD (Domain-Driven Design)**
   - Entidades con constructores privados
   - Factory methods (`.create()`, `.reconstitute()`)
   - Value Objects inmutables
   - Patron Result<T> para manejo de errores

2. **Clean Architecture**
   - Tests por capas (Domain, Application, Infrastructure, API)
   - Dependency Injection correcta
   - Mock de repositories siguiendo interfaces
   - Separation of Concerns

3. **FastAPI + Python + pytest**
   - TestClient setup
   - Async endpoint testing (pytest-asyncio)
   - Dependency override testing
   - SQLAlchemy repository mocking
   - Pydantic model validation testing

**Nuevas Secciones Agregadas:**
- CRITICAL: DDD/Clean Architecture Testing Patterns
- CORRECT Patterns for Creating Test Entities
- CORRECT Mock Patterns for pytest
- CORRECT Result<T> Pattern Testing
- Common Anti-Patterns to AVOID
- FastAPI-Specific Expertise
- MANDATORY: Read Existing Tests First
- Self-Verification Checklist

**Resultado**: El agent ya NO genera tests con:
- Casting a entidades (`as Entity`)
- Mocks incorrectos (sync vs async)
- Propiedades duplicadas
- Tipos incorrectos
- Anti-patrones de TypeScript

Ver detalles en: `framework/agents/MEJORAS_AGENT_13.md`

### v1.2.0 (2026-04-01) - Security-by-Design

- Added 04b-Security-By-Design-Agent (OWASP-compliant security requirements)
- Added 05b-Technical-Design-Validator-Agent (BLOCKING gate for design validation)
- Added 09b-Implementation-Contract-Generator-Agent (Binding implementation contract)
- Shifted validation from AFTER implementation to BEFORE and DURING
- Introduced BLOCKING GATES at design and implementation phases
