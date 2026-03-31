# 🎯 Guía: Ver y Usar el Workflow Visual en GitLab

**Tu workflow de 20 agentes ya está en GitLab como un gráfico visual interactivo**

---

## 📍 Paso 1: Ver el Workflow Visual

1. **Ve a tu repositorio en GitLab**:
   ```
   https://gitlab.com/rojored7-group/redwork
   ```

2. **Click en el menú lateral izquierdo** → **"Build"** → **"Pipelines"**

   URL directa: https://gitlab.com/rojored7-group/redwork/-/pipelines

3. **Verás el pipeline graph** (gráfico de workflow) con:
   - 6 etapas (stages): Discovery → Planning → Infrastructure → Development → Testing → Quality
   - 20 nodos (agents) conectados entre sí
   - Flechas mostrando dependencias

---

## 🎨 Cómo se ve el Workflow

```
┌─────────────────────────────────────────────────────────────┐
│  STAGE 1: DISCOVERY                                         │
│  01 → 02 → 03 → 04 → 05                                     │
├─────────────────────────────────────────────────────────────┤
│  STAGE 2: PLANNING                                          │
│  06 → 07 → 08 → 09                                          │
├─────────────────────────────────────────────────────────────┤
│  STAGE 3: INFRASTRUCTURE                                    │
│  12                                                          │
├─────────────────────────────────────────────────────────────┤
│  STAGE 4: DEVELOPMENT (Parallel)                            │
│  ┌─────────────────┐        ┌─────────────────┐           │
│  │ Backend Track   │        │ Frontend Track  │           │
│  │ 10 → 13 → 20    │        │ 11 → 14 → 20    │           │
│  └─────────────────┘        └─────────────────┘           │
├─────────────────────────────────────────────────────────────┤
│  STAGE 5: TESTING                                           │
│  15 → 16 → 18                                               │
├─────────────────────────────────────────────────────────────┤
│  STAGE 6: QUALITY                                           │
│  19 → 20 (final)                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 Paso 2: Ejecutar Agentes Manualmente

Cada agente tiene `when: manual`, lo que significa que TÚ decides cuándo ejecutarlo:

### Ejecutar un agente:

1. **Ve a Pipelines** → Click en el botón **"Run pipeline"** (arriba derecha)
2. **Selecciona la rama**: `framework`
3. **Click "Run pipeline"**
4. **Verás el gráfico** con todos los agentes
5. **Click en el primer nodo** (01-product-discovery)
6. **Click en el botón "Play" ▶️** para ejecutarlo

### Secuencia recomendada:

```bash
# Ejecuta uno por uno en este orden:
01-product-discovery          # Click Play ▶️
   ↓ (espera que termine)
02-domain-modeling            # Click Play ▶️
   ↓
03-context-mapping            # Click Play ▶️
   ↓
04-architecture-decision      # Click Play ▶️
   ↓
05-service-design             # Click Play ▶️
   ↓
06-epic-generation            # Click Play ▶️
   ↓
... y así sucesivamente
```

---

## 📊 Paso 3: Ver Logs de Ejecución

Cuando ejecutas un agente:

1. **Click en el nodo** del agente en el gráfico
2. **Se abre el log** de ejecución
3. **Verás**:
   - Nombre del agente
   - Primeras 30 líneas del archivo del agente
   - Output esperado (archivo que genera)
   - Status: ✅ Success o ❌ Failed

---

## 🎯 Colores en el Gráfico

GitLab usa colores para indicar el estado:

| Color | Significado |
|-------|------------|
| ⚪ Gris | No ejecutado (waiting) |
| 🔵 Azul | En ejecución (running) |
| 🟢 Verde | Exitoso (success) |
| 🔴 Rojo | Fallido (failed) |
| ⚠️ Amarillo | Manual (esperando que hagas click Play) |

---

## 🔗 Dependencias entre Agentes

El workflow tiene dependencias (`needs:`), lo que significa:

- **No puedes ejecutar Agent 02** hasta que Agent 01 esté ✅ verde
- **No puedes ejecutar Agent 10** hasta que Agent 12 esté ✅ verde
- **Agents 10 y 11 SÍ se pueden ejecutar en paralelo** (backend y frontend)

---

## 📝 Paso 4: Hacer Merge a Main

Una vez que hayas ejecutado todos los agentes y todo esté ✅ verde:

1. **Ve a**: https://gitlab.com/rojored7-group/redwork/-/merge_requests/new?merge_request[source_branch]=framework
2. **Click "Create merge request"**
3. **Title**: `feat: Add Framework with 20 Agents and Visual Workflow`
4. **Description**: Copia esto:
   ```
   ## Changes
   - ✅ 20 specialized agents for full-stack development
   - ✅ GitLab CI/CD pipeline with visual workflow
   - ✅ Quality enforcement framework (4 layers)
   - ✅ Git hooks for validation
   - ✅ Complete documentation

   ## How to Use
   1. Go to Pipelines → Run pipeline
   2. Execute agents one by one (click Play ▶️)
   3. Follow the visual workflow graph

   ## Pipeline Graph
   See: https://gitlab.com/rojored7-group/redwork/-/pipelines
   ```
5. **Click "Create merge request"**
6. **Click "Merge"**

---

## 🛠️ Troubleshooting

### No veo el pipeline

**Problema**: Voy a Pipelines y no hay nada
**Solución**:
1. Asegúrate de estar en la rama `framework`
2. Click en "Run pipeline" para crear el primero

### El pipeline está "blocked"

**Problema**: Los agentes no se ejecutan
**Solución**: Cada agente tiene `when: manual`, debes hacer click en Play ▶️ manualmente

### Quiero ejecutar todos automáticamente

**Solución**: Edita `.gitlab-ci.yml` y cambia:
```yaml
when: manual  →  when: on_success
```

---

## 📚 URLs Importantes

| Recurso | URL |
|---------|-----|
| Repositorio | https://gitlab.com/rojored7-group/redwork |
| Pipelines | https://gitlab.com/rojored7-group/redwork/-/pipelines |
| Merge Request | https://gitlab.com/rojored7-group/redwork/-/merge_requests/new?merge_request[source_branch]=framework |
| Archivo CI/CD | https://gitlab.com/rojored7-group/redwork/-/blob/framework/.gitlab-ci.yml |

---

## 🎉 Próximos Pasos

1. ✅ **Ve a Pipelines** y ejecuta el primer agente (01-product-discovery)
2. ✅ **Sigue el workflow visual** ejecutando cada agente en orden
3. ✅ **Revisa los logs** de cada ejecución
4. ✅ **Cuando todos estén verdes**, haz merge a main

---

**Creado**: 2026-03-31
**Framework**: Quality Enforcement Framework v1.0.0
**GitLab CI/CD**: Configurado con 20 agentes
