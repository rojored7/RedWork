# 00b - Impact Analysis

[ANALYZED-COMMIT: {sha}]
[GENERATED-AT: 2026-07-02T00:00:00Z]
[SCOPE: test-feature]

## Veredicto: ROJO

Riesgos estructurales sin resolver: no planificar.

## Blast Radius
| Área | Archivos | Dependientes inversos | Riesgo |
|---|---|---|---|
| db | migrations/ | divergencia de heads [VERIFIED: alembic heads] | crítico |

## Migraciones / Capa de datos
Dos heads divergentes en Alembic. [VERIFIED: alembic heads]

## Servicios Docker afectados (COPY vs volume)
Servicio db caído. [VERIFIED: docker compose ps]

## Contratos API
No evaluable con la base rota.

## Baseline de tests
- Comando: pytest  Total: 50  Pass: 0  Fail: 50 (suite irreproducible)

## Riesgos por vector (1-8)
4. Capa de datos: divergencia bloqueante.

## Condiciones para VERDE
1. Resolver la divergencia de heads de Alembic.
2. Levantar el servicio db y reproducir el baseline.
