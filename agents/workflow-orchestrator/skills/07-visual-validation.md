# Skill: Visual Validation

**Purpose:** Validar la feature visualmente en navegador usando Playwright MCP
**Duration:** 3-5 minutos
**Critical:** Alta (detecta issues de UI que tests no capturan)

---

## 🎯 Objetivo

Usar Playwright MCP para:
1. Navegar a las páginas afectadas por la feature
2. Verificar que los componentes nuevos se ven correctamente
3. Interactuar con la UI (clicks, forms, etc.)
4. Capturar screenshots para comparación visual
5. Verificar que no hay errores de consola

---

## 📋 Proceso

### 1. Identificar Páginas Afectadas

Leer checkpoints de backend/frontend:
- `.checkpoints/02-backend.md` → Qué endpoints se agregaron
- `.checkpoints/03-frontend.md` → Qué componentes/páginas se modificaron

**Ejemplo:**
```
Feature: Sistema de Notificaciones
Páginas afectadas:
- Dashboard (agregado NotificationBell en header)
- /notifications (página nueva)
```

### 2. Asegurar Servicios Corriendo

```bash
# Verificar que Docker containers están up
docker ps | grep -E "ciber-backend|ciber-frontend"
```

Si no están corriendo:
```
⚠️  Servicios no están corriendo

Para validar visualmente, necesitas:
docker-compose up -d

¿Iniciar servicios? (y/n)
```

### 3. Navegación y Validación

Usar Playwright MCP tools:

#### 3.1: Navegar a Home/Dashboard

```typescript
await page.goto('http://localhost:3000');
await page.waitForLoadState('networkidle');

// Capturar screenshot
await page.screenshot({
  path: 'reports/visual/01-homepage.png',
  fullPage: true
});
```

#### 3.2: Buscar Componente Nuevo

```typescript
// Ejemplo: NotificationBell
const bellButton = page.locator('[data-testid="notification-bell"]');
await expect(bellButton).toBeVisible();

// Verificar badge con contador
const badge = page.locator('[data-testid="notification-badge"]');
const count = await badge.textContent();
console.log(`Notificaciones: ${count}`);
```

#### 3.3: Interacción

```typescript
// Click en bell
await bellButton.click();

// Verificar que dropdown abre
const dropdown = page.locator('[data-testid="notification-dropdown"]');
await expect(dropdown).toBeVisible();

// Screenshot del dropdown
await page.screenshot({
  path: 'reports/visual/02-dropdown-open.png'
});
```

#### 3.4: Verificar Console

```typescript
// Capturar errores de consola
const consoleErrors = [];
page.on('console', msg => {
  if (msg.type() === 'error') {
    consoleErrors.push(msg.text());
  }
});

// Al final
if (consoleErrors.length > 0) {
  console.log('❌ Errores de consola detectados:');
  consoleErrors.forEach(err => console.log(`  - ${err}`));
}
```

#### 3.5: Verificar Network

```typescript
// Capturar requests fallidos
const failedRequests = [];
page.on('response', response => {
  if (!response.ok()) {
    failedRequests.push({
      url: response.url(),
      status: response.status()
    });
  }
});
```

### 4. Comparación Visual (Si existen baselines)

```typescript
// Comparar screenshot con baseline
const currentScreenshot = fs.readFileSync('reports/visual/01-homepage.png');
const baselineScreenshot = fs.readFileSync('e2e/visual-regression/baselines/dashboard-student.png');

// Usar pixelmatch o similar
const diff = compareImages(currentScreenshot, baselineScreenshot);

if (diff.percentage > 1.0) {
  console.log(`⚠️  Visual diff: ${diff.percentage}% de cambios`);
  // Guardar diff image
  fs.writeFileSync('reports/visual/01-homepage-diff.png', diff.image);
}
```

---

## 📊 Output Esperado

### Caso Exitoso (✅)

```
📸 FASE 6: Validación Visual (Playwright MCP)

Iniciando validación en navegador...
URL base: http://localhost:3000

🌐 Navegación: Dashboard
   ✅ Página carga correctamente
   ✅ Tiempo de carga: 1.2s
   ✅ No errors en consola

🔍 Componente: NotificationBell
   ✅ Visible en header
   ✅ Badge muestra "3 notificaciones"
   ✅ Icon renderiza correctamente

👆 Interacción: Click en bell
   ✅ Dropdown abre correctamente
   ✅ Lista de 3 notificaciones visible
   ✅ Scroll funciona
   ✅ Timestamps formateados correctamente

📡 Network Requests
   ✅ GET /api/notifications → 200 OK (245ms)
   ✅ GET /api/user/me → 200 OK (cached)
   ✅ No requests fallidos

📸 Screenshots Capturados
   ✅ 01-homepage.png (1920x1080)
   ✅ 02-dropdown-open.png (1920x600)
   ✅ 03-notification-detail.png (1920x800)

🎨 Visual Regression
   ⏭️  No baselines previos
   💾 Guardados como nuevos baselines

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Validación Visual PASSED

Resumen:
- 0 errores de consola
- 0 requests fallidos
- 0 componentes rotos
- 3 screenshots capturados

Reporte: reports/visual/validation-report.html
```

