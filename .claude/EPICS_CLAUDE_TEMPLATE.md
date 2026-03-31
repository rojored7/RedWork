# Template for claude.md in 06_epics/ Folder

This file MUST be created by the 06-Epic-Generation-Agent in the 06_epics/ folder to serve as the central control document for ALL epics.

## File: 06_epics/claude.md

```markdown
# Epic Generation Control Document - Task Manager Project

## Overview

This document serves as the **central source of truth** for all epics in the Task Manager project. Every epic file in this folder must align with the domain model, architecture decisions, and service design.

## Project Context

**Product**: Task Manager Pro (Task Management Application)
**Domain Model**: `../02_domain_model.md`
**Architecture**: `../04_architecture_decision.md` (Modular Monolith)
**Service Design**: `../05_service_design.md`
**Tech Stack**: Node.js + TypeScript + NestJS + PostgreSQL + Redis

## Epic Generation Rules

### Mandatory for Each Epic

Every epic file MUST contain:

1. **Epic Header**
   - Epic ID (Epic XX)
   - Epic Name
   - Business Value Statement
   - Target Users

2. **Epic Objectives**
   - Clear, measurable goals
   - Alignment with business strategy
   - Success metrics

3. **Functional Scope**
   - Core features included
   - Features explicitly excluded
   - Boundaries with other epics

4. **Acceptance Criteria (Epic Level)**
   - Minimum 5 criteria
   - Testable and measurable
   - Cover happy path + edge cases

5. **User Personas**
   - Primary users affected
   - Use cases covered

6. **Technical Considerations**
   - Domain entities involved
   - Architecture patterns needed
   - Integration points
   - Performance requirements
   - Security requirements

7. **Dependencies**
   - Prerequisites (other epics/features)
   - Enables (what this epic unlocks)

8. **Estimated Effort**
   - T-shirt size (S/M/L/XL)
   - Story count estimate
   - Sprint duration estimate

## Epic Catalog (15 Epics Total)

### Epic 01: Autenticación y Registro
**File**: `epic_01_autenticacion_y_registro.md`
**Status**: ✅ Created
**Business Value**: Enable secure user access and identity management
**Domain Entities**: User, UserPreferences, Subscription
**Bounded Context**: User Management Context
**Story Count**: 4-6 expected
**Dependencies**: None (foundation epic)
**Enables**: All other epics

### Epic 02: Gestión de Tareas Core
**File**: `epic_02_gestion_tareas_core.md`
**Status**: ✅ Created
**Business Value**: Core task management functionality
**Domain Entities**: Task, Comment, Tag, Attachment
**Bounded Context**: Task Management Context
**Story Count**: 5-8 expected
**Dependencies**: Epic 01 (authentication)
**Enables**: Epic 03, 04, 05

### Epic 03: Proyectos y Organización
**File**: `epic_03_proyectos_organizacion.md`
**Status**: ✅ Created
**Business Value**: Organize tasks into projects
**Domain Entities**: Project, ProjectSettings, TaskTemplate
**Bounded Context**: Collaboration Context
**Story Count**: 3-5 expected
**Dependencies**: Epic 01, Epic 02
**Enables**: Epic 04

### Epic 04: Colaboración en Equipos
**File**: `epic_04_colaboracion_equipos.md`
**Status**: {STATUS}
**Business Value**: Enable team collaboration and shared workspaces
**Domain Entities**: Team, TeamMember, Invitation
**Bounded Context**: Collaboration Context
**Story Count**: 4-6 expected
**Dependencies**: Epic 01, Epic 03
**Enables**: Epic 08, Epic 10

### Epic 05: Sincronización Multi-dispositivo
**File**: `epic_05_sincronizacion_multidispositivo.md`
**Status**: ✅ Created
**Business Value**: Work seamlessly across devices
**Domain Entities**: SyncLog, DeviceToken, ConflictResolution
**Bounded Context**: Integration Context
**Story Count**: 3-4 expected
**Dependencies**: Epic 02
**Enables**: Epic 11

### Epic 06: Notificaciones y Recordatorios
**File**: `epic_06_notificaciones_recordatorios.md`
**Status**: {STATUS}
**Business Value**: Keep users informed and engaged
**Domain Entities**: Notification, ReminderSettings, NotificationChannel
**Bounded Context**: Notification Context
**Story Count**: 4-5 expected
**Dependencies**: Epic 01, Epic 02
**Enables**: Epic 10

### Epic 07: Búsqueda y Filtrado
**File**: `epic_07_busqueda_filtrado.md`
**Status**: {STATUS}
**Business Value**: Find information quickly
**Domain Entities**: SearchIndex, SearchFilter, SavedSearch
**Bounded Context**: Task Management Context
**Story Count**: 3-4 expected
**Dependencies**: Epic 02
**Enables**: Epic 08

### Epic 08: Analytics y Reportes
**File**: `epic_08_analytics_reportes.md`
**Status**: {STATUS}
**Business Value**: Gain insights from productivity data
**Domain Entities**: ProductivityMetrics, Report, Dashboard
**Bounded Context**: Analytics Context (read model)
**Story Count**: 4-6 expected
**Dependencies**: Epic 02, Epic 04
**Enables**: None (leaf epic)

### Epic 09: Integraciones Externas
**File**: `epic_09_integraciones_externas.md`
**Status**: {STATUS}
**Business Value**: Connect with existing tools
**Domain Entities**: Integration, OAuthProvider, Webhook
**Bounded Context**: Integration Context
**Story Count**: 5-7 expected
**Dependencies**: Epic 01, Epic 02
**Enables**: None (leaf epic)

### Epic 10: Automatización y Reglas
**File**: `epic_10_automatizacion_reglas.md`
**Status**: {STATUS}
**Business Value**: Reduce manual work through automation
**Domain Entities**: AutomationRule, RuleTrigger, RuleAction
**Bounded Context**: Task Management Context
**Story Count**: 4-5 expected
**Dependencies**: Epic 02, Epic 04, Epic 06
**Enables**: None (leaf epic)

### Epic 11: Aplicaciones Móviles
**File**: `epic_11_aplicaciones_moviles.md`
**Status**: {STATUS}
**Business Value**: Access tasks on mobile devices
**Domain Entities**: Same as Epic 02 (reuse domain model)
**Bounded Context**: Task Management Context (mobile client)
**Story Count**: 6-8 expected
**Dependencies**: Epic 01, Epic 02, Epic 05
**Enables**: None (platform epic)

### Epic 12: Gestión de Suscripciones
**File**: `epic_12_gestion_suscripciones.md`
**Status**: {STATUS}
**Business Value**: Monetization and plan management
**Domain Entities**: Subscription, BillingCycle, SubscriptionLimits, Payment
**Bounded Context**: User Management Context
**Story Count**: 5-7 expected
**Dependencies**: Epic 01
**Enables**: All premium features

### Epic 13: Infraestructura y DevOps
**File**: `epic_13_infraestructura_devops.md`
**Status**: {STATUS}
**Business Value**: Reliable deployment and operations
**Domain Entities**: N/A (infrastructure)
**Bounded Context**: N/A (cross-cutting)
**Story Count**: 4-6 expected
**Dependencies**: None (parallel track)
**Enables**: All epics (operational support)

### Epic 14: Seguridad y Compliance
**File**: `epic_14_seguridad_compliance.md`
**Status**: {STATUS}
**Business Value**: Trust and regulatory compliance
**Domain Entities**: AuditLog, SecurityEvent, ComplianceReport
**Bounded Context**: N/A (cross-cutting)
**Story Count**: 5-7 expected
**Dependencies**: Epic 01
**Enables**: All epics (security foundation)

### Epic 15: Onboarding y Educación
**File**: `epic_15_onboarding_educacion.md`
**Status**: {STATUS}
**Business Value**: Reduce time to value for new users
**Domain Entities**: Tutorial, HelpArticle, OnboardingProgress
**Bounded Context**: User Management Context
**Story Count**: 3-5 expected
**Dependencies**: Epic 01, Epic 02
**Enables**: User activation

## Domain Model Mapping

### Entities Distribution Across Epics

| Entity | Primary Epic | Related Epics |
|--------|-------------|---------------|
| User | Epic 01 | All epics |
| Task | Epic 02 | 03, 04, 07, 10 |
| Project | Epic 03 | 02, 04, 08 |
| Team | Epic 04 | 03, 08 |
| Comment | Epic 02 | 04 |
| Notification | Epic 06 | 02, 04, 10 |
| Integration | Epic 09 | 02, 05 |
| Subscription | Epic 12 | 01 |

### Aggregates per Epic

- **Epic 01**: User Aggregate
- **Epic 02**: Task Aggregate
- **Epic 03**: Project Aggregate
- **Epic 04**: Team Aggregate
- **Epic 05**: Sync Aggregate (new)
- **Epic 06**: Notification Aggregate (new)
- **Epic 09**: Integration Aggregate (new)
- **Epic 10**: Automation Rule Aggregate (new)
- **Epic 12**: Subscription Aggregate (extends User)

### Business Rules Coverage

| Rule Category | Epic Coverage |
|--------------|---------------|
| Task Creation (R1-R6) | Epic 02, 12 |
| Prioritization (R7-R10) | Epic 02, 10 |
| Collaboration (R11-R15) | Epic 04 |
| Synchronization (R16-R19) | Epic 05 |
| Automation (R20-R23) | Epic 10 |
| Notification (R24-R27) | Epic 06 |
| Storage (R28-R31) | Epic 01, 02, 12 |

## Architecture Alignment

### Bounded Contexts per Epic

| Bounded Context | Epics |
|----------------|-------|
| Task Management | 02, 07, 10 |
| User Management | 01, 12, 15 |
| Collaboration | 03, 04 |
| Analytics | 08 |
| Notification | 06 |
| Integration | 05, 09 |

### Communication Patterns

**Synchronous Communication** (within monolith):
- Epic 01 ↔ Epic 02 (user validation)
- Epic 02 ↔ Epic 03 (task-project association)
- Epic 03 ↔ Epic 04 (project-team membership)

**Asynchronous Communication** (event-driven):
- Epic 02 → Epic 06 (task events → notifications)
- Epic 02 → Epic 08 (task events → analytics)
- Epic 04 → Epic 06 (team events → notifications)
- Epic 10 → Epic 02 (automation → task updates)

### Technology Stack per Epic

| Epic | Backend | Frontend | Database | Special |
|------|---------|----------|----------|---------|
| 01 | NestJS + JWT | React + Forms | PostgreSQL users schema | Auth0/Cognito |
| 02 | NestJS + CQRS | React + Rich Editor | PostgreSQL tasks schema | Redis cache |
| 03 | NestJS | React + Templates | PostgreSQL projects schema | - |
| 04 | NestJS + RBAC | React + Permissions UI | PostgreSQL teams schema | - |
| 05 | NestJS + WebSockets | Service Worker | PostgreSQL sync schema | IndexedDB |
| 06 | NestJS + Queues | React + Toast UI | PostgreSQL notifications | Redis queues |
| 07 | NestJS + Search | React + Facets | PostgreSQL FTS / Elastic | - |
| 08 | NestJS + CQRS | React + Charts | PostgreSQL analytics (read) | - |
| 09 | NestJS + OAuth | React + OAuth UI | PostgreSQL integrations | External APIs |
| 10 | NestJS + Rule Engine | React + Visual Builder | PostgreSQL rules | - |
| 11 | NestJS (same APIs) | React Native | Same schemas | Push notifications |
| 12 | NestJS + Stripe | React + Payment UI | PostgreSQL billing | Stripe/Paddle |
| 13 | Terraform/IaC | Monitoring UI | - | AWS/K8s |
| 14 | Security services | Audit UI | PostgreSQL audit logs | SIEM |
| 15 | Tutorial engine | Interactive UI | PostgreSQL help | - |

## Epic Dependencies Graph

```
Epic 01 (Auth)
    ├── Epic 02 (Tasks) ──┬── Epic 03 (Projects) ── Epic 04 (Teams)
    │                     ├── Epic 07 (Search)
    │                     ├── Epic 10 (Automation)
    │                     └── Epic 05 (Sync) ── Epic 11 (Mobile)
    ├── Epic 06 (Notifications)
    ├── Epic 09 (Integrations)
    ├── Epic 12 (Subscriptions)
    ├── Epic 14 (Security)
    └── Epic 15 (Onboarding)

