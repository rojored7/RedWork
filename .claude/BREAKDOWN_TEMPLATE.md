# Template for claude.local.md in Story Breakdown Folders

This template MUST be created by the agent in each `story_*/` folder before generating the breakdown files.

## File: claude.local.md

```markdown
# Implementation Breakdown Instructions - {STORY_ID}: {STORY_NAME}

## Story Context

**Epic**: {EPIC_NAME}
**Story ID**: {STORY_ID}
**Story Title**: {STORY_TITLE}
**Story File**: `../../07_user_stories/{epic_folder}/{story_file}.md`

## Required Files to Create

This breakdown MUST generate exactly 8 files in this directory:

1. ✅ `01_backend_tasks.md` - Backend implementation tasks
2. ✅ `02_frontend_tasks.md` - Frontend implementation tasks
3. ✅ `03_database_tasks.md` - Database schema and migrations
4. ✅ `04_devops_tasks.md` - Infrastructure and deployment
5. ✅ `05_security_tasks.md` - Security implementation
6. ✅ `06_qa_testing_tasks.md` - Testing strategy and tests
7. ✅ `07_observability_tasks.md` - Logging, metrics, monitoring
8. ✅ `README.md` - Summary and implementation guide

## Architecture References

**Domain Model**: `../../02_domain_model.md`
- Entities: {LIST_RELEVANT_ENTITIES}
- Value Objects: {LIST_RELEVANT_VOS}
- Aggregates: {LIST_RELEVANT_AGGREGATES}
- Business Rules: {LIST_APPLICABLE_RULES}
- Domain Events: {LIST_RELEVANT_EVENTS}

**Architecture Decision**: `../../04_architecture_decision.md`
- Pattern: Modular Monolith with Clean Architecture
- Tech Stack: Node.js + TypeScript + NestJS + PostgreSQL + Redis
- Communication: Event-driven with in-memory bus

**Service Design**: `../../05_service_design.md`
- Service: {BOUNDED_CONTEXT_NAME}
- Layers: Domain → Application → Infrastructure
- Ports & Adapters: {LIST_RELEVANT_PORTS}

## Story Acceptance Criteria

{PASTE_ACCEPTANCE_CRITERIA_FROM_STORY}

## BDD Scenarios

{PASTE_BDD_SCENARIOS_FROM_STORY}

## Technical Requirements per File

### 01_backend_tasks.md Structure
```
# Backend Tasks - {STORY_ID}

## Domain Layer Tasks
- [ ] Task 1: Create/Update entities
- [ ] Task 2: Implement value objects
- [ ] Task 3: Define domain events
- [ ] Task 4: Enforce business rules

## Application Layer Tasks
- [ ] Task 5: Create use case
- [ ] Task 6: Implement command handlers
- [ ] Task 7: Implement query handlers
- [ ] Task 8: Define DTOs

## Infrastructure Layer Tasks
- [ ] Task 9: Implement repository
- [ ] Task 10: Create adapters
- [ ] Task 11: Integrate external services

## API Layer Tasks
- [ ] Task 12: REST endpoints
- [ ] Task 13: GraphQL resolvers
- [ ] Task 14: WebSocket handlers

## Validation
- [ ] Task 15: Input validation
- [ ] Task 16: Business rule validation
```

### 02_frontend_tasks.md Structure
```
# Frontend Tasks - {STORY_ID}

## Component Development
- [ ] Task 1: Create main component
- [ ] Task 2: Create child components
- [ ] Task 3: Implement forms

## State Management
- [ ] Task 4: Define Zustand stores
- [ ] Task 5: Setup React Query
- [ ] Task 6: Implement cache strategy

## Integration
- [ ] Task 7: API integration
- [ ] Task 8: WebSocket subscription
- [ ] Task 9: Error handling

## UX/UI
- [ ] Task 10: Styling with Tailwind
- [ ] Task 11: Loading states
- [ ] Task 12: Animations
```

### 03_database_tasks.md Structure
```
# Database Tasks - {STORY_ID}

## Schema Design
- [ ] Task 1: Create migration files
- [ ] Task 2: Define tables
- [ ] Task 3: Add constraints

## Performance
- [ ] Task 4: Create indexes
- [ ] Task 5: Optimize queries
- [ ] Task 6: Partitioning strategy