### Caso con Issues (⚠️)

```
📸 FASE 6: Validación Visual

🌐 Navegación: Dashboard
   ✅ Página carga
   ❌ 2 errores en consola detectados

👆 Interacción: Click en bell
   ✅ Dropdown abre
   ⚠️  Scroll no funciona (overflow:hidden missing)

📡 Network Requests
   ❌ GET /api/notifications → 500 Internal Server Error
   Error: "Cannot read property 'findMany' of undefined"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

⚠️  Validación Visual: Issues detectados

Issues encontrados:
1. ❌ API error: /api/notifications retorna 500
2. ❌ Console errors (2):
   - TypeError: Cannot read property 'map' of undefined (NotificationDropdown.tsx:45)
   - Warning: Failed prop type (NotificationBell.tsx:12)
3. ⚠️  UI issue: Dropdown no permite scroll

Recomendaciones:
1. Verificar backend: notification_router.py
2. Agregar null check en NotificationDropdown.tsx:45
3. Agregar overflow-y:auto al dropdown

Screenshots con issues: reports/visual/
```

---

## 🔍 Checklist de Validación

Para cada componente/página nueva:

- [ ] ✅ Página/componente es visible
- [ ] ✅ Estilos correctos (colores, spacing, fonts)
- [ ] ✅ Responsive (probar diferentes viewports)
- [ ] ✅ Interacciones funcionan (clicks, hover, focus)
- [ ] ✅ Forms validan correctamente
- [ ] ✅ API calls exitosas (200 OK)
- [ ] ✅ Loading states visibles
- [ ] ✅ Error states se muestran
- [ ] ✅ No errores de consola
- [ ] ✅ No warnings de React/Vue
- [ ] ✅ Accesibilidad básica (keyboard navigation)

---

## 📸 Screenshots Estándar

Capturar para cada feature:

1. **01-initial-state.png** - Estado inicial
2. **02-interaction.png** - Durante interacción
3. **03-success-state.png** - Estado de éxito
4. **04-error-state.png** - Estado de error (si aplica)
5. **05-mobile.png** - Vista móvil

---

## 🎬 Scenarios de Prueba

### Scenario 1: Happy Path
```
1. Login como student
2. Navegar a dashboard
3. Ver NotificationBell
4. Click en bell
5. Ver lista de notificaciones
6. Click en notificación
7. Marcar como leída
8. Verificar badge actualiza
```

### Scenario 2: Empty State
```
1. Usuario sin notificaciones
2. Click en bell
3. Verificar "No hay notificaciones" mensaje
4. Verificar badge no visible
```

### Scenario 3: Error Handling
```
1. Simular API error (desconectar backend)
2. Click en bell
3. Verificar error message amigable
4. Verificar no crash de app
```

---

## 🛠️ Playwright MCP Tools a Usar

- `mcp__playwright__browser_navigate` - Navegación
- `mcp__playwright__browser_click` - Clicks
- `mcp__playwright__browser_snapshot` - Accessibility tree
- `mcp__playwright__browser_take_screenshot` - Screenshots
- `mcp__playwright__browser_console_messages` - Console logs
- `mcp__playwright__browser_network_requests` - Network requests
- `mcp__playwright__browser_wait_for` - Esperas

---

## 📝 Reporte Generado

Crear `.checkpoints/07-visual-validation.md`:

```markdown
# Visual Validation Report

**Feature:** Sistema de Notificaciones
**Date:** 2026-03-08 11:20:00
**Browser:** Chromium 120
**Viewport:** 1920x1080

## Pages Tested
1. Dashboard (/)
2. Notifications Page (/notifications)

## Components Validated
- NotificationBell
- NotificationDropdown
- NotificationItem

## Test Results
✅ 12 checks passed
⚠️  2 warnings
❌ 0 failures

## Screenshots
- reports/visual/01-homepage.png
- reports/visual/02-dropdown-open.png
[...]

## Console Messages
0 errors, 2 warnings

## Network Activity
- 5 requests total
- 5 successful (200 OK)
- 0 failed

## Recommendations
- Agregar aria-labels para accessibility
- Considerar lazy loading de notificaciones
```

---

**Duración estimada:** 3-5 minutos
**Tools:** Playwright MCP