Epic 04 ──> Epic 08 (Analytics)

Epic 13 (Infrastructure) → ALL (operational support)
```

## Implementation Roadmap

### Phase 1: Foundation (MVP - 6 months)
**Priority**: CRITICAL
- Epic 01: Autenticación ✅
- Epic 02: Tareas Core ✅
- Epic 03: Proyectos ✅
- Epic 05: Sincronización (básica) ✅

**Deliverable**: Functional task manager with auth and basic sync

### Phase 2: Collaboration (Months 7-9)
**Priority**: HIGH
- Epic 04: Equipos
- Epic 06: Notificaciones
- Epic 15: Onboarding

**Deliverable**: Team collaboration features

### Phase 3: Power Features (Months 10-12)
**Priority**: MEDIUM
- Epic 07: Búsqueda avanzada
- Epic 10: Automatización
- Epic 09: Integraciones (Google Calendar, Slack)

**Deliverable**: Power user features

### Phase 4: Scale & Monetize (Months 13-18)
**Priority**: MEDIUM-LOW
- Epic 08: Analytics
- Epic 11: Mobile apps
- Epic 12: Suscripciones premium

**Deliverable**: Mobile apps and premium tiers

### Phase 5: Enterprise (Months 18+)
**Priority**: LOW (depends on market)
- Epic 13: Infrastructure improvements
- Epic 14: Enterprise security (SSO, compliance)

**Deliverable**: Enterprise-ready platform

## Quality Standards for All Epics

### Epic Document Requirements

Each epic file MUST include:
- [ ] Clear business value statement
- [ ] Measurable success criteria
- [ ] Target user personas
- [ ] Functional scope (in/out)
- [ ] Domain entities referenced
- [ ] Architecture patterns identified
- [ ] Integration points defined
- [ ] Security considerations
- [ ] Performance requirements
- [ ] Dependencies listed
- [ ] Effort estimation

### Acceptance Criteria Format

Use this format for all epic acceptance criteria:
```
Given [context/precondition]
When [epic is implemented]
Then [measurable outcome]
And [additional outcome]
```

### Story Estimation Guidelines

- **Small Epic (S)**: 2-3 user stories, 1-2 weeks, 8-13 story points
- **Medium Epic (M)**: 4-6 user stories, 2-4 weeks, 21-34 story points
- **Large Epic (L)**: 7-10 user stories, 4-8 weeks, 55-89 story points
- **Extra Large (XL)**: 10+ user stories, 8+ weeks, 89+ story points

## Cross-Epic Validations

### Avoiding Duplication

Before creating an epic, check:
- [ ] Is this functionality already covered in another epic?
- [ ] Can this be merged with an existing epic?
- [ ] Is the scope too large (should it be split)?

### Ensuring Completeness

After creating all epics, verify:
- [ ] All product discovery objectives are covered
- [ ] All domain entities have an owning epic
- [ ] All bounded contexts are represented
- [ ] No gaps in user journeys
- [ ] Technical debt epics included (Epic 13, 14)

## Metrics and Success Criteria

### Epic Generation Metrics

- **Total Epics**: 15
- **Status Breakdown**:
  - Created: {COUNT}
  - In Progress: {COUNT}
  - Not Started: {COUNT}

- **Coverage Metrics**:
  - Domain Entities Covered: {PERCENTAGE}
  - Bounded Contexts Covered: {PERCENTAGE}
  - Business Rules Addressed: {PERCENTAGE}

### Effort Estimation Summary

| Phase | Epics | Total Story Points | Estimated Weeks |
|-------|-------|-------------------|----------------|
| Phase 1 (MVP) | 4 | {POINTS} | 24 weeks |
| Phase 2 | 3 | {POINTS} | 12 weeks |
| Phase 3 | 3 | {POINTS} | 12 weeks |
| Phase 4 | 3 | {POINTS} | 24 weeks |
| Phase 5 | 2 | {POINTS} | 12+ weeks |
| **TOTAL** | **15** | **{TOTAL}** | **84+ weeks** |

## Instructions for Epic Generation Agent

When creating or updating epics:

1. **READ** this claude.md file completely first
2. **VERIFY** epic doesn't duplicate existing functionality
3. **CHECK** domain model for relevant entities
4. **REVIEW** architecture for bounded context alignment
5. **CREATE** epic file using standard template
6. **UPDATE** this claude.md with epic status
7. **VALIDATE** dependencies are correct
8. **ESTIMATE** effort realistically

### Common Pitfalls to Avoid

❌ **Don't**: Create overlapping epics (e.g., "Task Sharing" when covered in Epic 04)
❌ **Don't**: Ignore domain model (epics must map to aggregates)
❌ **Don't**: Skip dependencies (creates implementation blockers)
❌ **Don't**: Underestimate effort (leads to missed deadlines)
❌ **Don't**: Forget cross-cutting concerns (security, performance)

✅ **Do**: Align with bounded contexts
✅ **Do**: Reference domain entities explicitly
✅ **Do**: Include both happy path and edge cases
✅ **Do**: Consider mobile/offline scenarios
✅ **Do**: Plan for scale from the start

## Epic Health Check

Run this validation after epic generation:

```bash
# Epic file count
epic_count=$(ls -1 06_epics/epic_*.md | wc -l)
echo "Epic files: $epic_count/15"

