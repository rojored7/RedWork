# Template for claude.md in 07_user_stories/ Folder

This file MUST be created by the 07-User-Story-Generation-Agent in the 07_user_stories/ folder to serve as the central control document for ALL user stories across all epics.

## File: 07_user_stories/claude.md

```markdown
# User Stories Control Document - Task Manager Project

## Overview

This document serves as the **central source of truth** for all user stories across all epics in the Task Manager project. Every user story folder in this directory must align with its parent epic, domain model, architecture decisions, and service design.

## Project Context

**Product**: Task Manager Pro
**Epics Source**: `../06_epics/` (15 total epics)
**Domain Model**: `../02_domain_model.md`
**Architecture**: `../04_architecture_decision.md`
**Service Design**: `../05_service_design.md`

## User Story Generation Rules

### Mandatory for Each User Story

Every user story file MUST contain:

1. **Story Header**
   - Story ID (US-XXX)
   - Story Title
   - Epic reference
   - User role (As a...)

2. **User Story Statement**
   ```
   As a [user role]
   I want [feature/capability]
   So that [business value/benefit]
   ```

3. **Business Value**
   - Clear explanation of why this matters
   - Measurable success metrics
   - Impact on user experience

4. **Acceptance Criteria**
   - Minimum 5 functional criteria
   - Non-functional requirements (performance, security, usability)
   - Edge cases covered
   - Error handling defined

5. **BDD Scenarios** (Given/When/Then)
   - Happy path scenario
   - Alternative path scenario
   - Error/edge case scenario
   - Minimum 3 scenarios per story

6. **Technical Considerations**
   - Domain entities affected
   - Architecture patterns needed
   - API endpoints required
   - Database changes needed
   - Security requirements

7. **Dependencies**
   - Prerequisites (other stories)
   - Related stories
   - Blocking issues

8. **Estimation**
   - Story points (Fibonacci: 1,2,3,5,8,13)
   - Estimated hours
   - Team composition needed

## Epic Coverage Status

### Epic 01: Autenticación y Registro
**Folder**: `epic_01_autenticacion/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-001 to US-009

**Expected Stories**:
- ✅ US-001: Registro con email
- ✅ US-002: Verificación de email
- ✅ US-003: Login con credenciales
- ✅ US-004: Autenticación OAuth (Google, GitHub)
- [ ] US-005: Recuperación de contraseña
- [ ] US-006: Cambio de contraseña
- [ ] US-007: Autenticación de dos factores (2FA)
- [ ] US-008: Gestión de sesiones
- [ ] US-009: Cierre de sesión

### Epic 02: Gestión de Tareas Core
**Folder**: `epic_02_gestion_tareas/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-010 to US-019

**Expected Stories**:
- ✅ US-010: Crear tarea básica
- ✅ US-011: Editar tarea
- ✅ US-012: Cambiar estado de tarea
- [ ] US-013: Eliminar tarea
- [ ] US-014: Agregar subtareas
- [ ] US-015: Gestionar etiquetas
- [ ] US-016: Adjuntar archivos
- [ ] US-017: Agregar comentarios
- [ ] US-018: Asignar tarea a usuario
- [ ] US-019: Establecer fecha de vencimiento

### Epic 03: Proyectos y Organización
**Folder**: `epic_03_proyectos/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-020 to US-029

**Expected Stories**:
- ✅ US-020: Crear proyecto
- ✅ US-021: Asociar tareas a proyecto
- [ ] US-022: Editar proyecto
- [ ] US-023: Eliminar/Archivar proyecto
- [ ] US-024: Gestionar miembros del proyecto
- [ ] US-025: Configurar permisos de proyecto
- [ ] US-026: Crear plantillas de proyecto
- [ ] US-027: Duplicar proyecto
- [ ] US-028: Visualizar progreso del proyecto
- [ ] US-029: Exportar datos del proyecto

### Epic 04: Colaboración en Equipos
**Folder**: `epic_04_colaboracion/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-040 to US-049

**Expected Stories**:
- [ ] US-040: Crear equipo
- [ ] US-041: Invitar miembros al equipo
- [ ] US-042: Aceptar/Rechazar invitación
- [ ] US-043: Gestionar roles de equipo
- [ ] US-044: Remover miembros del equipo
- [ ] US-045: Asignar líder de equipo
- [ ] US-046: Compartir proyecto con equipo
- [ ] US-047: Ver actividad del equipo
- [ ] US-048: Configurar equipo
- [ ] US-049: Eliminar equipo

### Epic 05: Sincronización Multi-dispositivo
**Folder**: `epic_05_sincronizacion/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-050 to US-059

