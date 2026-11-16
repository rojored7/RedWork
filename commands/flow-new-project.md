---
description: Pipeline DDD completo para construir un proyecto DESDE CERO (descubrimiento de producto, modelo de dominio, bounded contexts, arquitectura, diseno de servicios, epicas, historias, sprints, implementacion TDD por waves, validacion y seguridad). Usar cuando el usuario tiene una idea o producto nuevo sin codigo existente, o un repo vacio. NO usar sobre un proyecto que ya tiene codigo (flow-update o flow-bugfix) ni cuando solo se quiere un plan rapido sin DDD (plan).
---

# Flujo: Proyecto Nuevo (DDD Completo)

Pipeline completo de agentes para construir un proyecto desde cero siguiendo Domain-Driven Design.

## Uso

```
/flow-new-project [descripcion breve del producto o idea]
```

## Resolucion de scripts de gate (leer antes de Fase 0)

El flujo usa cuatro scripts que viven en cada proyecto, no en la configuracion global.
En un proyecto nuevo lo normal es que al inicio no exista ninguno. Cada script se
resuelve por separado y desde la raiz del repo:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Para cada script X en: validate-impact-analysis.sh, slice-gate.sh,
#                        checkpoint-commit.sh, run-gates.sh
#   1. $ROOT/scripts/workflow/X
#   2. $ROOT/plataforma/scripts/workflow/X
#   3. $HOME/.claude/redwork/scripts/workflow/validate-impact-analysis.sh  (solo ese script: es generico,
#      lee outputs/00b y HEAD. slice-gate, checkpoint y run-gates asumen la plantilla
#      del proyecto (paquete app, cobertura 100) y nunca se toman de la instalacion global)
#   4. ausente
```

Si un script esta ausente, el gate no desaparece: el agente verifica la misma condicion
a mano y lo declara en el reporte ("gate X verificado manualmente, script ausente").

| Script ausente | Que hace el agente en su lugar |
|---|---|
| validate-impact-analysis.sh | Verifica que `outputs/00b_impact_analysis.md` exista, este anclado al HEAD actual (o declare greenfield sin repo) y tenga veredicto. ROJO sigue bloqueando |
| slice-gate.sh | Corre lint, type-check y tests del proyecto a mano y reporta |
| checkpoint-commit.sh | Commit manual del slice con git, sin push |
| run-gates.sh | Al cerrar una wave: corre la suite completa de tests de esa wave y verifica que todos pasen y que la cobertura cumpla el umbral del proyecto |

Nunca inventes que un gate paso.

## Fases (ejecutar en orden estricto)

### Fase 0: Pre-validacion de Impacto (arranca primero, gate duro)

0. **impact-prevalidator** - Mapear el terreno antes del pipeline
   - En greenfield: inventaria convenciones instaladas (rules/, stacks/),
     estado del repo destino y baseline; scope `full-project`
   - Salida: `outputs/00b_impact_analysis.md` con veredicto VERDE/AMARILLO/ROJO
   - Gate: `bash "$VALIDATE_IMPACT" --allow-amber` (ruta resuelta arriba) debe salir 0
     antes de la Fase 1

### Fase 1: Descubrimiento y Modelado de Dominio

Ejecutar secuencialmente, cada agente depende del anterior:

1. **01-product-discovery** - Transformar la idea en documento estructurado
   - Entrada: vision del producto proporcionada por el usuario
   - Salida: `01_product_discovery.md`
   - No pausar aqui: las preguntas abiertas se acumulan para el gate unico

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
   - No pausar aqui: la decision se presenta en el paquete del gate unico

4b. **04b-security-by-design** - Requisitos de seguridad desde el diseno
   - Entrada: `04_architecture_decision.md`
   - Corre inmediatamente despues de 04 y antes de 05: autenticacion, autorizacion,
     datos sensibles, secretos y amenazas se deciden antes de disenar servicios
   - Sus requisitos son entrada obligatoria de 05 y de 05b

5. **05-service-design** - Disenar estructura interna de servicios
   - Entrada: `02_domain_model.md`, `03_context_map.md`, `04_architecture_decision.md`
   - Salida: `05_service_design.md`
   - Clean Architecture + Hexagonal, capas, puertos, adaptadores

5b. **05b-technical-design-validator** - Gate bloqueante del diseno
   - Entrada: `05_service_design.md` + requisitos de 04b
   - Valida que el diseno cumple seguridad, calidad y restricciones de arquitectura
   - Si falla, se corrige 05 y se re-valida antes de planificar (max 2 iteraciones)

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

### Fase 3.5: Contrato de API (antes del gate humano)

10. **10-api-specification** - Especificacion OpenAPI unica
    - Entrada: `07_user_stories/`, `08_implementation_breakdown/`, `09_sprint_plan/`
    - Backend y frontend comparten este contrato como fuente unica de verdad

11. **11-implementation-contract** - Contrato de implementacion
    - Entrada: `09_sprint_plan/` + la especificacion de 10
    - Define exactamente que implementar y que gates de calidad deben pasar

El usuario aprueba el contrato de API junto con el resto del paquete de decisiones.

### Fase 4: Implementacion (por sprint, en paralelo)

Este flujo orquesta las waves directamente. **25-development-orchestrator** es la entrada
alternativa cuando los agentes se ejecutan a mano, uno por uno: no se invocan los dos a la vez.

Por cada sprint, en orden de waves TDD. Los tests van siempre antes que la
implementacion: un test escrito despues del codigo tiende a describir lo que el codigo
hace, no lo que deberia hacer.

12. **Wave 0 - 12-infrastructure-deployment** - Levantar infra Docker/WSL
    - Entrada: `04_architecture_decision.md`, `05_service_design.md`
    - Salida: Docker containers, `runtime-infrastructure.json`
    - Verificar puertos libres antes de levantar servicios; nunca bajar los que ya
      estaban corriendo
    - Gate: `bash "$RUN_GATES" 0` (o verificacion manual si el script esta ausente)

13. **Wave 3a - 13-backend-test** (TDD Red) - Tests de backend PRIMERO
    - Todos deben fallar antes de implementar

14. **Wave 3b - 14-backend-development** (TDD Green) - Implementar backend
    - Por cada slice/tarea:
      `bash "$SLICE_GATE" backend` (umbral de cobertura del proyecto) y despues
      `bash "$CHECKPOINT_COMMIT" "<desc>" <task-id>`
    - Al cerrar la wave: `bash "$RUN_GATES" 3`

15. **Wave 5a - 15-frontend-test** (TDD Red) + **Wave 5b - 16-frontend-development** (TDD Green)
    - Mismo patron: tests primero, slice-gate + checkpoint por slice,
      y al cerrar: `bash "$RUN_GATES" 5`

### Fase 5: Validacion

Secuencial tras las waves:

16. **17-integration-test** - Tests de integracion real
17. **18-e2e-test** - Tests end-to-end de flujos criticos
18. **19-smoke-test** - Validacion de flujos minimos viables
19. **20-linting-validator** - Zero errores, zero warnings

### Fase 6: Seguridad y Cierre

20. **21-security-review** - Auditoria de seguridad completa
21. **20-linting-validator** - Validacion final de linting

## Gates: UN solo gate humano, el resto automaticos

**GATE HUMANO UNICO, tras Fase 3 (paquete de decisiones completo):**
El usuario recibe EN UN SOLO MENSAJE el paquete de decisiones de producto:
- Veredicto de impacto (Fase 0: `00b_impact_analysis.md`)
- Dominio (Fase 1: `02_domain_model.md`, entidades y reglas clave resumidas)
- Arquitectura (Fase 2: `04_architecture_decision.md`, decision y trade-offs)
- Requisitos de seguridad (04b) y veredicto del validador de diseno (05b)
- Sprint plan (Fase 3: `09_sprint_plan/`)
- Contrato de API (Fase 3.5: especificacion OpenAPI de 10 y contrato de implementacion de 11)
- Critica de **plan-critic** sobre el sprint plan (dependencias, orden, supuestos)
- Las preguntas abiertas acumuladas en Fases 1-3 (si las hay)

Una sola aprobacion autoriza TODO. Si el usuario quiere cambiar dominio o
arquitectura, se regeneran los artefactos afectados y se re-presenta el paquete
(max 2 iteraciones antes de escalar con opciones concretas).

**Tras aprobar el paquete: cada sprint (Fases 4-6) corre de punta a punta sin
confirmaciones intermedias.** Infra + backend + frontend + validacion + seguridad de
corrido, con los gates automaticos (tests verdes, linting, smoke, cierre de wave) como
unica condicion de avance. Cada gate fallido se corrige dentro del alcance y se
re-ejecuta hasta 3 intentos; al agotarlos, parar con reporte consolidado. Al final de
CADA sprint: reporte consolidado y se continua con el siguiente sprint del plan
aprobado. Escalar al usuario solo ante gate agotado, fallo no resoluble o cambio de
alcance.

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
