# Template for claude.md in Epic Folders

This template MUST be created by the 07-User-Story-Generation-Agent in each epic folder before generating user stories.

## File: 07_user_stories/epic_XX_name/claude.md

```markdown
# Epic Control Document - {EPIC_ID}: {EPIC_NAME}

## Epic Context

**Epic ID**: {EPIC_ID} (e.g., Epic 04)
**Epic Name**: {EPIC_NAME} (e.g., Colaboración Equipos)
**Epic File**: `../../06_epics/{epic_file}.md`
**Business Value**: {EPIC_BUSINESS_VALUE}
**Target Users**: {PRIMARY_USER_ROLES}

## Epic Objectives

{PASTE_EPIC_OBJECTIVES_FROM_SOURCE}

## Acceptance Criteria (Epic Level)

{PASTE_EPIC_ACCEPTANCE_CRITERIA}

## Required User Stories

This epic MUST generate minimum 2-5 user stories covering:

1. **Core Functionality**: Main feature implementation
2. **User Experience**: UI/UX aspects
3. **Integration**: Connection with other contexts
4. **Edge Cases**: Error handling, validations
5. **Performance**: Optimization considerations (if applicable)

### User Story Numbering Convention

- **Epic 01**: US-001 to US-009
- **Epic 02**: US-010 to US-019
- **Epic 03**: US-020 to US-029
- **Epic 04**: US-040 to US-049
- **Epic 05**: US-050 to US-059
- **Epic 06**: US-060 to US-069
- **Epic 07**: US-070 to US-079
- **Epic 08**: US-080 to US-089
- **Epic 09**: US-090 to US-099
- **Epic 10**: US-100 to US-109
- **Epic 11**: US-110 to US-119
- **Epic 12**: US-120 to US-129
- **Epic 13**: US-130 to US-139
- **Epic 14**: US-140 to US-149
- **Epic 15**: US-150 to US-159

**This Epic Range**: US-{START_ID} to US-{END_ID}

## Domain Model References

**Relevant from**: `../../02_domain_model.md`

### Entities Involved
- {LIST_ENTITIES} (e.g., Task, User, Project, Team)

### Value Objects
- {LIST_VALUE_OBJECTS} (e.g., Priority, Tag, TeamMember)

### Aggregates
- {LIST_AGGREGATES} (e.g., Task Aggregate, Team Aggregate)

### Business Rules Applicable
- {LIST_BUSINESS_RULES} (e.g., R11: Solo propietario puede eliminar proyecto)

### Domain Events
- {LIST_DOMAIN_EVENTS} (e.g., TaskCreated, ProjectMemberAdded)

## Architecture Alignment

**From**: `../../04_architecture_decision.md`

### Bounded Context
- **Primary Context**: {CONTEXT_NAME} (e.g., Collaboration Context)
- **Supporting Contexts**: {LIST_SUPPORTING_CONTEXTS}

### Technical Stack
- Backend: Node.js + TypeScript + NestJS
- Database: PostgreSQL (schema: {schema_name})
- Cache: Redis
- Real-time: WebSockets (if applicable)
- Frontend: React + TypeScript + Zustand

### Communication Patterns
- **Sync**: {SYNC_PATTERNS} (e.g., Direct method calls within monolith)
- **Async**: {ASYNC_PATTERNS} (e.g., Event bus for notifications)

## Service Design References

**From**: `../../05_service_design.md`

### Service Layer Mapping
- **Domain Layer**: {DOMAIN_COMPONENTS}
- **Application Layer**: {USE_CASES}
- **Infrastructure Layer**: {REPOSITORIES_AND_ADAPTERS}
- **API Layer**: {ENDPOINTS}

### Ports & Adapters
- **Primary Ports**: {DRIVING_PORTS}
- **Secondary Ports**: {DRIVEN_PORTS}

## User Story Template

Each user story in this epic MUST follow this structure:

```markdown
# US-{ID}: {Story Title}