**Expected Stories**:
- ✅ US-030: Sincronización en tiempo real
- ✅ US-031: Modo offline
- [ ] US-052: Resolución de conflictos
- [ ] US-053: Gestión de dispositivos
- [ ] US-054: Sincronización selectiva
- [ ] US-055: Estado de sincronización
- [ ] US-056: Forzar sincronización manual

### Epic 06: Notificaciones y Recordatorios
**Folder**: `epic_06_notificaciones/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-060 to US-069

**Expected Stories**:
- [ ] US-060: Configurar preferencias de notificaciones
- [ ] US-061: Notificaciones de tareas vencidas
- [ ] US-062: Notificaciones de menciones
- [ ] US-063: Recordatorios programados
- [ ] US-064: Notificaciones push móviles
- [ ] US-065: Resumen diario por email
- [ ] US-066: Reporte semanal
- [ ] US-067: Notificaciones en tiempo real
- [ ] US-068: Marcar notificaciones como leídas
- [ ] US-069: Gestionar canales de notificación

### Epic 07: Búsqueda y Filtrado
**Folder**: `epic_07_busqueda/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-070 to US-079

**Expected Stories**:
- [ ] US-070: Búsqueda básica de tareas
- [ ] US-071: Búsqueda avanzada con filtros
- [ ] US-072: Búsqueda por etiquetas
- [ ] US-073: Búsqueda en comentarios
- [ ] US-074: Guardar búsquedas favoritas
- [ ] US-075: Filtros rápidos (Hoy, Esta semana, etc.)
- [ ] US-076: Ordenar resultados
- [ ] US-077: Búsqueda global (tareas + proyectos + comentarios)
- [ ] US-078: Sugerencias de búsqueda
- [ ] US-079: Búsqueda por fecha

### Epic 08: Analytics y Reportes
**Folder**: `epic_08_analytics/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-080 to US-089

**Expected Stories**:
- [ ] US-080: Dashboard de productividad personal
- [ ] US-081: Métricas de tareas completadas
- [ ] US-082: Reportes de equipo
- [ ] US-083: Análisis de tiempo de completación
- [ ] US-084: Gráficos de tendencias
- [ ] US-085: Exportar reportes
- [ ] US-086: Reportes personalizados
- [ ] US-087: Comparación de períodos
- [ ] US-088: Métricas de proyecto
- [ ] US-089: Insights y recomendaciones

### Epic 09: Integraciones Externas
**Folder**: `epic_09_integraciones/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-090 to US-099

**Expected Stories**:
- [ ] US-090: Integración con Google Calendar
- [ ] US-091: Integración con Slack
- [ ] US-092: Integración con GitHub
- [ ] US-093: Integración con email (IMAP)
- [ ] US-094: Webhooks entrantes
- [ ] US-095: Webhooks salientes
- [ ] US-096: API pública REST
- [ ] US-097: API GraphQL
- [ ] US-098: Gestionar integraciones
- [ ] US-099: Logs de integración

### Epic 10: Automatización y Reglas
**Folder**: `epic_10_automatizacion/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-100 to US-109

**Expected Stories**:
- [ ] US-100: Crear regla de automatización
- [ ] US-101: Triggers basados en eventos
- [ ] US-102: Acciones automáticas
- [ ] US-103: Reglas condicionales (if/then)
- [ ] US-104: Templates de automatización
- [ ] US-105: Activar/Desactivar reglas
- [ ] US-106: Historial de ejecuciones
- [ ] US-107: Debugging de reglas
- [ ] US-108: Límites de automatización por plan
- [ ] US-109: Notificaciones de reglas

### Epic 11: Aplicaciones Móviles
**Folder**: `epic_11_mobile/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-110 to US-119

**Expected Stories**:
- [ ] US-110: Vista móvil de tareas
- [ ] US-111: Creación rápida de tareas móvil
- [ ] US-112: Notificaciones push nativas
- [ ] US-113: Modo offline móvil
- [ ] US-114: Widget de inicio
- [ ] US-115: Escaneo de documentos (cámara)
- [ ] US-116: Grabación de notas de voz
- [ ] US-117: Sincronización automática
- [ ] US-118: Gestos táctiles
- [ ] US-119: Tema oscuro móvil

