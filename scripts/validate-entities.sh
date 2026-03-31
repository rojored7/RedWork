#!/bin/bash
# Script de validación de entities TypeORM
# Previene duplicación de entities y errores de esquema

set -e

echo "🔍 Validando estructura de entities TypeORM..."

ERRORS=0

# 1. Detectar entities duplicadas
echo ""
echo "1️⃣ Verificando entities duplicadas..."
DUPLICATE_ENTITIES=$(find backend/src -name "*.entity.ts" -type f | \
  xargs -I {} basename {} | \
  sort | \
  uniq -d)

if [ ! -z "$DUPLICATE_ENTITIES" ]; then
  echo "❌ ERROR: Entities duplicadas detectadas:"
  echo "$DUPLICATE_ENTITIES"
  echo ""
  echo "Archivos encontrados:"
  for entity in $DUPLICATE_ENTITIES; do
    find backend/src -name "$entity" -type f
  done
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No hay entities duplicadas"
fi

# 2. Verificar que entities estén en la ruta correcta
echo ""
echo "2️⃣ Verificando rutas de entities..."
WRONG_PATH_ENTITIES=$(find backend/src -path "*/persistence/entities/*.entity.ts" -type f)

if [ ! -z "$WRONG_PATH_ENTITIES" ]; then
  echo "⚠️  WARNING: Entities en ruta obsoleta /entities/ (deberían estar directamente en /persistence/):"
  echo "$WRONG_PATH_ENTITIES"
  echo ""
  echo "Estas entities pueden causar esquemas duplicados en TypeORM."
  echo "Mueve los archivos a /persistence/ y actualiza los imports."
  ERRORS=$((ERRORS + 1))
else
  echo "✅ Todas las entities están en rutas correctas"
fi

# 3. Verificar imports rotos
echo ""
echo "3️⃣ Verificando imports de entities..."
BROKEN_IMPORTS=$(grep -r "from '.*\/entities\/.*\.entity'" backend/src --include="*.ts" || true)

if [ ! -z "$BROKEN_IMPORTS" ]; then
  echo "⚠️  WARNING: Imports que apuntan a /entities/ (ruta obsoleta):"
  echo "$BROKEN_IMPORTS"
  echo ""
  echo "Estos imports fallarán. Actualizar a la ruta correcta sin /entities/"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ Todos los imports de entities son correctos"
fi

# 4. Verificar que dist/ esté limpio
echo ""
echo "4️⃣ Verificando que dist/ no tenga entities obsoletas..."
if [ -d "backend/dist" ]; then
  OLD_ENTITIES=$(find backend/dist -path "*/persistence/entities/*.entity.js" -type f || true)
  if [ ! -z "$OLD_ENTITIES" ]; then
    echo "⚠️  WARNING: Entities obsoletas en dist/ compilado:"
    echo "$OLD_ENTITIES"
    echo ""
    echo "Ejecuta: cd backend && rm -rf dist && npm run build"
    ERRORS=$((ERRORS + 1))
  else
    echo "✅ dist/ está limpio"
  fi
else
  echo "ℹ️  dist/ no existe (OK)"
fi

# 5. Verificar columnsa hashedPassword obsoletas
echo ""
echo "5️⃣ Verificando que no haya columnas 'hashedPassword' obsoletas..."
HASHED_PASSWORD_COLUMNS=$(grep -r "hashedPassword" backend/src --include="*.entity.ts" || true)

if [ ! -z "$HASHED_PASSWORD_COLUMNS" ]; then
  echo "⚠️  WARNING: Referencias a 'hashedPassword' encontradas:"
  echo "$HASHED_PASSWORD_COLUMNS"
  echo ""
  echo "La columna debe ser 'password', no 'hashedPassword'"
  ERRORS=$((ERRORS + 1))
else
  echo "✅ No hay referencias a hashedPassword obsoleto"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ]; then
  echo "✅✅✅ VALIDACIÓN EXITOSA: Estructura de entities correcta"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  exit 0
else
  echo "❌❌❌ VALIDACIÓN FALLIDA: $ERRORS problemas detectados"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  echo "Corrige estos problemas antes de continuar."
  exit 1
fi
