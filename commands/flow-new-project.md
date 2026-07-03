---
description: Flujo completo DDD para proyecto nuevo - desde descubrimiento hasta deployment
---

# Flujo: Proyecto Nuevo (DDD Completo)

Pipeline completo de agentes para construir un proyecto desde cero siguiendo Domain-Driven Design.

## Uso

```
/flow-new-project [descripcion breve del producto o idea]
```

## Fases (ejecutar en orden estricto)

### Fase 0: Pre-validacion de Impacto (SIEMPRE PRIMERO — gate duro)

0. **impact-prevalidator** - Mapear el terreno ANTES del pipeline
   - En greenfield: inventaria convenciones instaladas (rules/, stacks/),
     estado del repo destino y baseline; scope `full-project`
   - Salida: `outputs/00b_impact_analysis.md` con veredicto VERDE/AMARILLO/ROJO
   - Gate: `bash scripts/workflow/validate-impact-analysis.sh --allow-amber`
     debe salir 0 antes de la Fase 1 (Agent 25 lo re-verifica en su check 0.6)

### Fase 1: Descubrimiento y Modelado de Dominio

Ejecutar secuencialmente, cada agente depende del anterior:

1. **01-product-discovery** - Transformar la idea en documento estructurado
   - Entrada: vision del producto proporcionada por el usuario
   - Salida: `01_product_discovery.md`
   - NO pausar aqui: las preguntas abiertas se acumulan para el gate unico

2. **02-domain-modeling** - Construir modelo de dominio
   - Entrada: `01_product_discovery.md`
   - Salida: `02_domain_model.md`
   - Define entidades, value objects, aggregates, reglas de negocio, domain events

3. **03-context-mapping** - Dividir en bounded contexts
   - Entrada: `02_domain_model.md`
   - Salida: `03_context_map.md`
   - Mapea relaciones estrategicas entre contextos

### Fase 2: Decisiones de Arquitectura y Diseno

4. **04-architecture-decision** - Decidir arquitectura
   - Entrada: `01_product_discovery.md`, `02_domain_model.md`, `03_context_map.md`
   - Salida: `04_architecture_decision.md`
   - Decide monolito modular vs microservicios, patrones de comunicacion
   - NO pausar aqui: la decision se presenta en el paquete del gate unico

5. **05-service-design** - Disenar estructura interna de servicios
   - Entrada: `02_domain_model.md`, `03_context_map.md`, `04_architecture_decision.md`
   - Salida: `05_service_design.md`
   - Clean Architecture + Hexagonal, capas, puertos, adaptadores

### Fase 3: Planificacion de Trabajo

6. **06-epic-generation** - Generar epicas
   - Entrada: `02_domain_model.md`, `04_architecture_decision.md`
   - Salida: `06_epics/`

7. **07-user-story-generation** - Descomponer epicas en historias
   - Entrada: `06_epics/`
   - Salida: `07_user_stories/`
   - Incluye criterios de aceptacion y escenarios BDD

8. **08-tech-lead-delivery** - Desglose tecnico de implementacion
   - Entrada: `07_user_stories/`
   - Salida: `08_implementation_breakdown/`
   - Tareas por backend, frontend, DB, DevOps, seguridad, QA

9. **09-sprint-orchestrator** - Organizar en sprints ejecutables
   - Entrada: `07_user_stories/`, `08_implementation_breakdown/`
   - Salida: `09_sprint_plan/`

### Fase 4: Implementacion (por sprint, en paralelo)

Por cada sprint, en orden de waves TDD (tests SIEMPRE antes que implementacion):

10. **Wave 0 — 12-infrastructure-deployment** - Levantar infra Docker/WSL
    - Entrada: `04_architecture_decision.md`, `05_service_design.md`
    - Salida: Docker containers, `runtime-infrastructure.json`
    - Gate: `bash scripts/workflow/run-gates.sh 0`

11. **Wave 3a — 13-backend-test** (TDD Red) - Tests de backend PRIMERO
    - Todos deben FALLAR antes de implementar

12. **Wave 3b — 14-backend-development** (TDD Green) - Implementar backend
    - Por cada slice/tarea:
      `bash scripts/workflow/slice-gate.sh backend` (cobertura 100%) →
      `bash scripts/workflow/checkpoint-commit.sh "<desc>" <task-id>`
    - Al cerrar la wave: `bash scripts/workflow/run-gates.sh 3`

13. **Wave 5a — 15-frontend-test** (TDD Red) + **Wave 5b — 16-frontend-development** (TDD Green)
    - Mismo patron: tests primero, slice-gate + checkpoint por slice,
      y al cerrar: `bash scripts/workflow/run-gates.sh 5`

### Fase 5: Validacion

Secuencial tras las waves:

14. **17-integration-test** - Tests de integracion real
15. **18-e2e-test** - Tests end-to-end de flujos criticos
16. **19-smoke-test** - Validacion de flujos minimos viables
17. **20-linting-validator** - Zero errores, zero warnings

### Fase 6: Seguridad y Cierre

19. **21-security-review** - Auditoria de seguridad completa
20. **20-linting-validator** - Validacion final de linting

## Gates: UN solo gate humano, el resto automaticos

**GATE HUMANO UNICO — tras Fase 3 (paquete de decisiones completo):**
El usuario recibe EN UN SOLO MENSAJE el paquete de decisiones de producto:
- Veredicto de impacto (Fase 0: `00b_impact_analysis.md`)
- Dominio (Fase 1: `02_domain_model.md` — entidades y reglas clave resumidas)
- Arquitectura (Fase 2: `04_architecture_decision.md` — decision y trade-offs)
- Sprint plan (Fase 3: `09_sprint_plan/`)
- Critica de **plan-critic** sobre el sprint plan (dependencias, orden, supuestos)
- Las preguntas abiertas acumuladas en Fases 1-3 (si las hay)

Una sola aprobacion autoriza TODO. Si el usuario quiere cambiar dominio o
arquitectura, se regeneran los artefactos afectados y se re-presenta el paquete
(max 2 iteraciones antes de escalar con opciones concretas).

**Tras aprobar el paquete: cada sprint (Fases 4-6) corre DE PUNTA A PUNTA sin
confirmaciones intermedias** (Doctrina de Ejecucion de CLAUDE.md global): infra +
backend + frontend + validacion + seguridad de corrido, con los gates automaticos
(tests verdes, linting, smoke, run-gates.sh con reintentos acotados por
FRAMEWORK_MAX_RETRIES) como unica condicion de avance. Al final de CADA sprint:
reporte consolidado y se continua con el siguiente sprint del plan aprobado;
escalar al usuario solo ante gate agotado (needs_human.flag), fallo no resoluble
o cambio de alcance.

## Artefactos Generados

```
proyecto/
  01_product_discovery.md
  02_domain_model.md
  03_context_map.md
  04_architecture_decision.md
  05_service_design.md
  06_epics/
  07_user_stories/
  08_implementation_breakdown/
  09_sprint_plan/
  src/
  tests/
  docker-compose.yml
  runtime-infrastructure.json
```

## Comandos Relacionados

- `/flow-update` - Para agregar features a proyecto existente
- `/flow-bugfix` - Para corregir bugs
- `/plan` - Para planificacion rapida sin DDD completo
