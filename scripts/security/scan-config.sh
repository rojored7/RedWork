#!/bin/bash
# RedWork Configuration Security Scanner
# Validates .claude/settings.json and hook scripts for injection risks.
#
# Usage:
#   bash scan-config.sh [project_dir]
#
# Exit codes:
#   0 = clean
#   1 = issues found
#   2 = scanner error

set -euo pipefail

TARGET_DIR="${1:-.}"
FOUND_ISSUES=0
TOTAL_ISSUES=0

if [ -t 1 ]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    NC='\033[0m'
else
    RED='' YELLOW='' GREEN='' NC=''
fi

report_issue() {
    local severity="$1"
    local message="$2"
    local detail="$3"
    FOUND_ISSUES=1
    TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
    echo -e "${RED}[$severity]${NC} $message"
    echo "  $detail"
    echo ""
}

# --- Check settings.json ---
SETTINGS_FILE="$TARGET_DIR/.claude/settings.json"
if [ -f "$SETTINGS_FILE" ]; then
    echo "Scanning: $SETTINGS_FILE"

    # Check for command injection in hook commands
    # Dangerous: hooks that use unsanitized variables or pipe to shell
    if grep -qE '(eval |exec |`[^`]+`|\$\(.*\).*\|.*sh)' "$SETTINGS_FILE" 2>/dev/null; then
        report_issue "HIGH" "Potential command injection in hook commands" \
            "Found eval, exec, backtick execution, or piped shell in $SETTINGS_FILE"
    fi

    # Check for overly permissive tool permissions
    if grep -qE '"dangerouslySkipPermissions":\s*true' "$SETTINGS_FILE" 2>/dev/null; then
        report_issue "CRITICAL" "dangerouslySkipPermissions is enabled" \
            "This bypasses all safety checks. Disable immediately."
    fi

    # Check for unrestricted allowed tools
    if grep -qE '"allowedTools":\s*\["\*"\]' "$SETTINGS_FILE" 2>/dev/null; then
        report_issue "HIGH" "All tools are allowed without restriction" \
            "Restrict allowedTools to only needed tools."
    fi

    # Check hook timeout (should not be extremely long)
    TIMEOUTS=$(grep -oE '"timeout":\s*[0-9]+' "$SETTINGS_FILE" 2>/dev/null || true)
    if [ -n "$TIMEOUTS" ]; then
        while IFS= read -r timeout_match; do
            timeout_val=$(echo "$timeout_match" | grep -oE '[0-9]+')
            if [ "$timeout_val" -gt 300 ]; then
                report_issue "MEDIUM" "Hook timeout exceeds 5 minutes ($timeout_val seconds)" \
                    "Long timeouts can block the session. Keep under 300 seconds."
            fi
        done <<< "$TIMEOUTS"
    fi
else
    echo "No settings.json found at $SETTINGS_FILE (skipping)"
fi

# --- Check hook scripts ---
HOOKS_DIR="$TARGET_DIR/.claude/hooks"
if [ -d "$HOOKS_DIR" ]; then
    echo "Scanning hook scripts in: $HOOKS_DIR"

    for hook_file in "$HOOKS_DIR"/*.sh; do
        [ -f "$hook_file" ] || continue
        HOOK_NAME=$(basename "$hook_file")

        # Check for curl/wget to unknown URLs (data exfiltration risk)
        if grep -qE '(curl|wget)\s+[^#]*https?://' "$hook_file" 2>/dev/null; then
            # Allow known safe domains
            UNSAFE_URLS=$(grep -E '(curl|wget)\s+[^#]*https?://' "$hook_file" 2>/dev/null | \
                grep -vE '(localhost|127\.0\.0\.1|registry\.npmjs\.org|pypi\.org)' || true)
            if [ -n "$UNSAFE_URLS" ]; then
                report_issue "HIGH" "Hook $HOOK_NAME makes HTTP requests to external URLs" \
                    "Review: $UNSAFE_URLS"
            fi
        fi

        # Check for base64 decode (obfuscation)
        if grep -qE 'base64\s+(--decode|-d)' "$hook_file" 2>/dev/null; then
            report_issue "MEDIUM" "Hook $HOOK_NAME uses base64 decode" \
                "Obfuscated commands may hide malicious payloads."
        fi

        # Check for environment variable exfiltration
        if grep -qE '(printenv|env\b|set\b).*\|.*(curl|wget|nc|netcat)' "$hook_file" 2>/dev/null; then
            report_issue "CRITICAL" "Hook $HOOK_NAME may exfiltrate environment variables" \
                "Environment piped to network command detected."
        fi

        # Check for write to sensitive paths
        if grep -qE '>\s*/etc/|>\s*~/.ssh/|>\s*~/.aws/' "$hook_file" 2>/dev/null; then
            report_issue "HIGH" "Hook $HOOK_NAME writes to sensitive system paths" \
                "Hooks should not modify system configuration files."
        fi

        # Check for chmod 777
        if grep -qE 'chmod\s+777' "$hook_file" 2>/dev/null; then
            report_issue "MEDIUM" "Hook $HOOK_NAME uses chmod 777" \
                "World-writable permissions are a security risk."
        fi

    done
else
    echo "No hooks directory found at $HOOKS_DIR (skipping)"
fi

# --- Summary ---
echo "---"
if [ $FOUND_ISSUES -eq 1 ]; then
    echo -e "${RED}CONFIG SCAN FAILED: $TOTAL_ISSUES issue(s) found.${NC}"
    exit 1
else
    echo -e "${GREEN}CONFIG SCAN PASSED: No issues detected.${NC}"
    exit 0
fi
