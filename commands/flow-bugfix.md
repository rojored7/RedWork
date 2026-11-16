---
description: Pipeline para diagnosticar y corregir un bug concreto en un proyecto existente (analisis de impacto, causa raiz, test que reproduce el bug, fix minimo, review y smoke). Usar cuando el usuario reporta un error, una excepcion, un 500, un comportamiento inesperado o un test que falla y quiere que se arregle. NO usar para agregar funcionalidad (flow-update), para errores de compilacion o build (build-fix) ni para refactors sin bug asociado.
---

# Flujo: Bug Fix

Pipeline de agentes para diagnosticar, corregir y validar la solucion de un bug.

## Uso

```
/flow-bugfix [descripcion del bug, error, o comportamiento inesperado]
```

## Resolucion de scripts de gate (leer antes de Fase 0)

El flujo usa tres scripts que viven en cada proyecto, no en la configuracion global.
Cada proyecto puede tener todos, algunos o ninguno. Cada script se resuelve por separado
y desde la raiz del repo, para que funcione aunque se invoque desde un subdirectorio:

```bash
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
# Para cada script X en: validate-impact-analysis.sh, slice-gate.sh, checkpoint-commit.sh
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
| validate-impact-analysis.sh | Verifica que `outputs/00b_impact_analysis.md` exista, este anclado al HEAD actual y tenga veredicto. ROJO sigue bloqueando |
| slice-gate.sh | Corre lint, type-check y tests del proyecto a mano y reporta el resultado |
| checkpoint-commit.sh | Commit manual de test + fix con git, sin push. Si no hay git, lo declara en el reporte |

Nunca inventes que un gate paso.

## Fases

### Fase 0: Pre-validacion de Impacto (arranca primero, gate duro)

0. **impact-prevalidator** - Mapear el terreno del bug antes de diagnosticar
   - Scope: `[SCOPE: bugfix-<id-o-descripcion-corta>]`
   - Blast radius del area sospechosa, baseline de tests (el rojo ya existia?),
     estado de servicios Docker y migraciones pendientes
   - Salida: `outputs/00b_impact_analysis.md` (VERDE/AMARILLO/ROJO)
   - Gate: `bash "$VALIDATE_IMPACT" --allow-amber` (ruta resuelta arriba) con exit 0
     como precondicion de la Fase 2. El baseline es lo que permite distinguir el rojo
     pre-existente del rojo que introduce el fix; sin el, un test que ya fallaba se
     confunde con una regresion

### Fase 1: Diagnostico

1. **code-explorer** - Trazar el bug (puede solaparse con Fase 0; ninguno depende del otro)
   - Analizar el path de ejecucion donde ocurre el error
   - Mapear dependencias involucradas
   - Identificar la causa raiz

### Fase 2: Reproduccion con Test

2. **tdd-guide** - Escribir test que reproduce el bug (RED)
   - El test debe fallar: es la unica prueba de que el bug existe y de que el test
     lo captura. Un test que pasa de entrada no prueba nada
   - Definir el comportamiento esperado correcto

### Fase 3: Fix

3. **tdd-guide** - Implementar la correccion minima (GREEN)
   - Solo corregir el bug, no refactorizar ni mejorar codigo alrededor. Cada cambio
     extra amplia el blast radius y dificulta revertir si el fix resulta incorrecto
   - El test debe pasar

4. **tdd-guide** - Refactor si es necesario (IMPROVE)
   - Solo si el fix introdujo deuda tecnica obvia

**Gate del fix (comandos directos del flujo):**
```bash
# 1. Gate: lint + types + tests (el test que reproduce incluido), con el umbral
#    de cobertura que fije el slice-gate del proyecto (COV_MIN) o 80% si no hay script
bash "$SLICE_GATE" auto

# 2. Checkpoint silencioso: test + fix juntos en el mismo checkpoint; nunca pushea
bash "$CHECKPOINT_COMMIT" "fix: <bug>" "bugfix"
```
Si el gate falla: corregir dentro del alcance y re-ejecutar, hasta 3 intentos. Al
agotarlos, parar con reporte consolidado (que se intento, evidencia, opciones).

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

**Sincronizacion de documentacion (si el proyecto tiene el protocolo):** si existen
`CLAUDE.md`, `TECHNICAL_DOCUMENTATION.md` o `CLAUDE.local.md`, lanzar **doc-updater** con el
diff final: aplica las reglas de `CLAUDE.local.md` (que cambios exigen actualizar que seccion
y cuales no) y marca lo actualizado con `[VERIFICADO] - <fecha>`. Los documentos actualizados
entran en el ultimo checkpoint del flujo, nunca quedan sin versionar. Si las reglas dicen que
el cambio no exige actualizacion, se declara asi en el reporte final.

### Fase 5: Validacion

7. **20-linting-validator** - Zero errores
8. **build-error-resolver** - Solo si el build falla

### Fase 6: Verificacion Final

9. **19-smoke-test** - Verificar que el fix funciona y no rompe nada mas

## Gates: UN solo gate humano

**GATE HUMANO UNICO, tras Fase 1:** el usuario recibe EN UN SOLO MENSAJE el
veredicto de impacto (Fase 0) + la causa raiz identificada, y confirma el
diagnostico. Es el punto donde el humano aporta criterio: un fix sobre un
diagnostico equivocado es trabajo perdido.

**Despues de la confirmacion: ejecucion continua (Fases 2 a 6) sin pausas.** Test que
reproduce, fix, review, validacion y smoke de corrido. El usuario ya decidio; cada
pregunta intermedia es una interrupcion sin informacion nueva. Cada gate fallido se
corrige dentro del alcance y se re-ejecuta hasta 3 intentos; al agotarlos, parar con
reporte consolidado (intentos, evidencia, opciones concretas). Al final: reporte unico
(causa, fix, test incluido en el commit, evidencia del smoke, gates que fueron
manuales por script ausente).

## Ejemplo de Invocacion

```
/flow-bugfix El login retorna 500 cuando el email tiene caracteres especiales como +
```

El flujo automaticamente:
1. Resuelve que scripts de gate tiene el proyecto
2. Explora el codigo de login y validacion de email
3. Escribe test: `login_with_plus_in_email_should_succeed`
4. Confirma que falla (RED)
5. Corrige la validacion de email
6. Test pasa (GREEN)
7. Review de codigo + review de seguridad (porque toca auth)
8. Linting
9. Smoke test del flujo de login

## Comandos Relacionados

- `/flow-update` - Para features nuevas, no bugs
- `/flow-new-project` - Para proyectos desde cero
- `/tdd` - TDD directo sin el pipeline completo
- `/build-fix` - Solo para errores de build, no bugs funcionales