### Epic 12: Gestión de Suscripciones
**Folder**: `epic_12_suscripciones/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-120 to US-129

**Expected Stories**:
- [ ] US-120: Ver planes disponibles
- [ ] US-121: Actualizar a plan premium
- [ ] US-122: Downgrade de plan
- [ ] US-123: Gestionar método de pago
- [ ] US-124: Ver facturas y pagos
- [ ] US-125: Cancelar suscripción
- [ ] US-126: Período de prueba
- [ ] US-127: Límites por plan
- [ ] US-128: Notificaciones de facturación
- [ ] US-129: Cupones y descuentos

### Epic 13: Infraestructura y DevOps
**Folder**: `epic_13_devops/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-130 to US-139

**Expected Stories**:
- [ ] US-130: CI/CD pipeline
- [ ] US-131: Monitoreo de aplicación
- [ ] US-132: Logging centralizado
- [ ] US-133: Backup automatizado
- [ ] US-134: Disaster recovery
- [ ] US-135: Health checks
- [ ] US-136: Auto-scaling
- [ ] US-137: CDN para assets
- [ ] US-138: Database migrations
- [ ] US-139: Feature flags

### Epic 14: Seguridad y Compliance
**Folder**: `epic_14_seguridad/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-140 to US-149

**Expected Stories**:
- [ ] US-140: Audit logs completos
- [ ] US-141: Encriptación de datos
- [ ] US-142: GDPR compliance (derecho al olvido)
- [ ] US-143: Exportar datos personales
- [ ] US-144: Gestión de permisos granulares
- [ ] US-145: Security headers
- [ ] US-146: Rate limiting
- [ ] US-147: Detección de actividad sospechosa
- [ ] US-148: Cumplimiento SOC 2
- [ ] US-149: Políticas de retención de datos

### Epic 15: Onboarding y Educación
**Folder**: `epic_15_onboarding/`
**Status**: {STATUS}
**Stories Created**: {COUNT}
**Story IDs**: US-150 to US-159

**Expected Stories**:
- [ ] US-150: Tour interactivo inicial
- [ ] US-151: Tutoriales paso a paso
- [ ] US-152: Centro de ayuda
- [ ] US-153: Búsqueda en documentación
- [ ] US-154: Videos tutoriales
- [ ] US-155: Tips contextuales
- [ ] US-156: Datos de ejemplo
- [ ] US-157: Plantillas predefinidas
- [ ] US-158: Onboarding de equipos
- [ ] US-159: Progreso de onboarding

## Domain Model Alignment

### Stories per Domain Entity

| Entity | Primary Stories | Supporting Stories |
|--------|----------------|-------------------|
| User | US-001 to US-009, US-120 to US-129 | All stories |
| Task | US-010 to US-019 | US-020-029, US-070-079 |
| Project | US-020 to US-029 | US-010-019, US-040-049 |
| Team | US-040 to US-049 | US-020-029, US-080-089 |
| Comment | US-017 | US-010-019 |
| Notification | US-060 to US-069 | All stories |
| Integration | US-090 to US-099 | US-010-019 |
| AutomationRule | US-100 to US-109 | US-010-019 |
| Subscription | US-120 to US-129 | US-001-009 |

### Business Rules Coverage

| Rule ID | Covered By Stories |
|---------|-------------------|
| R1-R6 (Task Creation) | US-010, US-014, US-120-129 |
| R7-R10 (Prioritization) | US-010, US-100-109 |
| R11-R15 (Collaboration) | US-040-049 |
| R16-R19 (Synchronization) | US-050-059 |
| R20-R23 (Automation) | US-100-109 |
| R24-R27 (Notification) | US-060-069 |
| R28-R31 (Storage) | US-016, US-120-129 |

## Architecture Patterns per Story Type

### CRUD Stories (Create, Read, Update, Delete)
**Examples**: US-010, US-020, US-040
**Patterns**:
- Clean Architecture (Domain → Application → Infrastructure)
- Repository pattern
- CQRS (separate read/write models)
- Domain events

### Real-time Stories
**Examples**: US-030, US-067
**Patterns**:
- WebSocket communication
- Event-driven architecture
- Optimistic UI updates
- Conflict resolution

### Integration Stories
**Examples**: US-090-099
**Patterns**:
- Adapter pattern
- OAuth 2.0 flow
- Webhook handlers
- API versioning

### Automation Stories
**Examples**: US-100-109
**Patterns**:
- Rule engine
- Event sourcing
- Saga pattern
- Idempotency

## Quality Standards

### Story Completeness Checklist

Each user story MUST have:
- [ ] Clear user role and value proposition
- [ ] Minimum 5 acceptance criteria
- [ ] Minimum 3 BDD scenarios (happy + alternative + error)
- [ ] Domain model references (entities, VOs, aggregates)
- [ ] Architecture alignment (bounded context, patterns)
- [ ] Technical considerations (API, DB, security)
- [ ] Dependencies identified
- [ ] Story points estimated (1,2,3,5,8,13)
- [ ] Definition of Done

### BDD Scenario Quality

Each scenario must follow:
```gherkin
Scenario: [Clear descriptive name]
  Given [precondition with specific data]
  And [additional context]
  When [user action with specific parameters]
  And [additional actions]
  Then [expected result with specific values]
  And [additional expected results]
