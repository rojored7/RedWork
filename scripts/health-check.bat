@echo off
REM scripts/health-check.bat
REM Health check for all services (Windows)

echo === HEALTH CHECK ===

echo Backend health...
curl -f http://localhost:8010/health -s >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ OK
) else (
    echo ❌ FAIL
    exit /b 1
)

echo Database health...
curl -f http://localhost:8010/health/db -s >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ OK
) else (
    echo ❌ FAIL
    exit /b 1
)

echo Redis health...
curl -f http://localhost:8010/health/redis -s >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ OK
) else (
    echo ❌ FAIL
    exit /b 1
)

echo Frontend serving...
curl -f http://localhost:3010 -s >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ OK
) else (
    echo ❌ FAIL
    exit /b 1
)

echo ✅ ALL HEALTH CHECKS PASSED
