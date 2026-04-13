"""
Display current instinct status.

Usage:
    python scripts/learning/instinct_status.py [project_path]
"""

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from scripts.lib.learning_manager import LearningManager


def main() -> int:
    parser = argparse.ArgumentParser(description="Show instinct status")
    parser.add_argument("project_path", nargs="?", default=".")
    args = parser.parse_args()

    lm = LearningManager(args.project_path)
    print(lm.format_status())
    return 0


if __name__ == "__main__":
    sys.exit(main())