```

**Anti-patterns to avoid**:
❌ Vague preconditions: "Given a user exists"
✅ Specific data: "Given a user 'john@example.com' with FREE plan exists"

❌ Unclear actions: "When the user creates a task"
✅ Specific action: "When the user creates a task with title 'Buy milk' and due date tomorrow"

❌ Weak assertions: "Then the task is created"
✅ Strong assertion: "Then the task appears in the user's task list with status PENDING"

## Cross-Story Validations

### Avoiding Duplication

Before creating a story, check:
- [ ] Is this functionality already in another story?
- [ ] Can this be merged with an existing story?
- [ ] Is the scope too large (should it be split)?

### Ensuring Coverage

After all stories created:
- [ ] All epic objectives covered
- [ ] All domain entities have CRUD stories
- [ ] All user journeys complete
- [ ] Edge cases addressed
- [ ] Error scenarios covered
- [ ] Security requirements included
- [ ] Performance criteria defined

## Story Dependencies Matrix

| Story | Depends On | Enables |
|-------|-----------|---------|
| US-002 | US-001 | US-003 |
| US-003 | US-001, US-002 | All stories |
| US-010 | US-001, US-003 | US-011-019 |
| US-020 | US-001, US-010 | US-021-029 |
| US-030 | US-010 | US-031, US-111 |
| US-040 | US-001, US-020 | US-041-049 |
| ... | ... | ... |

## Story Point Distribution

### Target Distribution (Healthy)
- **1 point** (trivial): 10% of stories
- **2 points** (simple): 20% of stories
- **3 points** (moderate): 30% of stories
- **5 points** (complex): 25% of stories
- **8 points** (very complex): 10% of stories
- **13 points** (epic-level): 5% of stories

### Current Distribution
- **1 point**: {COUNT} ({PERCENTAGE}%)
- **2 points**: {COUNT} ({PERCENTAGE}%)
- **3 points**: {COUNT} ({PERCENTAGE}%)
- **5 points**: {COUNT} ({PERCENTAGE}%)
- **8 points**: {COUNT} ({PERCENTAGE}%)
- **13 points**: {COUNT} ({PERCENTAGE}%)

## Implementation Sequencing

### Phase 1: MVP (Critical Path)
**Must Complete First**:
1. US-001, US-002, US-003 (Authentication)
2. US-010, US-011, US-012 (Basic Tasks)
3. US-020, US-021 (Projects)
4. US-030, US-031 (Sync basics)

**Why**: Foundation for all other features

### Phase 2: Collaboration
**Build Next**:
1. US-040-045 (Teams)
2. US-060-063 (Notifications)
3. US-017 (Comments)

**Why**: Enables team features

### Phase 3: Power Features
**Then Add**:
1. US-070-074 (Search)
2. US-100-103 (Automation)
3. US-013-019 (Advanced tasks)

**Why**: Differentiation features

### Phase 4: Growth
**Finally**:
1. US-110-119 (Mobile)
2. US-080-089 (Analytics)
3. US-120-129 (Subscriptions)

**Why**: Scale and monetization

## Metrics and Progress

### Overall Progress

- **Total Stories Planned**: ~60-80 stories
- **Stories Created**: {COUNT}
- **Completion**: {PERCENTAGE}%

### By Epic

| Epic | Planned | Created | Complete % |
|------|---------|---------|------------|
| Epic 01 | 9 | {COUNT} | {PCT}% |
| Epic 02 | 10 | {COUNT} | {PCT}% |
| Epic 03 | 10 | {COUNT} | {PCT}% |
| Epic 04 | 10 | {COUNT} | {PCT}% |
| Epic 05 | 7 | {COUNT} | {PCT}% |
| Epic 06 | 10 | {COUNT} | {PCT}% |
| Epic 07 | 10 | {COUNT} | {PCT}% |
| Epic 08 | 10 | {COUNT} | {PCT}% |
| Epic 09 | 10 | {COUNT} | {PCT}% |
| Epic 10 | 10 | {COUNT} | {PCT}% |
| Epic 11 | 10 | {COUNT} | {PCT}% |
| Epic 12 | 10 | {COUNT} | {PCT}% |
| Epic 13 | 10 | {COUNT} | {PCT}% |
| Epic 14 | 10 | {COUNT} | {PCT}% |
| Epic 15 | 10 | {COUNT} | {PCT}% |

### Effort Estimation

- **Total Story Points**: {SUM}
- **Estimated Development Hours**: {STORY_POINTS × 1.5}
- **Sprints Needed** (2-week sprints, velocity 20): {SPRINTS}
- **Team Weeks**: {WEEKS}

## Instructions for Agent 07

### Processing Sequence

1. **READ** this claude.md file completely
2. **READ** epic file from 06_epics/epic_XX_*.md
3. **IDENTIFY** 2-5 key user stories for that epic
4. **CREATE** epic folder: 07_user_stories/epic_XX_name/
5. **WRITE** each user story file: US-XXX_story_name.md
6. **UPDATE** this claude.md with story count and metrics
7. **VALIDATE** all quality standards met
8. **REPEAT** for next epic

### Common Pitfalls to Avoid

❌ **Don't**: Create stories that are too large (>8 points → split it)
❌ **Don't**: Forget edge cases (always include error scenarios)
❌ **Don't**: Skip technical considerations
❌ **Don't**: Use generic BDD scenarios
❌ **Don't**: Ignore dependencies between stories
❌ **Don't**: Forget to reference domain model

✅ **Do**: Keep stories focused (one clear goal)
✅ **Do**: Include specific acceptance criteria
✅ **Do**: Write realistic BDD scenarios with data
✅ **Do**: Reference domain entities explicitly
✅ **Do**: Identify API endpoints needed
✅ **Do**: Estimate story points honestly

## Validation Commands

### Check Story Count per Epic
```bash
for epic_dir in 07_user_stories/epic_*/; do
  epic_name=$(basename "$epic_dir")
  story_count=$(find "$epic_dir" -name "US-*.md" | wc -l)
  echo "$epic_name: $story_count stories"
