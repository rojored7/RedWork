---
description: Flujo para agregar features o actualizar un proyecto existente con soporte Docker
---

# Flujo: Actualizacion / Nueva Feature

Pipeline de agentes para implementar una nueva funcionalidad en un proyecto que ya existe.

## Uso

```
/flow-update [descripcion de la feature o cambio requerido]
```

## Fases

### Fase 0: Pre-validacion de Impacto (SIEMPRE PRIMERO — gate duro)

0. **impact-prevalidator** - Mapear TODO lo que se veria afectado ANTES de explorar o planificar
   - Blast radius (dependientes inversos por grep), capa de datos/migraciones,
     servicios Docker (COPY vs volume), contratos API, baseline de tests
   - Salida: `outputs/00b_impact_analysis.md` anclado al HEAD actual con
     veredicto VERDE / AMARILLO / ROJO
   - **Gate duro (precondicion de Fase 2):**
     ```bash
     bash scripts/workflow/validate-impact-analysis.sh --allow-amber
     ```
     - exit 0: continuar (si AMARILLO, el planner DEBE incorporar las
       "Condiciones para VERDE" del reporte)
     - exit 1 (ROJO): PARAR — resolver las condiciones antes de planificar
     - exit 2/4: falta el reporte o quedo obsoleto — re-ejecutar el agente
   - El reporte alimenta a code-explorer (donde mirar), planner (que mitigar)
     y plan-critic (que supuestos atacar)

### Fase 1: Analisis del Codigo Existente + Entorno de Ejecucion

Lanzar en PARALELO (el impact-prevalidator de Fase 0 puede correr en paralelo con estos):

1. **code-explorer** - Trazar paths de ejecucion, mapear arquitectura, documentar dependencias
   - Analiza el codigo relevante al cambio solicitado
   - Identifica puntos de integracion
   - **OBLIGATORIO: Detectar bugs preexistentes** en archivos de configuracion que afecten el entorno:
     - `docker-compose.yml` (comillas en env vars, puertos, volumes)
     - `.env` / `.env.example` (variables faltantes o mal formateadas)
     - `alembic.ini`, `settings.py`, config files
   - Reportar cualquier bug de configuracion encontrado como bloqueante

2. **code-architect** - Disenar la feature sobre la arquitectura existente
   - Analiza patrones y convenciones del repo
   - Proporciona blueprint de implementacion con archivos concretos, interfaces, flujo de datos

3. **Mapeo de entorno de ejecucion** (OBLIGATORIO, no omitir):
   - Determinar COMO se ejecuta cada servicio:
     - **Docker con COPY** (requiere `docker compose build` despues de cada cambio)
     - **Docker con volume mount** (HMR/hot-reload funciona, no requiere rebuild)
     - **Local directo** (python/npm en host, cambios se reflejan al guardar)
   - Verificar `docker-compose.yml`: buscar `volumes:` con bind mounts vs `COPY` en Dockerfile
   - Documentar la estrategia de rebuild necesaria para backend y frontend
   - Ejecutar: `docker compose ps` para ver estado actual de servicios

### Fase 2: Planificacion

4. **planner** - Crear plan de implementacion
   - Entrada: hallazgos de code-explorer + code-architect + mapeo de entorno
     + `outputs/00b_impact_analysis.md` (Fase 0)
   - Requerimientos, riesgos, fases
   - **OBLIGATORIO si el veredicto de impacto fue AMARILLO**: incorporar TODAS
     las "Condiciones para VERDE" del reporte de impacto como pasos del plan
   - **OBLIGATORIO en el plan**: incluir pasos de rebuild/restart de containers si aplica
   - **OBLIGATORIO en el plan**: incluir pasos de migracion de DB si hay cambios de schema
   - **OBLIGATORIO en el plan**: descomponer la implementacion en slices TDD (3-9 slices;
     cada slice = test + implementacion + verificacion, commiteable de forma independiente)

4.5. **plan-critic** (OBLIGATORIO antes del gate humano) - Critica adversarial del plan
   - Entrada: el plan del planner + ruta del proyecto
   - Intenta refutar el plan: dependencias no consideradas, orden incorrecto, supuestos
     sin verificar, migraciones/rebuild olvidados, falta de rollback
   - Salida: APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO con evidencia
   - Si RECHAZADO: el planner corrige el plan y se re-critica (max 2 iteraciones)
   - Presentar al usuario el PLAN + LA CRITICA juntos
   - ESPERAR confirmacion del usuario

### Fase 2.5: Preparacion de Entorno (OBLIGATORIA si hay Docker)

Ejecutar ANTES de cualquier implementacion:

