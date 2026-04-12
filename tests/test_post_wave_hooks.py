"""
Tests for post-wave hook scripts.

Validates syntax, existence, and basic structure of:
- scripts/hooks/post-wave-3-backend.sh
- scripts/hooks/post-wave-4-api.sh
- scripts/hooks/post-wave-5-frontend.sh
"""

import subprocess
from pathlib import Path

import pytest

FRAMEWORK_ROOT = Path(__file__).parent.parent.resolve()
HOOKS_DIR = FRAMEWORK_ROOT / "scripts" / "hooks"


POST_WAVE_HOOKS = [
    "post-wave-3-backend.sh",
    "post-wave-4-api.sh",
    "post-wave-5-frontend.sh",
]


class TestPostWaveHooksExist:
    """Verify all post-wave hook files are present."""

    def test_all_post_wave_hooks_exist(self):
        missing = []
        for hook in POST_WAVE_HOOKS:
            if not (HOOKS_DIR / hook).exists():
                missing.append(hook)
        assert missing == [], f"Missing post-wave hooks: {missing}"

    def test_post_wave_3_exists(self):
        assert (HOOKS_DIR / "post-wave-3-backend.sh").exists()

    def test_post_wave_4_exists(self):
        assert (HOOKS_DIR / "post-wave-4-api.sh").exists()

    def test_post_wave_5_exists(self):
        assert (HOOKS_DIR / "post-wave-5-frontend.sh").exists()


class TestPostWaveHooksSyntax:
    """Validate bash syntax using bash -n (parse without execution)."""

    @pytest.mark.parametrize("hook_name", POST_WAVE_HOOKS)
    def test_post_wave_syntax_valid(self, hook_name):
        rel_path = f"scripts/hooks/{hook_name}"
        result = subprocess.run(
            ["bash", "-n", rel_path],
            capture_output=True,
            text=True,
            timeout=10,
            cwd=str(FRAMEWORK_ROOT),
        )
        assert result.returncode == 0, (
            f"Syntax error in {hook_name}:\n{result.stderr}"
        )


class TestPostWaveHooksPermissions:
    """Verify hook scripts are accessible (exist and are regular files)."""

    @pytest.mark.parametrize("hook_name", POST_WAVE_HOOKS)
    def test_post_wave_scripts_are_files(self, hook_name):
        hook_path = HOOKS_DIR / hook_name
        assert hook_path.is_file(), f"{hook_name} is not a regular file"

    @pytest.mark.parametrize("hook_name", POST_WAVE_HOOKS)
    def test_post_wave_scripts_are_not_empty(self, hook_name):
        hook_path = HOOKS_DIR / hook_name
        size = hook_path.stat().st_size
        assert size > 0, f"{hook_name} is empty (0 bytes)"


class TestPostWaveHooksContent:
    """Verify hooks reference expected report paths and structure."""

    def test_post_wave_3_creates_report_dir(self):
        content = (HOOKS_DIR / "post-wave-3-backend.sh").read_text(encoding="utf-8")
        assert ".project-orchestration" in content, (
            "post-wave-3-backend.sh should reference .project-orchestration directory"
        )
        assert "mkdir -p .project-orchestration" in content, (
            "post-wave-3-backend.sh should create .project-orchestration directory"
        )

    def test_post_wave_4_references_report_path(self):
        content = (HOOKS_DIR / "post-wave-4-api.sh").read_text(encoding="utf-8")
        assert ".project-orchestration" in content, (
            "post-wave-4-api.sh should reference .project-orchestration directory"
        )
        assert "post-wave-4-report" in content, (
            "post-wave-4-api.sh should generate a post-wave-4-report file"
        )

    def test_post_wave_5_references_report_path(self):
        content = (HOOKS_DIR / "post-wave-5-frontend.sh").read_text(encoding="utf-8")
        assert ".project-orchestration" in content, (
            "post-wave-5-frontend.sh should reference .project-orchestration directory"
        )
        assert "post-wave-5-report" in content, (
            "post-wave-5-frontend.sh should generate a post-wave-5-report file"
        )

    @pytest.mark.parametrize("hook_name", POST_WAVE_HOOKS)
    def test_all_hooks_use_set_e(self, hook_name):
        content = (HOOKS_DIR / hook_name).read_text(encoding="utf-8")
        assert "set -e" in content, (
            f"{hook_name} should use 'set -e' for error safety"
        )

    @pytest.mark.parametrize("hook_name", POST_WAVE_HOOKS)
    def test_all_hooks_have_shebang(self, hook_name):
        content = (HOOKS_DIR / hook_name).read_text(encoding="utf-8")
        assert content.startswith("#!/bin/bash"), (
            f"{hook_name} should start with #!/bin/bash shebang"
        )
