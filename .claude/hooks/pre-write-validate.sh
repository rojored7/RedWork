#!/bin/bash

# Resolve Python interpreter (Linux/macOS/Windows Git Bash).
# Sets $PYTHON_BIN; falls back to python3 if the lib is unreachable.
for _pd in "$(dirname "${BASH_SOURCE[0]}")/../lib/python-detect.sh" \
           "$(dirname "${BASH_SOURCE[0]}")/../../scripts/lib/python-detect.sh" \
           "$HOME/.claude/redwork/scripts/lib/python-detect.sh"; do
    if [ -f "$_pd" ]; then . "$_pd"; break; fi
done
[ -n "${PYTHON_BIN:-}" ] || PYTHON_BIN=python3

# RedWork Runtime Hook: PreToolUse (Write|Edit)
# Blocks prohibited file writes BEFORE they happen.
# Exit 0 = allow, Exit 2 = block (stderr sent to Claude)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null)

CONTENT=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('content', ti.get('new_string', '')))
" 2>/dev/null)

# Normalize path: remove leading ./ and CWD prefix
FILE_PATH=$(echo "$FILE_PATH" | sed 's|^\./||' | sed "s|^$(pwd)/||")

# --- Read stack from state.json (default: fastapi) ---
BACKEND_STACK="fastapi"
if [ -f ".project-state/state.json" ]; then
    DECLARED=$("$PYTHON_BIN" -c "
import json
try:
    with open('.project-state/state.json') as f:
        print(json.load(f).get('stack',{}).get('backend','fastapi'))
except: print('fastapi')
" 2>/dev/null)
    if [ -n "$DECLARED" ]; then
        BACKEND_STACK="$DECLARED"
    fi
fi

# --- Stack-specific rules only apply to the declared stack ---
if [ "$BACKEND_STACK" = "fastapi" ] || [ "$BACKEND_STACK" = "django" ]; then
    # Python backend: no TypeScript files
    if echo "$FILE_PATH" | grep -qE '^backend/.*\.tsx?$'; then
        echo "BLOCKED: TypeScript files in backend/ violate $BACKEND_STACK mandate. Backend MUST be Python." >&2
        exit 2
    fi

    if echo "$FILE_PATH" | grep -qE '^backend/package\.json$'; then
        if echo "$CONTENT" | grep -qiE '"@nestjs/|"express"|"typeorm"'; then
            echo "BLOCKED: backend/package.json contains prohibited dependencies. Stack is $BACKEND_STACK (Python)." >&2
            exit 2
        fi
    fi

    if echo "$FILE_PATH" | grep -qE '^backend/(nest-cli\.json|pom\.xml|build\.gradle)$'; then
        echo "BLOCKED: NestJS/Java/Gradle config files in backend/ violate $BACKEND_STACK mandate." >&2
        exit 2
    fi
fi

# --- Rule 4: No direct .project-state/ edits ---
if echo "$FILE_PATH" | grep -qE '^\.project-state/'; then
    echo "BLOCKED: Do not modify .project-state/ directly. Use auto-commit-task.sh to update task state." >&2
    exit 2
fi

# --- Rule 5: No direct .git/hooks/ edits ---
if echo "$FILE_PATH" | grep -qE '^\.git/hooks/'; then
    echo "BLOCKED: Do not modify .git/hooks/ directly. Use install-workflow-hooks.sh to manage git hooks." >&2
    exit 2
fi

# --- Rule 6: No secrets in file content ---
# Skip secret scanning for test fixtures, security test files, and pattern definitions
if echo "$FILE_PATH" | grep -qiE '(tests/fixtures/security|test_security|secret-patterns)'; then
    exit 0
fi
# Also check the original (non-normalized) path
ORIG_PATH=$(echo "$INPUT" | "$PYTHON_BIN" -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null)
if echo "$ORIG_PATH" | grep -qiE '(tests/fixtures/security|test_security|secret-patterns)'; then
    exit 0
fi
if [ -n "$CONTENT" ]; then
    if echo "$CONTENT" | grep -qE 'AKIA[0-9A-Z]{16}'; then
        echo "BLOCKED: AWS Access Key detected in file content. Use environment variables or a secrets manager." >&2
        exit 2
    fi
    if echo "$CONTENT" | grep -qE '\-\-\-\-\-BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY\-\-\-\-\-'; then
        echo "BLOCKED: Private key detected in file content. Never commit private keys to source control." >&2
        exit 2
    fi
    if echo "$CONTENT" | grep -qE 'sk_live_[A-Za-z0-9]{24,}'; then
        echo "BLOCKED: Stripe live secret key detected. Use environment variables." >&2
        exit 2
    fi
    if echo "$CONTENT" | grep -qE 'ghp_[A-Za-z0-9]{36,}'; then
        echo "BLOCKED: GitHub personal access token detected. Use environment variables." >&2
        exit 2
    fi
    if echo "$CONTENT" | grep -qE 'glpat-[A-Za-z0-9_-]{20,}'; then
        echo "BLOCKED: GitLab personal access token detected. Use environment variables." >&2
        exit 2
    fi
fi

exit 0