## Data Management
- [ ] Task 7: Seed data
- [ ] Task 8: Migration scripts
```

### 04_devops_tasks.md Structure
```
# DevOps Tasks - {STORY_ID}

## Infrastructure
- [ ] Task 1: Update infrastructure as code
- [ ] Task 2: Environment variables
- [ ] Task 3: Service configuration

## CI/CD
- [ ] Task 4: Pipeline updates
- [ ] Task 5: Deployment steps
- [ ] Task 6: Rollback procedures

## Monitoring
- [ ] Task 7: Health checks
- [ ] Task 8: Feature flags
```

### 05_security_tasks.md Structure
```
# Security Tasks - {STORY_ID}

## Authentication & Authorization
- [ ] Task 1: Auth implementation
- [ ] Task 2: Permission checks
- [ ] Task 3: RBAC/ABAC

## Data Protection
- [ ] Task 4: Input sanitization
- [ ] Task 5: Encryption
- [ ] Task 6: Audit logging

## Threat Mitigation
- [ ] Task 7: Rate limiting
- [ ] Task 8: OWASP Top 10 checks
```

### 06_qa_testing_tasks.md Structure
```
# QA Testing Tasks - {STORY_ID}

## Unit Tests
- [ ] Task 1: Domain tests
- [ ] Task 2: Application tests
- [ ] Task 3: Component tests

## Integration Tests
- [ ] Task 4: API tests
- [ ] Task 5: Database tests
- [ ] Task 6: Service integration

## E2E Tests
- [ ] Task 7: Happy path
- [ ] Task 8: Error scenarios
- [ ] Task 9: BDD scenarios
```

### 07_observability_tasks.md Structure
```
# Observability Tasks - {STORY_ID}

## Logging
- [ ] Task 1: Structured logging
- [ ] Task 2: Error logging
- [ ] Task 3: Audit logging

## Metrics
- [ ] Task 4: Business metrics
- [ ] Task 5: Performance metrics
- [ ] Task 6: Custom dashboards

## Tracing
- [ ] Task 7: Distributed tracing
- [ ] Task 8: APM integration
```

### README.md Structure
```
# Implementation Breakdown - {STORY_ID}

## Overview
Story summary and business value

## Architecture Alignment
How this implements domain model

## Implementation Order
1. Database setup
2. Backend core
3. API layer
4. Frontend
5. Testing
6. Deployment

## Dependencies
Prerequisites and blockers

## Definition of Done
Checklist for completion

## Estimates
- Story Points: {X}
- Hours: {Y}
- Team: {Z}
```

## Quality Standards

Each task MUST include:
- ✅ Specific file path in codebase
- ✅ Class/function names from service design
- ✅ Story point estimate (1,2,3,5,8,13)
- ✅ Acceptance criteria
- ✅ Dependencies on other tasks

## Validation Checklist

Before marking this breakdown complete:
- [ ] All 8 files created
- [ ] Each file has 15+ tasks minimum
- [ ] All tasks reference architecture documents
- [ ] Story points estimated for each file
- [ ] Total matches story complexity
- [ ] BDD scenarios mapped to E2E tests
- [ ] Security tasks cover OWASP Top 10
- [ ] Observability covers logging, metrics, tracing

## Estimated Effort

**Total Story Points**: {CALCULATE_FROM_TASKS}
**Estimated Hours**: {STORY_POINTS * 1.5}
**Team Members**: {BACKEND + FRONTEND + QA + DEVOPS}
**Sprint Duration**: {WEEKS}

---

**Status**: ⏳ Breakdown in Progress
**Created**: {TIMESTAMP}
**Agent**: 08-Tech-Lead-Delivery-Agent
```

## Instructions for Agent

When processing a story:

1. **READ** the story file from `07_user_stories/epic_*/US-*.md`
2. **CREATE** this `claude.local.md` file in the breakdown folder
3. **FILL IN** all {PLACEHOLDER} values with actual content
4. **USE** this file as a checklist while creating the 8 breakdown files
5. **UPDATE** status to ✅ when all 8 files are complete
6. **VALIDATE** all checkboxes are marked before moving to next story

This ensures consistency and completeness across all story breakdowns.