## User Story

**As a** {user_role}
**I want** {feature}
**So that** {business_value}

## Business Value

{Detailed explanation of why this matters}

**Value Metrics**:
- {metric_1}
- {metric_2}

## Acceptance Criteria

**Functional Requirements**:
1. [ ] {criterion_1}
2. [ ] {criterion_2}
3. [ ] {criterion_3}
4. [ ] {criterion_4}
5. [ ] {criterion_5}

**Non-Functional Requirements**:
- Performance: {requirement}
- Security: {requirement}
- Usability: {requirement}

## BDD Scenarios

### Scenario 1: {Happy Path Name}
```gherkin
Given {precondition}
When {action}
Then {expected_result}
```

### Scenario 2: {Alternative Path Name}
```gherkin
Given {precondition}
When {action}
Then {expected_result}
```

### Scenario 3: {Error Case Name}
```gherkin
Given {precondition}
When {action}
Then {expected_error}
```

## Technical Considerations

### Domain Model Impact
- Entities: {affected_entities}
- New/Modified: {what_changes}

### Architecture Implications
- Bounded Context: {context}
- Integration Points: {integrations}

### Dependencies
- **Blocks**: {what_this_blocks}
- **Blocked By**: {what_blocks_this}
- **Related**: {related_stories}

## Estimated Complexity

- **Story Points**: {1,2,3,5,8,13}
- **Development Hours**: {estimate}
- **Team**: Backend + Frontend + QA

## Definition of Done

