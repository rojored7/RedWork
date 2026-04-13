#!/bin/bash
# A clean hook with no dangerous patterns
INPUT=$(cat)
echo "Hook executed" >&2
exit 0
