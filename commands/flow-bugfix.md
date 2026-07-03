---
description: Flujo para diagnosticar y corregir bugs con TDD y validacion
---

# Flujo: Bug Fix

Pipeline de agentes para diagnosticar, corregir y validar la solucion de un bug.

## Uso

```
/flow-bugfix [descripcion del bug, error, o comportamiento inesperado]
```

## Fases

### Fase 0: Pre-validacion de Impacto (SIEMPRE PRIMERO — gate duro)

0. **impact-prevalidator** - Mapear el terreno del bug ANTES de diagnosticar
   - Scope: `[SCOPE: bugfix-<id-o-descripcion-corta>]`
   - Blast radius del area sospechosa, baseline de tests (¿el rojo ya existia?),
     estado de servicios Docker y migraciones pendientes
   - Salida: `outputs/00b_impact_analysis.md` (VERDE/AMARILLO/ROJO)
   - Gate: `bash scripts/workflow/validate-impact-analysis.sh --allow-amber`
     exit 0 como precondicion de la Fase 2 (el baseline distingue el rojo
     pre-existente del rojo que introduce el fix)

### Fase 1: Diagnostico

1. **code-explorer** - Trazar el bug (puede correr en paralelo con Fase 0)
   - Analizar el path de ejecucion donde ocurre el error
   - Mapear dependencias involucradas
   - Identificar la causa raiz

### Fase 2: Reproduccion con Test

2. **tdd-guide** - Escribir test que reproduce el bug (RED)
   - El test DEBE fallar, confirmando que el bug existe
   - Definir el comportamiento esperado correcto

### Fase 3: Fix

3. **tdd-guide** - Implementar la correccion minima (GREEN)
   - Solo corregir el bug, no refactorizar ni mejorar codigo alrededor
   - El test debe pasar

4. **tdd-guide** - Refactor si es necesario (IMPROVE)
   - Solo si el fix introdujo deuda tecnica obvia

**Gate del fix (comandos directos del flujo):**
```bash
# 1. Gate: lint + types + tests con cobertura 100% (el test que reproduce incluido)
bash scripts/workflow/slice-gate.sh auto

# 2. Checkpoint silencioso: test + fix juntos en el mismo checkpoint; NUNCA pushea
bash scripts/workflow/checkpoint-commit.sh "fix: <bug>" "bugfix"
```
Si el gate falla: corregir dentro del alcance y re-ejecutar (reintentos acotados
por retry_controller; agotados -> parar con reporte consolidado).

### Fase 4: Review (en PARALELO)

Lanzar en PARALELO:

5. **code-reviewer** - Verificar calidad del fix
6. **security-reviewer** - Solo si el bug o fix toca:
   - Autenticacion/autorizacion
   - Input de usuario
   - Queries a base de datos
   - Operaciones de archivo
   - APIs externas
   - Pagos

### Fase 5: Validacion

7. **20-linting-validator** - Zero errores
8. **build-error-resolver** - Solo si el build falla

### Fase 6: Verificacion Final

9. **19-smoke-test** - Verificar que el fix funciona y no rompe nada mas

## Gates: UN solo gate humano

**GATE HUMANO UNICO — tras Fase 1:** el usuario recibe EN UN SOLO MENSAJE el
veredicto de impacto (Fase 0) + la causa raiz identificada, y confirma el
diagnostico (es donde el humano aporta criterio).

**Despues de la confirmacion: EJECUCION CONTINUA (Fases 2 a 6) SIN PAUSAS** — test que
reproduce, fix, review, validacion y smoke de corrido (Doctrina de Ejecucion de
CLAUDE.md global). Cada gate fallido se corrige dentro del alcance y se re-ejecuta
hasta FRAMEWORK_MAX_RETRIES (default 3) intentos; al agotarlos, PARAR con reporte
consolidado (intentos, evidencia, opciones concretas). Al final: reporte unico
(causa, fix, test incluido en el commit, evidencia del smoke).

## Ejemplo de Invocacion

```
/flow-bugfix El login retorna 500 cuando el email tiene caracteres especiales como +
```

El flujo automaticamente:
1. Explora el codigo de login y validacion de email
2. Escribe test: `login_with_plus_in_email_should_succeed`
3. Confirma que falla (RED)
4. Corrige la validacion de email
5. Test pasa (GREEN)
6. Review de codigo + review de seguridad (porque toca auth)
7. Linting
8. Smoke test del flujo de login

## Comandos Relacionados

- `/flow-update` - Para features nuevas, no bugs
- `/flow-new-project` - Para proyectos desde cero
- `/tdd` - TDD directo sin el pipeline completo
- `/build-fix` - Solo para errores de build, no bugs funcionales
