#!/bin/bash
# RedWork Runtime Hook: PreToolUse (Write|Edit)
# Blocks prohibited file writes BEFORE they happen.
# Exit 0 = allow, Exit 2 = block (stderr sent to Claude)

INPUT=$(cat)

FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', ti.get('filePath', '')))
" 2>/dev/null)

CONTENT=$(echo "$INPUT" | python3 -c "
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
    DECLARED=$(python3 -c "
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

exit 0
