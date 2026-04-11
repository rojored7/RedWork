#!/bin/bash
# RedWork Runtime Hook: PreToolUse (Bash)
# Blocks dangerous shell commands BEFORE they execute.
# Exit 0 = allow, Exit 2 = block (stderr sent to Claude)

INPUT=$(cat)

COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('command', ''))
" 2>/dev/null)

# --- Rule 1: No --no-verify (bypasses framework hooks) ---
if echo "$COMMAND" | grep -qE '\-\-no-verify'; then
    echo "BLOCKED: --no-verify bypasses framework pre-commit and post-commit hooks. The hooks enforce FastAPI mandate and sprint completeness. Never skip them." >&2
    exit 2
fi

# --- Rule 2: No force push to main/master ---
if echo "$COMMAND" | grep -qE 'git\s+push.*--force.*(main|master)'; then
    echo "BLOCKED: Force push to main/master is destructive and can lose work." >&2
    exit 2
fi

# --- Rule 3: No npm/yarn/pnpm install @nestjs ---
if echo "$COMMAND" | grep -qE '(npm|yarn|pnpm)\s+(install|add)\s+.*@nestjs'; then
    echo "BLOCKED: Installing @nestjs packages violates FastAPI mandate. Backend must use Python packages only." >&2
    exit 2
fi

# --- Rule 4: No rm -rf on protected directories ---
if echo "$COMMAND" | grep -qE 'rm\s+-rf\s+.*(\.project-state|\.framework|outputs|\.claude)'; then
    echo "BLOCKED: Deleting protected directories (.project-state, .framework, outputs, .claude) is destructive. These contain framework state and agent outputs." >&2
    exit 2
fi

# --- Rule 5: No git reset --hard (destructive) ---
if echo "$COMMAND" | grep -qE 'git\s+reset\s+--hard'; then
    echo "BLOCKED: git reset --hard discards all uncommitted changes. Use git stash if you need to save work, or git checkout for specific files." >&2
    exit 2
fi

exit 0
