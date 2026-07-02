#!/usr/bin/env bash
# python-detect.sh - Resolve a working Python interpreter into $PYTHON_BIN.
#
# Order: pre-set $PYTHON_BIN -> python3 -> python -> py -3 (Windows launcher,
# resolved to its real executable path so call sites can quote "$PYTHON_BIN").
# Windows Store aliases print an install message and exit non-zero, so every
# candidate is verified by actually executing code.
#
# Usage (from any framework script):
#   source "<path-to>/scripts/lib/python-detect.sh"
#   "$PYTHON_BIN" -c "..."

resolve_python() {
    local c exe
    if [ -n "${PYTHON_BIN:-}" ] && "$PYTHON_BIN" -c "pass" >/dev/null 2>&1; then
        export PYTHON_BIN
        return 0
    fi
    for c in python3 python; do
        if command -v "$c" >/dev/null 2>&1 && "$c" -c "pass" >/dev/null 2>&1; then
            PYTHON_BIN="$c"
            export PYTHON_BIN
            return 0
        fi
    done
    if command -v py >/dev/null 2>&1; then
        exe=$(py -3 -c "import sys; print(sys.executable)" 2>/dev/null | tr -d '\r')
        if [ -n "$exe" ] && "$exe" -c "pass" >/dev/null 2>&1; then
            PYTHON_BIN="$exe"
            export PYTHON_BIN
            return 0
        fi
    fi
    PYTHON_BIN=""
    return 1
}

resolve_python
