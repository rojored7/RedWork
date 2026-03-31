# CLAUDE.md - Sprint Plan Instructions

## Overview

This sprint plan is organized by **complete epics** that deliver end-to-end business value. Each sprint delivers one or more fully functional epics.

## Project Information

**Project**: [Project Name]
**Architecture**: [Architecture Type]
**Tech Stack**:
- Backend: [Tech Stack]
- Frontend: [Tech Stack]
- Database: [Database]
- Infrastructure: [Infrastructure]

## Sprint Execution Protocol

### For Development Agents

When executing a sprint, you MUST:

1. **Read the Epic Sprint Plan**
   - Open the file: `epic_XX_sprint_plan.md`
   - Understand the complete epic scope
   - Review all user stories (US-XXX) in the epic

2. **For Each User Story (US-XXX)**
   - Read the original story: `07_user_stories/epic_XX/US-XXX_[name].md`
   - Read ALL implementation files in: `08_implementation_breakdown/epic_XX/story_XXX/`
     - 01_backend_tasks.md
     - 02_frontend_tasks.md
     - 03_database_tasks.md
     - 04_devops_tasks.md
     - 05_security_tasks.md
     - 06_qa_testing_tasks.md
     - 07_observability_tasks.md

3. **Execute Tasks in Order**
   - Follow the task sequence defined in epic_XX_sprint_plan.md
   - Complete ALL tasks for a user story before moving to the next
   - Mark tasks as complete in the epic plan file

4. **Validate Before Moving On**
   - All acceptance criteria met
   - All tests passing (>80% coverage)
   - Code reviewed
   - Deployed to staging
   - User story is 100% complete

## Epic-Driven Development Rules

### ✅ CORRECT Approach

```
Sprint 1-2: Complete Epic 01 - Authentication
  → Deliver: Working login, registration, password recovery
  → Demo: User can create account, login, recover password
  → 100% functional authentication system
```

### ❌ WRONG Approach

```
Sprint 1: Backend authentication + Frontend login page
  → Partial functionality
  → Cannot demo complete feature
  → Leaves technical debt
```

## Definition of Done

### User Story Level
- [ ] All tasks from implementation breakdown completed
- [ ] All acceptance criteria from 07_user_stories met
- [ ] Unit tests written and passing (>80% coverage)
- [ ] Integration tests passing
- [ ] Code reviewed by 2+ developers
- [ ] Security scan passed (no critical/high issues)
- [ ] Documentation updated
- [ ] Deployed to staging environment
- [ ] Feature demoed to Product Owner
- [ ] User story marked complete in epic plan

### Epic Level
- [ ] ALL user stories in epic completed per DoD
- [ ] Epic-level integration tests passing
- [ ] End-to-end feature flow working
- [ ] Performance benchmarks met
- [ ] Security audit completed
- [ ] User documentation written
- [ ] Demo prepared for stakeholders
- [ ] Epic marked ✓ in sprint_overview.md

### Sprint Level
- [ ] All epics assigned to sprint completed
- [ ] Sprint goal achieved
- [ ] System integration tests passing
- [ ] No critical or high bugs
- [ ] Sprint demo completed
- [ ] Retrospective completed
- [ ] Next sprint planned

## Task Execution Order

### 1. Foundation Tasks (Do These First)
- Infrastructure setup from 04_devops_tasks.md
- Database schema from 03_database_tasks.md
- Security foundation from 05_security_tasks.md

### 2. Core Development (Do These Second)
- Backend implementation from 01_backend_tasks.md
- Frontend implementation from 02_frontend_tasks.md

### 3. Quality & Operations (Do These Last)
- QA tests from 06_qa_testing_tasks.md
- Observability from 07_observability_tasks.md

## Cross-Epic Dependencies

Before starting an epic, verify dependencies are met:

**Example:**
- Epic 02 (Gestión Tareas) requires Epic 01 (Autenticación) to be 100% complete
- Epic 04 (Colaboración) requires Epic 02 (Gestión Tareas) and Epic 03 (Proyectos)

Check the `dependency_map.md` file for the complete dependency graph.

## Development Standards

### Code Quality Gates
- TypeScript strict mode enabled
- ESLint/Prettier passing
- No console.log in production code
- All functions documented (JSDoc)
- Error handling implemented
- Logging configured

### Testing Requirements
```
Unit Tests:        70% minimum coverage
Integration Tests: Critical paths covered
E2E Tests:         Happy path + error scenarios
Performance Tests: Response time < 200ms (P95)
Security Tests:    OWASP top 10 validated
```

