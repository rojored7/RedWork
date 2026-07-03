"""
sweep_references.py - Mechanical reference sweeps for the RedWork content layer.

Two jobs:
  --apply : run the declared exact-string replacements (idempotent).
  --check : exit 1 if any forbidden pattern is still present (used by tests/CI).

Replacements are exact strings (never blind number seds); anything contextual
is fixed by hand and only *guarded* here via forbidden patterns.
"""

import argparse
import re
import sys
from pathlib import Path

# Windows consoles default to cp1252; agent files contain unicode
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent.parent

# (exact_old, new, glob) — applied literally, all occurrences
REPLACEMENTS = [
    ("framework/skills/", "~/.claude/redwork/skills/", "agents/*.md"),
    ("framework/skills/", "~/.claude/redwork/skills/", "skills/README.md"),
    ("`framework/skills`", "`~/.claude/redwork/skills`", "agents/*.md"),
]

# (regex, description, globs, allowlist_substrings)
FORBIDDEN = [
    (r"framework/skills", "phantom skills path",
     ["agents/**/*.md", "skills/**/*.md", "commands/*.md", "rules/**/*.md"],
     ["CHANGELOG"]),
    (r"~/\.config/claude", "phantom claude config path",
     ["agents/**/*.md", "commands/*.md"], ["CHANGELOG"]),
    (r"workflow-orchestrator", "dead subsystem reference",
     ["agents/**/*.md", "commands/*.md", "skills/**/*.md", "learning/**/*.md",
      "scripts/**/*.py", "scripts/**/*.sh", "README.md", "CLAUDE.md"],
     ["CHANGELOG", "sweep_references"]),
    (r"\b05c\b", "v1 agent id 05c (now 10)",
     ["agents/**/*.md", "commands/*.md", "skills/**/*.md", "README.md",
      "CLAUDE.md", ".gitlab-ci.yml"], ["CHANGELOG", "rename_agents"]),
    (r"\b09b\b", "v1 agent id 09b (now 11)",
     ["agents/**/*.md", "commands/*.md", "skills/**/*.md", "README.md",
      "CLAUDE.md", ".gitlab-ci.yml"], ["CHANGELOG", "rename_agents"]),
    (r"Agent 10 \((?:Backend|backend)", "v1 numbering: Agent 10 as backend dev",
     ["**/*.md"], ["CHANGELOG"]),
    (r"Agent 11 \((?:Frontend|frontend)", "v1 numbering: Agent 11 as frontend dev",
     ["**/*.md"], ["CHANGELOG"]),
]


def _iter_files(globs):
    seen = set()
    for pattern in globs:
        for path in ROOT.glob(pattern):
            if path.is_file() and path not in seen:
                seen.add(path)
                yield path


def cmd_apply() -> int:
    changed = 0
    for old, new, glob in REPLACEMENTS:
        for path in _iter_files([glob]):
            text = path.read_text(encoding="utf-8")
            if old in text:
                path.write_text(text.replace(old, new), encoding="utf-8",
                                newline="\n")
                count = text.count(old)
                print(f"APPLIED {path.relative_to(ROOT)}: {count}x '{old}'")
                changed += count
    print(f"\n{changed} replacements applied")
    return 0


def cmd_check() -> int:
    hits = []
    for regex, desc, globs, allow in FORBIDDEN:
        pattern = re.compile(regex)
        for path in _iter_files(globs):
            rel = str(path.relative_to(ROOT))
            if any(a in rel for a in allow):
                continue
            for lineno, line in enumerate(
                path.read_text(encoding="utf-8", errors="replace").splitlines(), 1
            ):
                if pattern.search(line):
                    hits.append(f"{rel}:{lineno}: [{desc}] {line.strip()[:100]}")
    if hits:
        print("FORBIDDEN references found:")
        print("\n".join(hits))
        print(f"\n{len(hits)} hits")
        return 1
    print("CHECK PASSED: no forbidden references")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--apply", action="store_true")
    mode.add_argument("--check", action="store_true")
    args = parser.parse_args()
    sys.exit(cmd_apply() if args.apply else cmd_check())
