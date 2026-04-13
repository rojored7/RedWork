#!/bin/bash
# RedWork AgentShield - Claude Configuration Security Auditor
# Scans 5 configuration domains for security risks using pattern matching.
#
# Usage:
#   bash audit-claude-config.sh [target_dir]
#   bash audit-claude-config.sh [target_dir] --json     # Machine-readable output
#   bash audit-claude-config.sh [target_dir] --ci       # Exit 1 on HIGH+
#
# Domains scanned:
#   1. settings.json (permissions, hook commands)
#   2. hooks/ scripts (injection vectors, exfiltration)
#   3. CLAUDE.md files (prompt injection)
#   4. MCP config (mcp.json, risky servers)
#   5. agents/*.md (dangerous instructions)
#
# Exit codes:
#   0 = clean or LOW/MEDIUM only
#   1 = HIGH or CRITICAL findings
#   2 = scanner error

set -uo pipefail

TARGET_DIR="${1:-.}"
OUTPUT_MODE="text"
CI_MODE=0

# Parse flags
for arg in "$@"; do
    case "$arg" in
        --json) OUTPUT_MODE="json" ;;
        --ci)   CI_MODE=1 ;;
    esac
done

# Resolve patterns file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATTERNS_FILE="${CONFIG_AUDIT_PATTERNS:-$SCRIPT_DIR/config-audit-patterns.txt}"

if [ ! -f "$PATTERNS_FILE" ]; then
    echo "ERROR: Patterns file not found: $PATTERNS_FILE" >&2
    exit 2
fi

# Colors (only for terminal)
if [ -t 1 ] && [ "$OUTPUT_MODE" = "text" ]; then
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    GREEN='\033[0;32m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' YELLOW='' GREEN='' CYAN='' BOLD='' NC=''
fi

# Temp file for findings (avoids subshell variable loss from pipes)
FINDINGS_FILE=$(mktemp)
trap "rm -f '$FINDINGS_FILE'" EXIT