# Check for missing epic numbers
for i in {01..15}; do
  if [ ! -f "06_epics/epic_${i}_*.md" ]; then
    echo "❌ Missing: Epic ${i}"
  fi
done

# Verify all epics have minimum sections
for epic in 06_epics/epic_*.md; do
  if ! grep -q "Business Value" "$epic"; then
    echo "⚠️  Missing Business Value: $epic"
  fi
  if ! grep -q "Acceptance Criteria" "$epic"; then
    echo "⚠️  Missing Acceptance Criteria: $epic"
  fi
done
```

## Status Dashboard

**Last Updated**: {TIMESTAMP}
**Agent**: 06-Epic-Generation-Agent
**Overall Status**: {IN_PROGRESS / COMPLETE}

### Epic Completion Checklist
- [✅] Epic 01: Autenticación
- [✅] Epic 02: Tareas Core
- [✅] Epic 03: Proyectos
- [ ] Epic 04: Equipos ← MISSING
- [✅] Epic 05: Sincronización
- [ ] Epic 06: Notificaciones
- [ ] Epic 07: Búsqueda
- [ ] Epic 08: Analytics
- [ ] Epic 09: Integraciones
- [ ] Epic 10: Automatización
- [ ] Epic 11: Mobile
- [ ] Epic 12: Suscripciones
- [ ] Epic 13: Infraestructura
- [ ] Epic 14: Seguridad
- [ ] Epic 15: Onboarding

**Progress**: {X}/15 epics (Y%)

---

**This document is the master control file for epic management.**
**All epic files must align with this document.**
**Update this file whenever epic scope or dependencies change.**
```

## Implementation Notes

The 06-Epic-Generation-Agent should:
1. Create this claude.md file FIRST before generating any epic files
2. Update the {STATUS} fields as epics are created
3. Fill in {POINTS} and {COUNT} metrics as epics are completed
4. Maintain this as the single source of truth for epic status
