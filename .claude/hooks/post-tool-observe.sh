#!/bin/bash
# RedWork Runtime Hook: PostToolUse (all tools)
# Captures tool observations for the learning system.
# Appends one line to .learning/observations.jsonl.
# NEVER blocks (exit 0 always). Must be fast (<50ms).

INPUT=$(cat)

# Only capture if .learning/ directory exists (learning system active)
CWD=$(echo "$INPUT" | python3 -c "
import sys, json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null || pwd)
cd "$CWD" 2>/dev/null || true

if [ ! -d ".learning" ]; then
    exit 0
fi

# Extract tool name and input summary, append to JSONL
python3 -c "
import sys, json, os
from datetime import datetime, timezone

try:
    data = json.loads(sys.stdin.read())
except (json.JSONDecodeError, Exception):
    sys.exit(0)

tool_name = data.get('tool_name', 'unknown')
tool_input = data.get('tool_input', {})
tool_result = data.get('tool_result', '')

# Build a short input summary
input_summary = ''
if isinstance(tool_input, dict):
    fp = tool_input.get('file_path', tool_input.get('filePath', ''))
    cmd = tool_input.get('command', '')
    pattern = tool_input.get('pattern', '')
    if fp:
        input_summary = fp[-100:]
    elif cmd:
        input_summary = cmd[:100]
    elif pattern:
        input_summary = pattern[:100]
    else:
        input_summary = str(tool_input)[:100]
else:
    input_summary = str(tool_input)[:100]

# Build output summary (truncated)
output_summary = ''
if isinstance(tool_result, str):
    output_summary = tool_result[:200]
elif isinstance(tool_result, dict):
    output_summary = str(tool_result)[:200]

record = {
    'tool': tool_name,
    'input': input_summary,
    'output': output_summary,
    'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
}

obs_file = os.path.join('.learning', 'observations.jsonl')
with open(obs_file, 'a', encoding='utf-8') as f:
    f.write(json.dumps(record) + '\n')
" <<< "$INPUT" 2>/dev/null

exit 0