### Git Workflow
```bash
# Feature branch per user story
git checkout -b feature/US-XXX-short-description

# Commits reference user story
git commit -m "feat(US-XXX): implement user registration endpoint"

# PR must reference user story and epic
PR Title: [Epic XX] US-XXX: User Registration
```

## Agent Coordination

### Backend Agent
- Implements 01_backend_tasks.md for each story
- Creates API contracts FIRST
- Updates OpenAPI documentation
- Writes unit + integration tests

### Frontend Agent
- Implements 02_frontend_tasks.md for each story
- Uses API contracts (can mock if backend in progress)
- Creates component tests
- Ensures accessibility (WCAG 2.1 AA)

### DevOps Agent
- Implements 04_devops_tasks.md
- Sets up infrastructure BEFORE development
- Maintains CI/CD pipeline
- Monitors deployments

### QA Agent
- Implements 06_qa_testing_tasks.md
- Creates test plans from user story acceptance criteria
- Performs manual testing
- Automates regression tests

## Epic Progress Tracking

Update the epic_XX_sprint_plan.md file as you work:

```markdown
### US-001: Registro con Email
**Status**: ✅ COMPLETED
**Completed**: 2024-03-20
**Reviewed By**: @developer1, @developer2

#### Implementation Tasks
- [x] Task BE-001-001: Create User entity (3h) - DONE
- [x] Task BE-001-002: Registration endpoint (4h) - DONE
- [x] Task FE-001-001: Registration form (5h) - DONE
...
```

## Common Mistakes to Avoid

### ❌ Don't Do This
1. Starting Epic 02 before Epic 01 is 100% done
2. Implementing only backend tasks and moving on
3. Skipping tests "to save time"
4. Creating PRs that span multiple user stories
5. Not updating the epic plan file as you work

### ✅ Do This Instead
1. Complete Epic 01 fully, then start Epic 02
2. Complete ALL tasks (backend, frontend, DB, DevOps, QA, etc.) for each story
3. Write tests BEFORE implementation (TDD)
4. One PR per user story maximum
5. Update epic plan after each task completion

## Emergency Procedures

### If Blocked on Dependencies
1. Check dependency_map.md for alternative paths
2. Communicate block in daily standup
3. Work on independent user stories in same epic
4. Do NOT start new epic if current epic blocked

### If Tests Are Failing
1. Do NOT mark user story as complete
2. Fix tests before moving to next story
3. Update task estimates if needed
4. Document lessons learned in retrospective

### If Scope Changes
1. Update the user story in 07_user_stories/
2. Regenerate implementation breakdown
3. Update epic_XX_sprint_plan.md
4. Communicate impact to sprint goal

## Performance Targets

### Backend
- API response time P95 < 200ms
- Database queries < 50ms
- Background jobs < 5s
- WebSocket latency < 100ms

### Frontend
- First Contentful Paint < 1.5s
- Time to Interactive < 3s
- Lighthouse score > 90
- Bundle size < 500KB initial load

### Infrastructure
- Deployment time < 5 minutes
- Auto-scaling response < 30s
- Uptime > 99.95%
- Backup/restore < 1 hour

## Daily Checklist

Every development agent should:

- [ ] Review epic_XX_sprint_plan.md for today's tasks
- [ ] Read implementation breakdown files for current US-XXX
- [ ] Complete assigned tasks
- [ ] Update task status in epic plan
- [ ] Create/update tests
- [ ] Run full test suite locally
- [ ] Create PR if user story complete
- [ ] Update documentation
- [ ] Check dependency_map.md for unblocking others

## Sprint Demo Preparation

At the end of each sprint:

1. Prepare demo for EACH completed epic
2. Show end-to-end user flow (not technical internals)
3. Demonstrate business value delivered
4. Highlight challenges overcome
5. Present metrics (velocity, quality, performance)

## Questions?

If unclear about:
- **Epic scope**: Read 06_epics/epic_XX_[name].md
- **User story details**: Read 07_user_stories/epic_XX/US-XXX_[name].md
- **Task details**: Read 08_implementation_breakdown/epic_XX/story_XXX/
- **Dependencies**: Read dependency_map.md
- **Timeline**: Read sprint_overview.md

---

**Remember**: Each epic must be 100% complete and demostrable. Partial features create technical debt and reduce business value.

**Version**: 1.0
**Template**: SPRINT_PLAN_CLAUDE_TEMPLATE.md
