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

# --- Rule 1: No .ts/.tsx in backend/ ---
if echo "$FILE_PATH" | grep -qE '^backend/.*\.tsx?$'; then
    echo "BLOCKED: TypeScript files in backend/ violate FastAPI mandate. Backend MUST be Python (FastAPI)." >&2
    exit 2
fi

# --- Rule 2: No @nestjs/express in backend/package.json ---
if echo "$FILE_PATH" | grep -qE '^backend/package\.json$'; then
    if echo "$CONTENT" | grep -qiE '"@nestjs/|"express"|"typeorm"'; then
        echo "BLOCKED: backend/package.json contains prohibited dependencies (@nestjs, express, typeorm). Framework mandate: FastAPI only." >&2
        exit 2
    fi
fi

# --- Rule 3: No nest-cli.json, pom.xml, build.gradle in backend/ ---
if echo "$FILE_PATH" | grep -qE '^backend/(nest-cli\.json|pom\.xml|build\.gradle)$'; then
    echo "BLOCKED: NestJS/Java/Gradle config files in backend/ violate FastAPI mandate." >&2
    exit 2
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
