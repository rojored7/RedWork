@echo off
REM scripts/smoke-test-frontend.bat
REM Smoke tests for frontend (Windows)

echo === FRONTEND SMOKE TESTS ===

echo 1. Frontend serves HTML...
curl -s http://localhost:3010 | findstr /C:"<!DOCTYPE html>" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅
) else (
    echo ❌
    exit /b 1
)

echo 2. JavaScript bundles...
curl -s http://localhost:3010 | findstr /C:"<script" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅
) else (
    echo ❌
    exit /b 1
)

echo 3. Build artifacts...
if exist "frontend\dist" (
    echo ✅
) else (
    echo ❌ frontend\dist not found
    exit /b 1
)

echo ✅ ALL FRONTEND SMOKE TESTS PASSED
