# Agente 09-Sprint-Orchestrator - Configuración

## ✅ Configuración Completa

### Archivos de Configuración

1. **`.claude/agent-config.md`** (Sección: 09-Sprint-Orchestrator-Agent Rules)
   - Define estructura obligatoria
   - Reglas de asignación de épicas a sprints
   - Formato de todos los archivos

2. **`.claude/SPRINT_PLAN_CLAUDE_TEMPLATE.md`**
   - Template para generar el CLAUDE.md de cada sprint
   - Instrucciones para development agents

## 📁 Estructura de Salida Correcta

```
09_sprint_plan/
├── sprint_01/
│   ├── sprint_goal.md                 ← Épicas y objetivos del sprint
│   ├── sprint_overview.md             ← Resumen: épicas, user stories, story points
│   ├── backend_execution_plan.md      ← SOLO tareas backend de épicas en este sprint
│   ├── frontend_execution_plan.md     ← SOLO tareas frontend de épicas en este sprint
│   ├── infrastructure_execution_plan.md ← SOLO tareas infra de épicas en este sprint
│   ├── dependency_map.md              ← Dependencias de este sprint
│   ├── execution_waves.md             ← Waves dentro de este sprint
│   ├── excluded_items.md              ← Items excluidos de este sprint
│   └── CLAUDE.md                      ← Instrucciones para dev agents
├── sprint_02/
│   └── [mismos 9 archivos]
├── sprint_03/
│   └── [mismos 9 archivos]
├── sprint_NN/
│   └── [mismos 9 archivos]
└── README.md                          ← Índice maestro de todos los sprints
```

## 🎯 Reglas Críticas

### 1. Épicas Completas al 100%

❌ **INCORRECTO:**
```
Sprint 1:
  - Epic 01: Stories 1, 2, 3 (60% de la épica)

Sprint 2:
  - Epic 01: Stories 4, 5 (resto de la épica)
  - Epic 02: Stories 1, 2 (50% de la épica)
```

✅ **CORRECTO:**
```
Sprint 1:
  - Epic 01: TODAS las stories (100% de la épica)

Sprint 2:
  - Epic 02: TODAS las stories (100% de la épica)
```

### 2. Tareas Extraídas de 08_implementation_breakdown

Cada archivo de ejecución debe contener:

**backend_execution_plan.md:**
```markdown
# Backend Execution Plan - Sprint 1

## Epic 01: Autenticación

### US-001: Registro con Email
**From**: 08_implementation_breakdown/epic_01/story_001/01_backend_tasks.md

#### Tasks
- [ ] BE-001-001: Crear entidad User (3h)
- [ ] BE-001-002: Implementar UserRepository (2h)
- [ ] BE-001-003: Crear endpoint POST /auth/register (4h)
[... TODAS las tareas del archivo 01_backend_tasks.md]

### US-002: Verificación Email
**From**: 08_implementation_breakdown/epic_01/story_002/01_backend_tasks.md

#### Tasks
- [ ] BE-002-001: Crear EmailVerificationToken entity (2h)
- [ ] BE-002-002: Implementar servicio de envío de email (4h)
[... TODAS las tareas del archivo 01_backend_tasks.md]

[Y así para TODAS las user stories del Epic 01]
```

**frontend_execution_plan.md:**
```markdown
# Frontend Execution Plan - Sprint 1

## Epic 01: Autenticación

### US-001: Registro con Email
**From**: 08_implementation_breakdown/epic_01/story_001/02_frontend_tasks.md

#### Tasks
- [ ] FE-001-001: Crear componente RegistrationForm (4h)
- [ ] FE-001-002: Validación de formulario (2h)
[... TODAS las tareas del archivo 02_frontend_tasks.md]

### US-002: Verificación Email
**From**: 08_implementation_breakdown/epic_01/story_002/02_frontend_tasks.md

#### Tasks
- [ ] FE-002-001: Crear página de verificación (3h)
[... TODAS las tareas del archivo 02_frontend_tasks.md]

[Y así para TODAS las user stories del Epic 01]
```

### 3. Cada Sprint es Autocontenido

Cada carpeta `sprint_XX/` contiene **TODO** lo necesario para ejecutar ese sprint:
- Objetivos (sprint_goal.md)
- Tareas backend (backend_execution_plan.md)
- Tareas frontend (frontend_execution_plan.md)
- Tareas infra (infrastructure_execution_plan.md)
- Dependencias (dependency_map.md)
- Plan de ejecución temporal (execution_waves.md)
- Instrucciones para agentes (CLAUDE.md)