- [ ] Code implemented following Clean Architecture
- [ ] Unit tests > 80% coverage
- [ ] Integration tests passing
- [ ] E2E tests for all BDD scenarios
- [ ] Security review completed
- [ ] Performance validated
- [ ] Documentation updated
- [ ] Code reviewed and approved
- [ ] Deployed to staging
- [ ] QA sign-off received
```

## Quality Standards for This Epic

### Story Completeness Checklist
- [ ] Each story has clear user role
- [ ] Business value is measurable
- [ ] Minimum 5 acceptance criteria
- [ ] Minimum 3 BDD scenarios (happy path + alternative + error)
- [ ] Technical considerations reference domain model
- [ ] Dependencies identified
- [ ] Story points estimated
- [ ] Definition of Done included

### Domain Alignment
- [ ] All stories map to domain entities
- [ ] Business rules enforced
- [ ] Domain events identified
- [ ] Aggregates respected

### Architecture Alignment
- [ ] Stories fit within bounded context
- [ ] Communication patterns defined
- [ ] Integration points clear
- [ ] Technology stack followed

## Extra Instructions for This Epic

### Specific Considerations

**Epic 01 (Autenticación)**:
- Security is paramount - every story needs security review
- Include password policies, token management
- Consider OAuth providers
- Rate limiting for authentication attempts

**Epic 02 (Gestión Tareas)**:
- Core domain - align closely with Task aggregate
- Consider offline scenarios
- Real-time updates for collaborative editing
- Undo/redo functionality

**Epic 03 (Proyectos)**:
- Multi-tenancy considerations
- Permission management crucial
- Template system for project creation
- Archiving and restoration flows

**Epic 04 (Colaboración Equipos)**:
- Team aggregate alignment
- Invitation workflow states
- Role-based access control (RBAC)
- Activity feed and notifications

**Epic 05 (Sincronización)**:
- Conflict resolution strategy critical
- Offline-first architecture
- Event sourcing patterns
- WebSocket scaling considerations

**Epic 06 (Notificaciones)**:
- Multi-channel delivery (email, push, in-app)
- User preferences management
- Digest and batching logic
- Delivery tracking and retry

**Epic 07 (Búsqueda y Filtrado)**:
- Full-text search with PostgreSQL or Elasticsearch
- Faceted search support
- Query performance optimization
- Search result relevance

**Epic 08 (Analytics)**:
- Read model design (CQRS)
- Aggregation strategies
- Real-time vs batch processing
- Data privacy considerations

**Epic 09 (Integraciones)**:
- OAuth flow for third-party services
- Webhook management
- API versioning
- Error handling and retries

**Epic 10 (Automatización)**:
- Rule engine design
- Trigger-action patterns
- Infinite loop prevention
- Testing automation rules

**Epic 11 (Aplicaciones Móviles)**:
- Offline-first mobile architecture
- Native feature integration (camera, notifications)
- App store compliance
- Mobile-specific UX patterns

**Epic 12 (Suscripciones)**:
- Payment provider integration
- Subscription lifecycle management
- Billing and invoicing
- Grace period and dunning

**Epic 13 (Infraestructura)**:
- Infrastructure as Code
- CI/CD pipeline automation
- Monitoring and observability
- Disaster recovery

**Epic 14 (Seguridad)**:
- OWASP Top 10 compliance
- Penetration testing
- Security audit trail
- Compliance certifications (SOC 2, GDPR)

**Epic 15 (Onboarding)**:
- Progressive disclosure
- Interactive tutorials
- Sample data generation
- Help documentation

### Common Pitfalls to Avoid

1. **Too Generic**: Stories should be specific and actionable
2. **Missing Edge Cases**: Always include error scenarios
3. **No Integration**: Consider how this connects to other epics
4. **Performance Ignored**: Include performance acceptance criteria
5. **Security Afterthought**: Security must be designed in, not bolted on

## Validation Before Completion

### Epic-Level Checklist
- [ ] Minimum 2 user stories created
- [ ] All story IDs within epic range (US-{START} to US-{END})
- [ ] Each story file exists in this folder
- [ ] Each story follows template structure
- [ ] All stories reference this claude.md
- [ ] Epic objectives fully covered by stories
- [ ] No duplicate story IDs
- [ ] All dependencies between stories documented

### Cross-Epic Dependencies
- **Depends On**: {LIST_PREREQUISITE_EPICS}
- **Enables**: {LIST_DEPENDENT_EPICS}

## Metrics and Success Criteria

### Story Count
- **Target**: {2-5} stories
- **Actual**: {COUNT_WHEN_DONE}

### Coverage
- **Epic Objectives Covered**: {PERCENTAGE}
- **Business Value Delivered**: {DESCRIPTION}

### Estimated Effort
- **Total Story Points**: {SUM_OF_ALL_STORIES}
- **Estimated Development Hours**: {TOTAL_HOURS}
- **Team Size Needed**: {TEAM_COUNT}
- **Sprint Duration**: {WEEKS}

---

## Instructions for Agent 07

When processing this epic:

1. **READ** this claude.md file completely
2. **UNDERSTAND** the epic scope and objectives
3. **IDENTIFY** 2-5 key user stories that deliver the epic value
4. **CREATE** each user story using the template above
5. **VALIDATE** all stories against quality standards
6. **UPDATE** metrics section with actual counts
7. **MARK** status as complete

## Status

- **Epic Processing Status**: ⏳ In Progress / ✅ Complete
- **Stories Created**: {COUNT} / {TARGET}
- **Agent**: 07-User-Story-Generation-Agent
- **Created**: {TIMESTAMP}
- **Last Updated**: {TIMESTAMP}

---

**This document serves as the source of truth for all user stories in this epic.**
**All user stories MUST reference back to this document.**
**Any changes to epic scope must update this document first.**
```

## Implementation Notes for Agent

When processing an epic:

1. **FIRST**: Create `claude.md` in epic folder
2. **THEN**: Fill all {PLACEHOLDERS} with actual content from epic file
3. **THEN**: Create user story files based on claude.md guidance
4. **FINALLY**: Update claude.md with final metrics

This ensures:
- Consistency across all stories in the epic
- Clear traceability to epic objectives
- Validation checklist before moving to next epic
- Central reference for implementation teams