done
```

### Verify Story ID Ranges
```bash
# Epic 01 should have US-001 to US-009
ls 07_user_stories/epic_01_*/US-*.md | grep -v "US-00[1-9]" && echo "❌ Invalid ID"

# Epic 02 should have US-010 to US-019
ls 07_user_stories/epic_02_*/US-*.md | grep -v "US-01[0-9]" && echo "❌ Invalid ID"
```

### Check Story Completeness
```bash
for story in 07_user_stories/epic_*/US-*.md; do
  if ! grep -q "Acceptance Criteria" "$story"; then
    echo "⚠️  Missing Acceptance Criteria: $story"
  fi
  if ! grep -q "Scenario:" "$story"; then
    echo "⚠️  Missing BDD Scenarios: $story"
  fi
  if ! grep -q "Story Points" "$story"; then
    echo "⚠️  Missing Story Points: $story"
  fi
done
```

## Status Dashboard

**Last Updated**: {TIMESTAMP}
**Agent**: 07-User-Story-Generation-Agent
**Overall Status**: {IN_PROGRESS / COMPLETE}

### Epic Processing Checklist
- [✅] Epic 01: Autenticación (4 stories)
- [✅] Epic 02: Tareas (3 stories)
- [✅] Epic 03: Proyectos (2 stories)
- [ ] Epic 04: Equipos (0 stories) ← MISSING
- [✅] Epic 05: Sincronización (2 stories)
- [ ] Epic 06: Notificaciones (0 stories)
- [ ] Epic 07: Búsqueda (0 stories)
- [ ] Epic 08: Analytics (0 stories)
- [ ] Epic 09: Integraciones (0 stories)
- [ ] Epic 10: Automatización (0 stories)
- [ ] Epic 11: Mobile (0 stories)
- [ ] Epic 12: Suscripciones (0 stories)
- [ ] Epic 13: DevOps (0 stories)
- [ ] Epic 14: Seguridad (0 stories)
- [ ] Epic 15: Onboarding (0 stories)

**Progress**: 11/15 epics (73%)
**Stories**: 11/{TARGET} ({PCT}%)

---

**This document is the master control file for user story management.**
**All user story folders and files must align with this document.**
**Update this file after processing each epic.**
```

## Usage Notes for Agent

The agent should:
1. Create this claude.md BEFORE generating any user stories
2. Update metrics after each epic is processed
3. Use this as validation checklist before marking epic complete
4. Reference this for story ID ranges and conventions