## 🚀 Cómo Usar

### Para Invocar el Agente

```bash
# El agente automáticamente lee .claude/agent-config.md
# y crea la estructura correcta

"Usa el agente 09-Sprint-Orchestrator-Agent"
"Genera el sprint plan completo"
```

### El Agente Hará:

1. **Analizar todas las épicas** en 06_epics/
2. **Leer todas las user stories** en 07_user_stories/
3. **Calcular story points** por épica
4. **Decidir número de sprints** necesarios
5. **Asignar épicas completas** a cada sprint
6. **Para cada sprint:**
   - Crear carpeta `sprint_XX/`
   - Generar 9 archivos requeridos
   - Extraer tareas de `08_implementation_breakdown/`
   - Agrupar por épica → user story → tareas

### Ejemplo de Salida

```
✅ Sprint 1 created
   Epics: Epic 01 - Autenticación (100% complete)
   User Stories: 5 stories (US-001 to US-005)
   Story Points: 25 points
   Files: 9/9 created
   Location: 09_sprint_plan/sprint_01/

✅ Sprint 2 created
   Epics: Epic 02 - Gestión Tareas (100% complete)
   User Stories: 6 stories (US-010 to US-015)
   Story Points: 32 points
   Files: 9/9 created
   Location: 09_sprint_plan/sprint_02/

... [continúa para todos los sprints necesarios]

✅ Sprint plan generation complete
   Total Sprints: 10
   Total Epics: 15 (all assigned)
   Total User Stories: 80
   Total Story Points: 350
```

## ✅ Checklist de Validación

Después de que el agente genere el plan, verifica:

### Estructura de Archivos
- [ ] Existe carpeta `09_sprint_plan/`
- [ ] Existen carpetas `sprint_01/`, `sprint_02/`, ..., `sprint_NN/`
- [ ] Cada carpeta tiene exactamente 9 archivos
- [ ] Existe `README.md` en la raíz de `09_sprint_plan/`

### Contenido de Cada Sprint
- [ ] `sprint_goal.md` lista las épicas asignadas (100% completas)
- [ ] `sprint_overview.md` lista todas las user stories
- [ ] `backend_execution_plan.md` tiene TODAS las tareas backend de las épicas
- [ ] `frontend_execution_plan.md` tiene TODAS las tareas frontend de las épicas
- [ ] `infrastructure_execution_plan.md` tiene TODAS las tareas infra de las épicas
- [ ] Las tareas están agrupadas por: Épica → User Story → Tasks
- [ ] Todas las tareas tienen checkbox [ ]
- [ ] Todas las tareas tienen estimación en horas (Xh)

### Completitud
- [ ] Todas las épicas están asignadas a un sprint
- [ ] Ninguna épica está dividida entre múltiples sprints
- [ ] Todas las user stories están incluidas
- [ ] No hay duplicados de tareas

## 🚫 Errores Comunes a Evitar

### Error 1: Épicas Parciales
```
❌ Sprint 1: Epic 01 (50%), Epic 02 (50%)
✅ Sprint 1: Epic 01 (100%)
   Sprint 2: Epic 02 (100%)
```

### Error 2: Archivos Globales en Lugar de Por Sprint
```
❌ 09_sprint_plan/
   ├── backend_execution_plan.md (global)
   └── frontend_execution_plan.md (global)

✅ 09_sprint_plan/
   ├── sprint_01/
   │   ├── backend_execution_plan.md (solo Sprint 1)
   │   └── frontend_execution_plan.md (solo Sprint 1)
   └── sprint_02/
       ├── backend_execution_plan.md (solo Sprint 2)
       └── frontend_execution_plan.md (solo Sprint 2)
```

### Error 3: Tareas No Extraídas de 08_implementation_breakdown
```
❌ Tareas genéricas inventadas
✅ Tareas copiadas exactamente de:
   08_implementation_breakdown/epic_XX/story_XXX/01_backend_tasks.md
   08_implementation_breakdown/epic_XX/story_XXX/02_frontend_tasks.md
   etc.
```

## 📖 Archivos de Referencia

- **Configuración del agente**: `.claude/agent-config.md` (línea 70+)
- **Template de CLAUDE.md**: `.claude/SPRINT_PLAN_CLAUDE_TEMPLATE.md`
- **Este README**: `.claude/README_SPRINT_ORCHESTRATOR.md`

---

**Versión**: 2.0
**Última Actualización**: 2024-03-20
**Configuración**: Corregida y validada
