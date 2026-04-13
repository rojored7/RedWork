"""
AgentShield pattern scanner engine.

Called by audit-claude-config.sh for fast pattern matching.

Usage:
    python3 audit_scanner.py <patterns_file> <target_file> [category_filter]

Output format (pipe-delimited, one line per finding):
    CATEGORY|SEVERITY|DESCRIPTION|LINE_NUMBER
"""

import re
import sys


def main() -> int:
    if len(sys.argv) < 3:
        print("Usage: audit_scanner.py <patterns_file> <target_file> [category_filter]",
              file=sys.stderr)
        return 2

    patterns_file = sys.argv[1]
    target_file = sys.argv[2]
    cat_filter = sys.argv[3] if len(sys.argv) > 3 else ""

    # Load patterns
    # Format: CATEGORY | SEVERITY | PATTERN | DESCRIPTION
    # PATTERN may contain | (regex alternation), so we parse from edges:
    # - Field 1 (CATEGORY): everything before first |
    # - Field 2 (SEVERITY): between first and second |
    # - Field 4 (DESCRIPTION): everything after LAST |
    # - Field 3 (PATTERN): everything between second | and last |
    patterns = []
    try:
        with open(patterns_file, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = line.split("|")
                if len(parts) < 4:
                    continue
                cat = parts[0].strip()
                sev = parts[1].strip()
                # Description is always the last field
                desc = parts[-1].strip()
                # Pattern is everything between second | and last |
                pat = "|".join(parts[2:-1]).strip()
                if cat_filter and cat != cat_filter:
                    continue
                if not pat:
                    continue
                try:
                    compiled = re.compile(pat)
                    patterns.append((cat, sev, compiled, desc))
                except re.error:
                    pass
    except (OSError, IOError) as e:
        print(f"Error reading patterns: {e}", file=sys.stderr)
        return 2

    # Scan target file
    try:
        with open(target_file, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except (OSError, IOError) as e:
        print(f"Error reading target: {e}", file=sys.stderr)
        return 2

    for i, line in enumerate(lines, 1):
        for cat, sev, compiled, desc in patterns:
            if compiled.search(line):
                print(f"{cat}|{sev}|{desc}|{i}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
