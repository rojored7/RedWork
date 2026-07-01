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

### Fase 1: Descubrimiento y Modelado de Dominio

Ejecutar secuencialmente, cada agente depende del anterior:

1. **01-product-discovery** - Transformar la idea en documento estructurado
   - Entrada: vision del producto proporcionada por el usuario
   - Salida: `01_product_discovery.md`
   - Preguntar al usuario para validar antes de continuar

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
   - ESPERAR confirmacion del usuario

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

Lanzar en PARALELO por cada sprint:

10. **12-infrastructure-deployment** - Levantar infra Docker/WSL
    - Entrada: `04_architecture_decision.md`, `05_service_design.md`
    - Salida: Docker containers, `runtime-infrastructure.json`

11. **14-backend-development** - Implementar backend
    - Entrada: `05_service_design.md`, `09_sprint_plan/`
    - Salida: codigo backend FastAPI

12. **16-frontend-development** - Implementar frontend
    - Entrada: `05_service_design.md`, `09_sprint_plan/`
    - Salida: codigo frontend

### Fase 5: Validacion (en paralelo)

Lanzar en PARALELO:

13. **13-backend-test** - Tests de backend
14. **15-frontend-test** - Tests de frontend
15. **20-linting-validator** - Zero errores, zero warnings

Luego secuencial:

16. **17-integration-test** - Tests de integracion real
17. **18-e2e-test** - Tests end-to-end de flujos criticos
18. **19-smoke-test** - Validacion de flujos minimos viables

### Fase 6: Seguridad y Cierre

19. **21-security-review** - Auditoria de seguridad completa
20. **20-linting-validator** - Validacion final de linting

## Gates: decisiones de producto si, pausas de ejecucion no

**GATES HUMANOS (decisiones de diseno — el dueño del producto decide):**
- Despues de Fase 1 (dominio validado)
- Despues de Fase 2 (arquitectura aprobada)
- Despues de Fase 3 (sprint plan aprobado)

**Tras aprobar el sprint plan: cada sprint (Fases 4-6) corre DE PUNTA A PUNTA sin
confirmaciones intermedias** (Doctrina de Ejecucion de CLAUDE.md global): infra +
backend + frontend + validacion + seguridad de corrido, con los gates automaticos
(tests verdes, linting, smoke) como unica condicion de avance. Al final de CADA
sprint: reporte consolidado y se continua con el siguiente sprint del plan aprobado;
escalar al usuario solo ante fallo no resoluble o cambio de alcance.

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
