---
description: Pipeline completo para agregar una feature o modificar un proyecto que YA existe (analisis de impacto, plan criticado, TDD por slices, rebuild Docker, migraciones, review y tests). Usar cuando el usuario pide agregar, cambiar o extender funcionalidad en un repo existente, sobre todo si hay Docker, base de datos o tests. NO usar para un bug puntual (flow-bugfix), para un proyecto desde cero (flow-new-project) ni para un cambio trivial de una linea (feature-dev o edicion directa).
---

# Flujo: Actualizacion / Nueva Feature

Pipeline de agentes para implementar una nueva funcionalidad en un proyecto que ya existe.

## Uso

```
/flow-update [descripcion de la feature o cambio requerido]
```

## Resolucion de scripts de gate (leer antes de Fase 0)

El flujo usa tres scripts que viven en cada proyecto, no en la configuracion global.
Cada proyecto puede tener todos, algunos o ninguno, y pueden estar en rutas distintas.
Por eso cada script se resuelve de forma independiente y desde la raiz del repo, para
que funcione aunque el comando se invoque desde un subdirectorio:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Para cada script X en: validate-impact-analysis.sh, slice-gate.sh, checkpoint-commit.sh
#   1. $ROOT/scripts/workflow/X
#   2. $ROOT/plataforma/scripts/workflow/X
#   3. ausente
```

Si un script esta ausente, el gate no desaparece: el agente verifica la misma condicion
a mano y lo declara en el reporte ("gate X verificado manualmente, script ausente").
Comportamiento por script ausente:

| Script ausente | Que hace el agente en su lugar |
|---|---|
| validate-impact-analysis.sh | Verifica que `outputs/00b_impact_analysis.md` exista, este anclado al HEAD actual y tenga veredicto. ROJO sigue bloqueando |
| slice-gate.sh | Corre lint, type-check y tests del proyecto a mano y reporta el resultado |
| checkpoint-commit.sh | Commit manual del slice con git, sin push. Si no hay git, lista los slices en el reporte final |

Nunca inventes que un gate paso. Un gate manual mal reportado es peor que un gate ausente.

## Fases

### Fase 0: Pre-validacion de Impacto (arranca primero, gate duro)

0. **impact-prevalidator** - Mapear TODO lo que se veria afectado antes de planificar
   - Blast radius (dependientes inversos por grep), capa de datos/migraciones,
     servicios Docker (COPY vs volume), contratos API, baseline de tests
   - Salida: `outputs/00b_impact_analysis.md` anclado al HEAD actual con
     veredicto VERDE / AMARILLO / ROJO
   - **Gate duro (precondicion de Fase 2):**
     ```bash
     bash "$VALIDATE_IMPACT" --allow-amber   # ruta resuelta arriba
     ```
     - exit 0: continuar (si AMARILLO, el planner debe incorporar las
       "Condiciones para VERDE" del reporte)
     - exit 1 (ROJO): parar y resolver las condiciones antes de planificar
     - exit 2/4: falta el reporte o quedo obsoleto. Re-ejecutar el agente
   - El reporte alimenta a code-explorer (donde mirar), planner (que mitigar)
     y plan-critic (que supuestos atacar)

Orden real: impact-prevalidator se lanza primero y puede solaparse con los agentes de
Fase 1, porque no dependen de el. Lo que NO puede pasar es entrar a Fase 2 sin que
este gate este verde.

### Fase 1: Analisis del Codigo Existente + Entorno de Ejecucion

Lanzar en PARALELO (pueden solaparse con el impact-prevalidator de Fase 0):

1. **code-explorer** - Trazar paths de ejecucion, mapear arquitectura, documentar dependencias
   - Analiza el codigo relevante al cambio solicitado
   - Identifica puntos de integracion
   - Detectar bugs preexistentes en archivos de configuracion que afecten el entorno:
     - `docker-compose.yml` (comillas en env vars, puertos, volumes)
     - `.env` / `.env.example` (variables faltantes o mal formateadas)
     - `alembic.ini`, `settings.py`, config files
   - Reportar cualquier bug de configuracion encontrado como bloqueante. Un entorno roto
     hace que todo lo que sigue falle por razones ajenas a la feature

2. **code-architect** - Disenar la feature sobre la arquitectura existente
   - Analiza patrones y convenciones del repo
   - Proporciona blueprint de implementacion con archivos concretos, interfaces, flujo de datos

3. **Mapeo de entorno de ejecucion** (no omitir: decide si hace falta rebuild mas adelante):
   - Determinar COMO se ejecuta cada servicio:
     - **Docker con COPY** (requiere `docker compose build` despues de cada cambio)
     - **Docker con volume mount** (HMR/hot-reload funciona, no requiere rebuild)
     - **Local directo** (python/npm en host, cambios se reflejan al guardar)
   - Verificar `docker-compose.yml`: buscar `volumes:` con bind mounts vs `COPY` en Dockerfile
   - Documentar la estrategia de rebuild necesaria para backend y frontend
   - Ejecutar: `docker compose ps` para ver estado actual de servicios

### Fase 1.5: Revision de Seguridad/Arquitectura Pre-Implementacion (condicional, tras Fase 1)

3.5. **security-reviewer** - Revisar el blueprint de `code-architect` ANTES de planificar
   - **CONDICIONAL**: solo si la feature toca auth, input de usuario no confiable,
     APIs expuestas, pagos, criptografia o datos sensibles (mismo criterio que Fase 4)
   - Entrada: blueprint de `code-architect` (Fase 1) + codigo existente relevante
     (para detectar patrones ya duplicados que la feature va a repetir)
   - Busca anti-patrones visibles desde el diseno: duplicacion de logica entre los
     archivos que el plan va a tocar, recursos sin limite (cache/colas/buffers sin
     bound), decisiones de arquitectura riesgosas (ej. objetos no hasheables usados
     como clave de cache), secretos hardcodeados, superficie de ataque nueva
   - Salida: hallazgos con severidad (CRITICAL/HIGH/MEDIUM/LOW), anclados a archivos
     concretos del blueprint
   - **No reemplaza** a `security-reviewer` de Fase 4: esta pasada solo adelanta lo
     que ya es visible en el diseno, antes de que se escriba y testee codigo

### Fase 2: Planificacion

4. **planner** - Crear plan de implementacion
   - Entrada: hallazgos de code-explorer + code-architect + mapeo de entorno
     + `outputs/00b_impact_analysis.md` (Fase 0)
     + hallazgos de `security-reviewer` si corrio Fase 1.5
   - Requerimientos, riesgos, fases
   - Si el veredicto de impacto fue AMARILLO: incorporar TODAS las "Condiciones para
     VERDE" del reporte como pasos del plan
   - Si Fase 1.5 corrio: incorporar todo hallazgo CRITICAL/HIGH como paso explicito
     del plan (ej. centralizar una funcion en vez de duplicarla desde el slice 1, usar
     una estructura con bound en vez de una sin limite)
   - El plan debe incluir: pasos de rebuild/restart de containers si aplica, pasos de
     migracion de DB si hay cambios de schema, y la descomposicion en slices TDD
     (3-9 slices; cada slice = test + implementacion + verificacion, commiteable de
     forma independiente). Un plan sin estos pasos se queda corto justo donde mas
     fallan las features sobre proyectos existentes

4.5. **plan-critic** (siempre, antes del gate humano) - Critica adversarial del plan
   - Entrada: el plan del planner + ruta del proyecto + hallazgos de Fase 1.5 (si corrio)
   - Intenta refutar el plan: dependencias no consideradas, orden incorrecto, supuestos
     sin verificar, migraciones/rebuild olvidados, falta de rollback
   - **Si Fase 1.5 encontro CRITICAL/HIGH**: verificar que el plan los incorporo; si no,
     es motivo de RECHAZADO
   - Salida: APROBADO / APROBADO CON OBSERVACIONES / RECHAZADO con evidencia
   - Si RECHAZADO: el planner corrige el plan y se re-critica (max 2 iteraciones)
   - Presentar al usuario el PLAN + LA CRITICA juntos
   - ESPERAR confirmacion del usuario

### Fase 2.5: Preparacion de Entorno (si hay Docker)

Ejecutar antes de cualquier implementacion. Verificar puertos libres antes de levantar
cualquier servicio y nunca bajar servicios que ya estaban corriendo.

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
   - Si el smoke test falla, parar y resolver antes de continuar

### Fase 3: Implementacion TDD

9. **tdd-guide** - Escribir tests primero
   - RED: tests que fallan
   - GREEN: implementacion minima
   - IMPROVE: refactor
   - Cobertura: el umbral lo fija el `slice-gate.sh` del proyecto (variable `COV_MIN`).
     Si el proyecto no tiene script, aplica el minimo de 80% de las reglas globales.
     No subir el umbral de un proyecto desde este flujo: eso es una decision del equipo
   - Calcular a mano cada caso de test ANTES de escribir el expected value.
     No adivinar valores esperados, derivarlos del algoritmo

10. Implementacion segun el stack:
    - **14-backend-development** (si es backend Python/FastAPI)
    - **16-frontend-development** (si es frontend)
    - O implementacion directa si es otro stack

10.5. **Regla de slices (gate directo + checkpoint silencioso):**
    Por CADA slice de la descomposicion del plan, en este orden exacto:
    ```bash
    # 1. Gate del slice (lint + types + tests con el umbral de cobertura del proyecto)
    bash "$SLICE_GATE" auto
    # exit 0 = verde | exit 1 = corregir dentro del alcance y re-ejecutar

    # 2. Checkpoint silencioso (solo con gate verde; nunca pushea)
    bash "$CHECKPOINT_COMMIT" "<que hace el slice>" "slice-N"
    ```
    - El gate es un comando del flujo: no depende de commits, hooks ni formato de mensaje
    - Si slice-gate falla: corregir dentro del alcance (build-error-resolver si es de
      build) y re-ejecutar. Maximo 3 intentos por slice; al agotarlos, parar con
      reporte consolidado (que se intento, evidencia por intento, opciones concretas)
    - No acumular varios slices en un checkpoint gigante: pierdes la capacidad de
      revertir uno solo
    - Si un slice rompe algo de un slice anterior, arreglarlo antes de seguir
    - El push nunca es automatico: publicar es decision del humano al final

### Fase 3.5: Rebuild + Migracion (despues de implementar)

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
    - Si algun servicio fallo, parar y resolver antes de continuar

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
    - Para otros lenguajes (go, rust, java, kotlin, csharp, flutter, cpp): usar el
      reviewer especifico solo si esta instalado en ~/.claude/agents (RedWork no los
      vendoriza); si no, **code-reviewer** generico

### Fase 5: Correccion y Validacion

19. **build-error-resolver** - Solo si el build falla
20. **20-linting-validator** - Zero errores, zero warnings

### Fase 6: Testing (en PARALELO segun aplique)

**Regla para E2E**: obtener datos reales de la DB ANTES de navegar.
No adivinar URLs, slugs, IDs ni credenciales: un E2E con datos inventados falla por
el dato y no por el producto, y cuesta una iteracion entera descubrirlo. Consultar primero:
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

**GATE HUMANO UNICO, tras Fase 2, paso 4.5 (impacto + plan + critica):**
El usuario recibe EN UN SOLO MENSAJE: veredicto de impacto (Fase 0) + hallazgos
del analisis (Fase 1 y Fase 1.5 no se detienen; sus hallazgos se presentan junto
al plan) + plan con slices + critica de plan-critic. Una sola aprobacion.

**Despues de la aprobacion: ejecucion continua (Fases 2.5 a 7) sin pausas.**
Plan aprobado = autorizacion completa para todo lo que el plan describe. No preguntar
"continuo?" entre fases: el usuario ya decidio y cada pregunta intermedia es una
interrupcion sin informacion nueva. Los checkpoints son gates automaticos: verificar
la condicion y seguir; detenerse solo si falla y la correccion exige salirse del plan:

| Gate automatico | Condicion para continuar | Si falla |
|---|---|---|
| Fase 0 impacto | validate-impact-analysis exit 0 (o verificacion manual equivalente) | ROJO: resolver condiciones; stale: re-ejecutar impact-prevalidator |
| Fase 2.5 entorno | servicios Up + smoke OK | corregir config (estaba en el plan) y seguir; escalar solo si no es resoluble |
| Fase 3.5 rebuild+migracion | containers levantan + schema verificado + smoke endpoint OK | diagnosticar y corregir dentro del plan; escalar solo si no es resoluble |
| Fase 4 review | sin issues CRITICAL/HIGH pendientes | corregirlos automaticamente y continuar; MEDIUM/LOW van al reporte final |
| Fase 6 tests | suites en verde | arreglar (test o producto segun corresponda) y re-ejecutar |

**Reintentos acotados:** cada gate fallido se corrige dentro del alcance del plan y se
re-ejecuta, hasta 3 intentos por gate. Al agotarlos, parar con reporte consolidado
(que se intento N veces, evidencia por intento, opciones concretas), nunca con una
pregunta vaga.

**REPORTE FINAL CONSOLIDADO** al terminar Fase 7: que se implemento, slices/commits,
resultados de tests y smoke, gates que fueron manuales por script ausente, issues
MEDIUM/LOW anotados, desviaciones del plan.

## Secuencia Critica (no alterar este orden)

```
Implementar codigo
    -> Rebuild containers (si Docker COPY)
        -> Verificar servicios levantan
            -> Aplicar migraciones DB
                -> Verificar schema
                    -> Smoke test endpoint
                        -> Tests E2E con datos reales
```

Cada paso existe porque el siguiente da falsos resultados sin el: un E2E contra un
container sin rebuild prueba el codigo viejo, y un smoke sin migracion falla por
schema y no por logica.

## Ejemplo de Invocacion

```
/flow-update Agregar endpoint de reset de password con envio de email y validacion de token
```

El flujo automaticamente:
1. Resuelve que scripts de gate tiene el proyecto
2. Explora el codigo de auth existente + mapea entorno Docker
3. Detecta si docker-compose.yml tiene bugs de configuracion
4. Disena la feature sobre la arquitectura actual
5. Revisa seguridad del diseno ANTES de planificar (toca auth -> dispara Fase 1.5)
6. Planifica incorporando los hallazgos de seguridad + pasos de rebuild y migracion
7. Verifica que servicios Docker estan sanos
8. Escribe tests primero (con valores calculados, no adivinados)
9. Implementa
10. Rebuild containers afectados
11. Aplica migracion, verifica schema
12. Smoke test del endpoint nuevo
13. Revisa seguridad post-implementacion (Fase 4, cambios que solo son visibles con codigo)
14. Valida linting y build
15. Ejecuta tests E2E con datos reales de la DB
