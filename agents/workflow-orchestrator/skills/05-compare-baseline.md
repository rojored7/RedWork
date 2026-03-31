# Skill: Compare Baseline

**Purpose:** Comparar estado actual vs baseline y generar tabla de métricas
**Duration:** 1-2 minutos
**Critical:** Moderado

---

## 🎯 Objetivo

Generar una tabla comparativa clara que muestre cómo cambió el proyecto después de implementar la feature/fix.

---

## 📋 Proceso

### 1. Cargar Baseline

```bash
# Leer .baselines/latest.json
```

Extraer:
- Tests: total, passed, failed
- Coverage: backend %, frontend %
- Timestamp

### 2. Capturar Estado Actual

Ejecutar los mismos comandos que en baseline pero sin guardar:
- Backend tests count
- Frontend tests count
- Coverage actual

### 3. Calcular Diferencias

```javascript
const diff = {
  tests: {
    total: current.total - baseline.total,
    passed: current.passed - baseline.passed,
    failed: current.failed - baseline.failed
  },
  coverage: {
    backend: current.backend - baseline.backend,
    frontend: current.frontend - baseline.frontend
  }
};
```

### 4. Generar Tabla Markdown

```markdown
# 📊 Comparación Before/After

## Fecha de Baseline
{baseline.timestamp}

## Tests

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Tests totales | 156 | 179 | +23 ✅ |
| Tests passed | 156 | 179 | +23 ✅ |
| Tests failed | 0 | 0 | 0 ✅ |
| Success rate | 100% | 100% | 0% ✅ |

## Coverage

| Capa | Antes | Después | Cambio |
|------|-------|---------|--------|
| Backend | 82% | 83% | +1% ✅ |
| Frontend | 76% | 78% | +2% ✅ |
| Promedio | 79% | 80.5% | +1.5% ✅ |

## Código

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Archivos | 245 | 258 | +13 |
| LOC Backend | 12,450 | 12,865 | +415 |
| LOC Frontend | 8,230 | 8,565 | +335 |
| LOC Total | 20,680 | 21,430 | +750 |

## Resumen

✅ **Todos los indicadores mejoraron o se mantuvieron estables**

- Tests: +23 nuevos, 0 rotos
- Coverage: Incremento en ambas capas
- Calidad: Mantenida

**Veredicto:** ✅ Safe to merge
```

### 5. Generar Gráfica ASCII (Opcional)

```
Coverage Trend:
Backend:  [████████████████████  ] 82% → 83% (+1%)
Frontend: [██████████████████    ] 76% → 78% (+2%)
```

---

## 📊 Output Esperado

```
📊 FASE 5: Comparación Before/After

Analizando cambios desde baseline...
Baseline: 2026-03-08 10:30:00

┌─────────────────┬─────────┬─────────┬──────────┐
│ Métrica         │ Antes   │ Después │ Cambio   │
├─────────────────┼─────────┼─────────┼──────────┤
│ Tests totales   │ 156     │ 179     │ +23 ✅   │
│ Tests passed    │ 156     │ 179     │ +23 ✅   │
│ Tests failed    │ 0       │ 0       │ 0 ✅     │
│ Backend cov.    │ 82%     │ 83%     │ +1% ✅   │
│ Frontend cov.   │ 76%     │ 78%     │ +2% ✅   │
│ LOC backend     │ 12,450  │ 12,865  │ +415     │
│ LOC frontend    │ 8,230   │ 8,565   │ +335     │
└─────────────────┴─────────┴─────────┴──────────┘

✅ Veredicto: Mejora en todas las métricas
✅ Safe to merge

Reporte completo: .checkpoints/05-comparison.md
```

---

## 🚨 Casos Especiales

### Si Coverage Bajó

```
⚠️  Coverage disminuyó

| Capa | Antes | Después | Cambio |
|------|-------|---------|--------|
| Backend | 82% | 79% | -3% ⚠️ |

Recomendación:
- Agregar tests para nuevo código
- Target: Volver a 82%+
```

### Si Tests Rotos

```
❌ Tests rotos detectados

| Métrica | Antes | Después | Cambio |
|---------|-------|---------|--------|
| Tests failed | 0 | 3 | +3 ❌ |

⛔ NO safe to merge
Ver: .checkpoints/04-regression-report.md
```

---

## 📝 Guardar Reporte

Crear `.checkpoints/05-comparison.md` con:
- Tabla completa
- Análisis de tendencias
- Recomendaciones

---

**Duración estimada:** 1-2 minutos