5. **Verificar que servicios estan corriendo**:
   ```bash
   docker compose ps
   docker compose logs --tail=20 <service>
   ```

6. **Corregir bugs de configuracion** encontrados en Fase 1:
   - Arreglar comillas en env vars de docker-compose.yml
   - Corregir variables de entorno faltantes
   - Cualquier otro bloqueante de configuracion

7. **Rebuild containers si es necesario**:
   ```bash
   docker compose up -d --build <services-afectados>
   ```

8. **Smoke test de servicios**:
   ```bash
   # Backend responde
   docker compose exec backend python -c "print('backend ok')"
   # O curl al health endpoint
   curl -s http://localhost:<puerto>/health || curl -s http://localhost:<puerto>/docs
   
   # Frontend responde
   curl -s http://localhost:<puerto-frontend>/ | head -5
   ```
   - Si el smoke test falla, PARAR y resolver antes de continuar

### Fase 3: Implementacion TDD

9. **tdd-guide** - Escribir tests primero
   - RED: tests que fallan
   - GREEN: implementacion minima
   - IMPROVE: refactor
   - Verificar 80%+ cobertura
   - **REGLA: Calcular a mano cada caso de test ANTES de escribir el expected value**
   - No adivinar valores esperados, derivarlos del algoritmo

10. Implementacion segun el stack:
    - **14-backend-development** (si es backend Python/FastAPI)
    - **16-frontend-development** (si es frontend)
    - O implementacion directa si es otro stack

10.5. **Regla de slices (1 slice = 1 commit):**
    - Implementar slice por slice segun la descomposicion del plan
    - Un slice SOLO se commitea cuando typecheck + tests del modulo + build (si aplica)
      estan en verde — "deberia funcionar" no es verde
    - NUNCA acumular varios slices en un solo commit gigante
    - Si un slice rompe algo de un slice anterior, arreglarlo ANTES de seguir al siguiente

### Fase 3.5: Rebuild + Migracion (OBLIGATORIA despues de implementar)

Ejecutar en SECUENCIA ESTRICTA, no saltar pasos:

11. **Rebuild containers afectados** (si Docker usa COPY):
    ```bash
    docker compose up -d --build backend   # si hubo cambios backend
    docker compose up -d --build frontend  # si hubo cambios frontend
    ```

12. **Verificar que servicios levantaron sin errores**:
    ```bash
    docker compose ps                        # todos deben estar "Up" o "healthy"
    docker compose logs --tail=30 backend    # sin tracebacks
    docker compose logs --tail=30 frontend   # sin errores de build
    ```
    - Si algun servicio fallo, PARAR y resolver antes de continuar

13. **Aplicar migraciones de DB** (si hubo cambios de schema):
    ```bash
    docker compose exec backend alembic upgrade head
    # O el equivalente del proyecto (prisma migrate, django migrate, etc.)
    ```

14. **Verificar que el schema tiene los cambios**:
    ```bash
    # Verificar columna/tabla nueva existe
    docker compose exec db psql -U <user> -d <db> -c "\d <tabla>"
    # O query directa al campo nuevo
    docker compose exec db psql -U <user> -d <db> -c "SELECT column_name FROM information_schema.columns WHERE table_name='<tabla>' AND column_name='<campo_nuevo>'"
    ```

15. **Smoke test del cambio especifico**:
    ```bash
    # Probar que el endpoint nuevo/modificado responde con el campo nuevo
    curl -s http://localhost:<puerto>/api/<endpoint> | python -m json.tool
    ```
    - Solo continuar a la siguiente fase si el smoke test pasa

### Fase 4: Review (en PARALELO)

Lanzar en PARALELO estos agentes:

16. **code-reviewer** - Calidad general, patrones, mejores practicas
17. **security-reviewer** - Solo si toca auth, input de usuario, APIs, pagos, crypto
18. Reviewer por lenguaje segun el proyecto:
    - **python-reviewer** para Python
    - **typescript-reviewer** para TS/JS
    - (otros lenguajes: usar **code-reviewer** generico; los reviewers especificos
      de go/rust/java/kotlin/csharp/flutter/cpp estan archivados en .claude-archive)

### Fase 5: Correccion y Validacion

19. **build-error-resolver** - Solo si el build falla
20. **20-linting-validator** - Zero errores, zero warnings

### Fase 6: Testing (en PARALELO segun aplique)

**REGLA OBLIGATORIA para E2E**: Obtener datos reales de la DB ANTES de navegar.
No adivinar URLs, slugs, IDs, ni credenciales. Consultar primero:
```bash
# Obtener slugs reales
docker compose exec db psql -U <user> -d <db> -c "SELECT slug FROM <tabla> LIMIT 5"
# Obtener IDs reales
docker compose exec db psql -U <user> -d <db> -c "SELECT id, name FROM <tabla> LIMIT 5"
# Obtener credenciales de test (si existen seeders)
docker compose exec db psql -U <user> -d <db> -c "SELECT email FROM users WHERE is_test=true LIMIT 1"
```

