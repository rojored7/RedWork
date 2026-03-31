@echo off
REM scripts/smoke-test-backend.bat
REM Smoke tests for backend functionality (Windows)

echo === BACKEND SMOKE TESTS ===

echo 1. Health check...
curl -s http://localhost:8010/health | findstr /C:"\"status\":\"ok\"" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅
) else (
    echo ❌
    exit /b 1
)

echo 2. Database connection...
curl -s http://localhost:8010/health/db | findstr /C:"\"database\":{\"status\":\"up\"}" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅
) else (
    echo ❌
    exit /b 1
)

echo 3. Redis connection...
curl -s http://localhost:8010/health/redis | findstr /C:"\"redis\":{\"status\":\"up\"}" >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅
) else (
    echo ❌
    exit /b 1
)

echo ✅ ALL BACKEND SMOKE TESTS PASSED
