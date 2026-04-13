#!/bin/bash
# RedWork Secret Scanner
# Scans files for leaked secrets, credentials, and sensitive data.
#
# Usage:
#   bash scan-secrets.sh [target_dir]     # Scan directory (default: current dir)
#   bash scan-secrets.sh --staged         # Scan git staged files only
#
# Exit codes:
#   0 = clean (no secrets found)
#   1 = secrets detected
#   2 = scanner error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="${PATTERNS_FILE:-${SCRIPT_DIR}/secret-patterns.txt}"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
else
    RED='' YELLOW='' GREEN='' NC=''
fi

# Validate patterns file
if [ ! -f "$PATTERNS_FILE" ]; then
    echo "ERROR: Patterns file not found: $PATTERNS_FILE" >&2
    exit 2
fi

# Determine scan mode
SCAN_MODE="directory"
TARGET_DIR="."
FILES_TO_SCAN=""

if [ "${1:-}" = "--staged" ]; then
    SCAN_MODE="staged"
    FILES_TO_SCAN=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || echo "")
    if [ -z "$FILES_TO_SCAN" ]; then
        echo -e "${GREEN}No staged files to scan.${NC}"
        exit 0
    fi
elif [ -n "${1:-}" ]; then
    TARGET_DIR="$1"
    if [ ! -d "$TARGET_DIR" ]; then
        echo "ERROR: Directory not found: $TARGET_DIR" >&2
        exit 2
    fi
fi

# File extensions to skip (binary, media, etc.)
EXCLUDE_PATTERNS=(
    "*.png" "*.jpg" "*.jpeg" "*.gif" "*.ico" "*.svg"
    "*.woff" "*.woff2" "*.ttf" "*.eot"
    "*.zip" "*.tar" "*.gz" "*.bz2"
    "*.pyc" "*.pyo" "*.class" "*.o" "*.so" "*.dll"
    "*.exe" "*.bin"
    "*.lock" "package-lock.json" "yarn.lock" "pnpm-lock.yaml"
    "*.min.js" "*.min.css"
)

# Directories to skip
EXCLUDE_DIRS=(
    ".git" "node_modules" "__pycache__" ".venv" "venv"
    ".pytest_cache" ".mypy_cache" ".ruff_cache"
    "dist" "build" ".next" ".nuxt"
)

# Build find exclude args
FIND_EXCLUDES=""
for dir in "${EXCLUDE_DIRS[@]}"; do
    FIND_EXCLUDES="$FIND_EXCLUDES -path '*/$dir' -prune -o"
done

FOUND_SECRETS=0
TOTAL_FINDINGS=0

# Read patterns and scan
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$line" ]] && continue

    # Split: CATEGORY | PATTERN | DESCRIPTION
    # Extract first field (category) and last field (description), middle is pattern
    category=$(echo "$line" | awk -F'|' '{print $1}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    description=$(echo "$line" | awk -F'|' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Pattern: remove first and last pipe-delimited fields
    pattern=$(echo "$line" | sed "s/^[^|]*|//;s/|[^|]*$//" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

    [ -z "$pattern" ] && continue

    # Determine grep flags: if pattern has (?i), strip it and use -i
    GREP_FLAGS="-n"
    if echo "$pattern" | grep -q '(?i)'; then
        pattern=$(echo "$pattern" | sed 's/(?i)//')
        GREP_FLAGS="-ni"
    fi

    # Scan based on mode
    MATCHES=""
    if [ "$SCAN_MODE" = "staged" ]; then
        for file in $FILES_TO_SCAN; do
            [ -f "$file" ] || continue
            # Skip binary-like extensions
            case "$file" in
                *.png|*.jpg|*.gif|*.ico|*.woff|*.pyc|*.exe|*.zip|*.lock) continue ;;
            esac
            FILE_MATCHES=$(grep $GREP_FLAGS -E -- "$pattern" "$file" 2>/dev/null || true)
            if [ -n "$FILE_MATCHES" ]; then
                while IFS= read -r line; do
                    MATCHES="${MATCHES}${file}:${line}"$'\n'
                done <<< "$FILE_MATCHES"
            fi
        done
    else
        MATCHES=$(grep -r ${GREP_FLAGS} -E -- "$pattern" "$TARGET_DIR" \
            --include="*.py" --include="*.js" --include="*.ts" --include="*.tsx" \
            --include="*.jsx" --include="*.json" --include="*.yaml" --include="*.yml" \
            --include="*.toml" --include="*.cfg" --include="*.ini" --include="*.conf" \
            --include="*.env" --include="*.env.*" --include="*.sh" --include="*.bash" \
            --include="*.sql" --include="*.html" --include="*.xml" \
            --exclude-dir=".git" --exclude-dir="node_modules" \
            --exclude-dir="__pycache__" --exclude-dir=".venv" \
            --exclude-dir=".pytest_cache" --exclude-dir=".mypy_cache" \
            --exclude="*.lock" --exclude="package-lock.json" \
            --exclude="secret-patterns.txt" \
            2>/dev/null || true)
    fi

    if [ -n "$MATCHES" ]; then
        FOUND_SECRETS=1
        while IFS= read -r match; do
            [ -z "$match" ] && continue
            TOTAL_FINDINGS=$((TOTAL_FINDINGS + 1))
            echo -e "${RED}[SECRET DETECTED]${NC} ${YELLOW}${category}${NC}: ${description}"
            echo "  $match"
            echo ""
        done <<< "$MATCHES"
    fi

done < "$PATTERNS_FILE"

# Summary
echo "---"
if [ $FOUND_SECRETS -eq 1 ]; then
    echo -e "${RED}SCAN FAILED: $TOTAL_FINDINGS potential secret(s) found.${NC}"
    echo "Fix: Use environment variables or a secrets manager. Never hardcode secrets."
    exit 1
else
    echo -e "${GREEN}SCAN PASSED: No secrets detected.${NC}"
    exit 0
fi