21. **13-backend-test** - Si hubo cambios backend
22. **15-frontend-test** - Si hubo cambios frontend
23. **17-integration-test** - Si el cambio afecta multiples componentes
24. **18-e2e-test** - Si el cambio afecta flujos criticos de usuario
    - Usar datos reales obtenidos de la DB, no inventados

### Fase 7: Validacion Final

25. **19-smoke-test** - Verificar que flujos criticos siguen funcionando
26. **21-security-review** - Si el cambio toca areas sensibles (auth, datos, APIs)

## Gates: UN solo gate humano, el resto automaticos

**GATE HUMANO UNICO — tras Fase 2, paso 4.5 (impacto + plan + critica):**
El usuario recibe EN UN SOLO MENSAJE: veredicto de impacto (Fase 0) + hallazgos
del analisis (Fase 1 NO se detiene; sus hallazgos se presentan junto al plan) +
plan con slices + critica de plan-critic. Una sola aprobacion.

**Despues de la aprobacion: EJECUCION CONTINUA (Fases 2.5 a 7) SIN PAUSAS.**
Plan aprobado = autorizacion completa (ver Doctrina de Ejecucion en CLAUDE.md global).
PROHIBIDO preguntar "¿continuo?" entre fases. Los antiguos checkpoints son ahora
gates AUTOMATICOS — verificar la condicion y seguir; detenerse SOLO si falla y la
correccion exige salirse del plan:

| Gate automatico | Condicion para continuar | Si falla |
|---|---|---|
| Fase 0 impacto | validate-impact-analysis.sh exit 0 | ROJO: resolver condiciones; stale: re-ejecutar impact-prevalidator |
| Fase 2.5 entorno | servicios Up + smoke OK | corregir config (estaba en el plan) y seguir; escalar solo si no es resoluble |
| Fase 3.5 rebuild+migracion | containers levantan + schema verificado + smoke endpoint OK | diagnosticar y corregir dentro del plan; escalar solo si no es resoluble |
| Fase 4 review | sin issues CRITICAL/HIGH pendientes | corregirlos automaticamente y continuar; MEDIUM/LOW van al reporte final |
| Fase 6 tests | suites en verde | arreglar (test o producto segun corresponda) y re-ejecutar |

**Reintentos acotados (motor de fabrica):** cada gate fallido se corrige dentro del
alcance del plan y se re-ejecuta, hasta `FRAMEWORK_MAX_RETRIES` (default 3) intentos
por gate. En proyectos con waves (`run-gates.sh <wave>`), el contador vive en
`.project-state/retry_state.json`; al agotar los intentos se crea
`needs_human.flag` y se PARA con reporte consolidado (que se intento N veces,
evidencia por intento, opciones concretas) — nunca con una pregunta vaga.

**REPORTE FINAL CONSOLIDADO** al terminar Fase 7: que se implemento, slices/commits,
resultados de tests y smoke, issues MEDIUM/LOW anotados, desviaciones del plan.

## Secuencia Critica (NUNCA alterar este orden)

```
Implementar codigo
    -> Rebuild containers (si Docker COPY)
        -> Verificar servicios levantan
            -> Aplicar migraciones DB
                -> Verificar schema
                    -> Smoke test endpoint
                        -> Tests E2E con datos reales
```

Saltar cualquier paso de esta secuencia GARANTIZA fallas.

## Ejemplo de Invocacion

```
/flow-update Agregar endpoint de reset de password con envio de email y validacion de token
```

El flujo automaticamente:
1. Explora el codigo de auth existente + mapea entorno Docker
2. Detecta si docker-compose.yml tiene bugs de configuracion
3. Disena la feature sobre la arquitectura actual
4. Planifica incluyendo pasos de rebuild y migracion
5. Verifica que servicios Docker estan sanos
6. Escribe tests primero (con valores calculados, no adivinados)
7. Implementa
8. Rebuild containers afectados
9. Aplica migracion, verifica schema
10. Smoke test del endpoint nuevo
11. Revisa seguridad (porque toca auth)
12. Valida linting y build
13. Ejecuta tests E2E con datos reales de la DB

## Comandos Relacionados

- `/flow-new-project` - Para proyectos desde cero con DDD
- `/flow-bugfix` - Para corregir bugs
- `/feature-dev` - Alternativa mas simple sin pipeline completo de agentes