# Source type weights for scoring
weight_for_source() {
    local file="$1"
    case "$file" in
        *settings.json|*mcp.json|*.claude.json)
            echo "1.0" ;;
        *settings.local.json)
            echo "0.75" ;;
        *hooks.json|*plugin*)
            echo "0.5" ;;
        *template*|*example*|*fixture*|*test*)
            echo "0.25" ;;
        *docs/*|*README*|*CHANGELOG*)
            echo "0.25" ;;
        *)
            echo "0.8" ;;
    esac
}

severity_color() {
    case "$1" in
        CRITICAL) echo "$RED" ;;
        HIGH)     echo "$RED" ;;
        MEDIUM)   echo "$YELLOW" ;;
        LOW)      echo "$GREEN" ;;
        *)        echo "$NC" ;;
    esac
}

record_finding() {
    local category="$1"
    local severity="$2"
    local description="$3"
    local file="$4"
    local line_num="${5:-0}"

    # Append to findings file (survives subshell)
    echo "$severity" >> "$FINDINGS_FILE"

    if [ "$OUTPUT_MODE" = "text" ]; then
        local color
        color=$(severity_color "$severity")
        echo -e "  ${color}[$severity]${NC} ${BOLD}$category${NC}: $description"
        echo -e "    File: $file${line_num:+ (line $line_num)}"
    fi
}

scan_file_with_patterns() {
    local file="$1"
    local category_filter="${2:-}"

    if [ ! -f "$file" ]; then
        return
    fi

    # Use Python scanner for fast pattern matching
    local scanner="$SCRIPT_DIR/audit_scanner.py"
    python3 "$scanner" "$PATTERNS_FILE" "$file" "$category_filter" 2>/dev/null | while IFS='|' read -r cat sev desc lnum; do
        record_finding "$cat" "$sev" "$desc" "$file" "$lnum"
    done
}

# ============================================================================
# DOMAIN 1: Settings files
# ============================================================================
scan_settings() {
    local header_shown=0

    for settings_file in \
        "$TARGET_DIR/.claude/settings.json" \
        "$TARGET_DIR/.claude/settings.local.json" \
        "$TARGET_DIR/.claude.json"; do

        if [ -f "$settings_file" ]; then
            if [ "$header_shown" -eq 0 ] && [ "$OUTPUT_MODE" = "text" ]; then
                echo -e "\n${CYAN}[Domain 1] Settings files${NC}"
                header_shown=1
            fi
            scan_file_with_patterns "$settings_file" "PERM"
        fi
    done
}

# ============================================================================
# DOMAIN 2: Hook scripts
# ============================================================================
scan_hooks() {
    local header_shown=0

    for hooks_dir in \
        "$TARGET_DIR/.claude/hooks"; do

        if [ -d "$hooks_dir" ]; then
            if [ "$header_shown" -eq 0 ] && [ "$OUTPUT_MODE" = "text" ]; then
                echo -e "\n${CYAN}[Domain 2] Hook scripts${NC}"
                header_shown=1
            fi
            for hook_file in "$hooks_dir"/*.sh "$hooks_dir"/*.js "$hooks_dir"/*.py; do
                [ -f "$hook_file" ] && scan_file_with_patterns "$hook_file" "HOOK"
            done
        fi
    done
}

# ============================================================================
# DOMAIN 3: CLAUDE.md files (prompt injection)
# ============================================================================
scan_claude_md() {
    local header_shown=0

    for md_file in \
        "$TARGET_DIR/CLAUDE.md" \
        "$TARGET_DIR/.claude/CLAUDE.md"; do

        if [ -f "$md_file" ]; then
            if [ "$header_shown" -eq 0 ] && [ "$OUTPUT_MODE" = "text" ]; then
                echo -e "\n${CYAN}[Domain 3] CLAUDE.md files${NC}"
                header_shown=1
            fi
            scan_file_with_patterns "$md_file" "INJECTION"
        fi
    done
}

# ============================================================================
# DOMAIN 4: MCP configuration
# ============================================================================
scan_mcp_config() {
    local header_shown=0

    for mcp_file in \
        "$TARGET_DIR/.mcp.json" \
        "$TARGET_DIR/.claude/mcp.json"; do

        if [ -f "$mcp_file" ]; then
            if [ "$header_shown" -eq 0 ] && [ "$OUTPUT_MODE" = "text" ]; then
                echo -e "\n${CYAN}[Domain 4] MCP configuration${NC}"
                header_shown=1
            fi
            scan_file_with_patterns "$mcp_file" "MCP"
        fi
    done
}

# ============================================================================
# DOMAIN 5: Agent definitions
# ============================================================================
scan_agents() {
    local header_shown=0
    local agents_dir="$TARGET_DIR/agents"

    for dir in "$agents_dir"; do
        if [ -d "$dir" ]; then
            if [ "$header_shown" -eq 0 ] && [ "$OUTPUT_MODE" = "text" ]; then
                echo -e "\n${CYAN}[Domain 5] Agent definitions${NC}"
                header_shown=1
            fi
            for agent_file in "$dir"/*.md; do
                [ -f "$agent_file" ] && scan_file_with_patterns "$agent_file" "AGENT"
            done
        fi
    done
}

# ============================================================================
# MAIN
# ============================================================================

if [ "$OUTPUT_MODE" = "text" ]; then
    echo -e "${BOLD}RedWork AgentShield - Configuration Security Audit${NC}"
    echo "Target: $TARGET_DIR"
    echo "Patterns: $PATTERNS_FILE"
fi

# Run all domain scans
scan_settings
scan_hooks
scan_claude_md
scan_mcp_config
scan_agents

# ============================================================================
# REPORT - Count findings from temp file
# ============================================================================

TOTAL_FINDINGS=0
CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
LOW_COUNT=0

if [ -f "$FINDINGS_FILE" ] && [ -s "$FINDINGS_FILE" ]; then
    TOTAL_FINDINGS=$(wc -l < "$FINDINGS_FILE" | tr -d '[:space:]')
    CRITICAL_COUNT=$(grep -c "^CRITICAL$" "$FINDINGS_FILE" 2>/dev/null | tr -d '[:space:]' || true)
    HIGH_COUNT=$(grep -c "^HIGH$" "$FINDINGS_FILE" 2>/dev/null | tr -d '[:space:]' || true)
    MEDIUM_COUNT=$(grep -c "^MEDIUM$" "$FINDINGS_FILE" 2>/dev/null | tr -d '[:space:]' || true)
    LOW_COUNT=$(grep -c "^LOW$" "$FINDINGS_FILE" 2>/dev/null | tr -d '[:space:]' || true)
    # Ensure numeric values (grep -c returns empty on no match in some shells)
    CRITICAL_COUNT=${CRITICAL_COUNT:-0}
    HIGH_COUNT=${HIGH_COUNT:-0}
    MEDIUM_COUNT=${MEDIUM_COUNT:-0}
    LOW_COUNT=${LOW_COUNT:-0}
fi

if [ "$OUTPUT_MODE" = "text" ]; then
    echo ""
    echo -e "${BOLD}--- Summary ---${NC}"
    echo "Total findings: $TOTAL_FINDINGS"

    if [ "$CRITICAL_COUNT" -gt 0 ]; then
        echo -e "  ${RED}CRITICAL: $CRITICAL_COUNT${NC}"
    fi
    if [ "$HIGH_COUNT" -gt 0 ]; then
        echo -e "  ${RED}HIGH: $HIGH_COUNT${NC}"
    fi
    if [ "$MEDIUM_COUNT" -gt 0 ]; then
        echo -e "  ${YELLOW}MEDIUM: $MEDIUM_COUNT${NC}"
    fi
    if [ "$LOW_COUNT" -gt 0 ]; then
        echo -e "  ${GREEN}LOW: $LOW_COUNT${NC}"
    fi

    if [ "$TOTAL_FINDINGS" -eq 0 ]; then
        echo -e "${GREEN}No security issues found.${NC}"
    fi
fi

if [ "$OUTPUT_MODE" = "json" ]; then
    AUDIT_TARGET="$TARGET_DIR" \
    AUDIT_TOTAL="$TOTAL_FINDINGS" \
    AUDIT_CRITICAL="$CRITICAL_COUNT" \
    AUDIT_HIGH="$HIGH_COUNT" \
    AUDIT_MEDIUM="$MEDIUM_COUNT" \
    AUDIT_LOW="$LOW_COUNT" \
    python3 -c "
import json, os
t = int(os.environ.get('AUDIT_TOTAL', 0))
c = int(os.environ.get('AUDIT_CRITICAL', 0))
h = int(os.environ.get('AUDIT_HIGH', 0))
report = {
    'target': os.environ.get('AUDIT_TARGET', '.'),
    'total_findings': t,
    'critical': c,
    'high': h,
    'medium': int(os.environ.get('AUDIT_MEDIUM', 0)),
    'low': int(os.environ.get('AUDIT_LOW', 0)),
    'status': 'FAIL' if (c + h) > 0 else 'PASS',
}
print(json.dumps(report, indent=2))
"
fi

# Exit code
if [ "$CI_MODE" -eq 1 ] || [ "$CRITICAL_COUNT" -gt 0 ]; then
    if [ "$CRITICAL_COUNT" -gt 0 ] || [ "$HIGH_COUNT" -gt 0 ]; then
        exit 1
    fi
fi

exit 0
