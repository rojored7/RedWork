# Makefile.workflow
#
# Helper commands for workflow-orchestrator agent
# Include this in your main Makefile or use directly
#
# Usage:
#   make -f Makefile.workflow workflow-init
#   make -f Makefile.workflow workflow-baseline
#   make -f Makefile.workflow workflow-regression

.PHONY: help workflow-init workflow-baseline workflow-regression workflow-feature workflow-fix workflow-validate-arch workflow-visual workflow-compare

# Colors for output
COLOR_BLUE := \033[0;34m
COLOR_GREEN := \033[0;32m
COLOR_YELLOW := \033[1;33m
COLOR_RED := \033[0;31m
COLOR_RESET := \033[0m

help:
	@echo "$(COLOR_BLUE)Workflow System Commands$(COLOR_RESET)"
	@echo ""
	@echo "$(COLOR_GREEN)Setup:$(COLOR_RESET)"
	@echo "  workflow-init          - Initialize project with workflow system"
	@echo ""
	@echo "$(COLOR_GREEN)Workflows:$(COLOR_RESET)"
	@echo "  workflow-feature       - Execute full feature workflow (with approvals)"
	@echo "  workflow-fix           - Execute fast fix workflow (automatic)"
	@echo ""
	@echo "$(COLOR_GREEN)Individual Skills:$(COLOR_RESET)"
	@echo "  workflow-baseline      - Capture current project baseline"
	@echo "  workflow-regression    - Run regression testing"
	@echo "  workflow-compare       - Compare current state vs baseline"
	@echo "  workflow-validate-arch - Validate architecture rules (CAS)"
	@echo "  workflow-visual        - Visual validation with Playwright MCP"
	@echo ""
	@echo "$(COLOR_GREEN)Utilities:$(COLOR_RESET)"
	@echo "  workflow-status        - Show workflow system status"
	@echo "  workflow-clean         - Clean temporary files"
	@echo ""
	@echo "$(COLOR_YELLOW)Note:$(COLOR_RESET) These commands invoke the workflow-orchestrator agent."
	@echo "      You must be in a Claude Code session to use them."

workflow-init:
	@echo "$(COLOR_BLUE)🎬 Initializing Workflow System...$(COLOR_RESET)"
	@echo ""
	@echo "This will:"
	@echo "  • Detect project type and frameworks"
	@echo "  • Create directory structure (.baselines/, .checkpoints/, reports/)"
	@echo "  • Copy templates (smoke-tests, arch-rules, config)"
	@echo "  • Capture initial baseline"
	@echo "  • Generate usage guide"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 08-init-project$(COLOR_RESET)"

workflow-baseline:
	@echo "$(COLOR_BLUE)📸 Capturing Baseline...$(COLOR_RESET)"
	@echo ""
	@echo "This will:"
	@echo "  • Run all backend tests (if exists)"
	@echo "  • Run all frontend tests (if exists)"
	@echo "  • Calculate coverage"
	@echo "  • Save state to .baselines/latest.json"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 01-capture-baseline$(COLOR_RESET)"

workflow-regression:
	@echo "$(COLOR_RED)🔄 Running Regression Testing...$(COLOR_RESET)"
	@echo ""
	@echo "This will:"
	@echo "  • Load baseline from .baselines/latest.json"
	@echo "  • Run ALL tests (backend + frontend)"
	@echo "  • Compare results with baseline"
	@echo "  • ⛔ BLOCK if any old test breaks"
	@echo "  • Generate regression report"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 04-run-regression$(COLOR_RESET)"

workflow-feature:
	@echo "$(COLOR_GREEN)✨ Starting Feature Workflow...$(COLOR_RESET)"
	@echo ""
	@echo "This will execute the FULL workflow:"
	@echo "  FASE 0: Capture baseline (automatic)"
	@echo "  FASE 1: Docker/Infra (if needed, with approval)"
	@echo "  FASE 2: Backend implementation (with approval)"
	@echo "  FASE 3: Frontend implementation (with approval)"
	@echo "  FASE 4: Regression testing (⛔ blocks if fails)"
	@echo "  FASE 5: Baseline comparison"
	@echo "  FASE 6: Visual validation"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 02-orchestrate-feature$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Or simply say: \"Implement [feature name]\"$(COLOR_RESET)"

workflow-fix:
	@echo "$(COLOR_GREEN)🔧 Starting Fix Workflow...$(COLOR_RESET)"
	@echo ""
	@echo "This will execute the FAST workflow (no approval gates):"
	@echo "  • Capture baseline (automatic)"
	@echo "  • Backend changes (automatic)"
	@echo "  • Frontend changes (automatic)"
	@echo "  • Regression testing (⛔ blocks if fails)"
	@echo "  • Report"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 03-orchestrate-fix$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)Or simply say: \"Fix [bug description]\"$(COLOR_RESET)"

workflow-compare:
	@echo "$(COLOR_BLUE)📊 Comparing with Baseline...$(COLOR_RESET)"
	@echo ""
	@echo "This will:"
	@echo "  • Load baseline from .baselines/latest.json"
	@echo "  • Capture current state"
	@echo "  • Generate before/after comparison table"
	@echo "  • Show test count changes, coverage changes"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 05-compare-baseline$(COLOR_RESET)"

workflow-validate-arch:
	@echo "$(COLOR_BLUE)🏛️  Validating Architecture...$(COLOR_RESET)"
	@echo ""
	@echo "This will check:"
	@echo "  • Layering rules (Controllers → Services → Repositories)"
	@echo "  • Naming conventions (kebab-case, PascalCase)"
	@echo "  • Circular dependencies"
	@echo "  • Import order"
	@echo "  • File organization"
	@echo ""
	@echo "$(COLOR_YELLOW)Mode: Advisory (warnings only, doesn't block)$(COLOR_RESET)"
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 06-validate-architecture$(COLOR_RESET)"

workflow-visual:
	@echo "$(COLOR_BLUE)📸 Visual Validation...$(COLOR_RESET)"
	@echo ""
	@echo "This will:"
	@echo "  • Navigate to affected pages with Playwright MCP"
	@echo "  • Verify components render correctly"
	@echo "  • Check for console errors"
	@echo "  • Capture screenshots"
	@echo "  • Compare with visual baselines (if exist)"
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Invoke workflow-orchestrator agent with skill 07-visual-validation$(COLOR_RESET)"

workflow-status:
	@echo "$(COLOR_BLUE)📊 Workflow System Status$(COLOR_RESET)"
	@echo ""
	@if [ -d ".baselines" ]; then \
		echo "$(COLOR_GREEN)✅ Baselines directory exists$(COLOR_RESET)"; \
		if [ -f ".baselines/latest.json" ]; then \
			echo "   Latest baseline: $$(stat -f%Sm -t '%Y-%m-%d %H:%M:%S' .baselines/latest.json 2>/dev/null || stat -c %y .baselines/latest.json 2>/dev/null | cut -d'.' -f1)"; \
		else \
			echo "$(COLOR_YELLOW)   ⚠️  No baseline captured yet$(COLOR_RESET)"; \
		fi \
	else \
		echo "$(COLOR_RED)❌ Baselines directory missing$(COLOR_RESET)"; \
	fi
	@echo ""
	@if [ -d ".checkpoints" ]; then \
		echo "$(COLOR_GREEN)✅ Checkpoints directory exists$(COLOR_RESET)"; \
		CHECKPOINT_COUNT=$$(ls -1 .checkpoints/*.md 2>/dev/null | wc -l); \
		echo "   Checkpoints: $$CHECKPOINT_COUNT files"; \
	else \
		echo "$(COLOR_RED)❌ Checkpoints directory missing$(COLOR_RESET)"; \
	fi
	@echo ""
	@if [ -f ".workflow-config.json" ]; then \
		echo "$(COLOR_GREEN)✅ Workflow config exists$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠️  No workflow config (run workflow-init)$(COLOR_RESET)"; \
	fi
	@echo ""
	@if [ -f ".arch-rules.ts" ]; then \
		echo "$(COLOR_GREEN)✅ Architecture rules configured$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_YELLOW)⚠️  No architecture rules$(COLOR_RESET)"; \
	fi

workflow-clean:
	@echo "$(COLOR_YELLOW)🧹 Cleaning Workflow Artifacts...$(COLOR_RESET)"
	@rm -f temp-*-results.json
	@rm -rf .checkpoints/*.md.tmp
	@echo "$(COLOR_GREEN)✅ Cleanup complete$(COLOR_RESET)"

workflow-clean-all:
	@echo "$(COLOR_RED)⚠️  WARNING: This will delete ALL workflow data$(COLOR_RESET)"
	@echo "   - .baselines/"
	@echo "   - .checkpoints/"
	@echo "   - reports/"
	@echo ""
	@read -p "Are you sure? (y/N): " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf .baselines .checkpoints reports; \
		echo "$(COLOR_GREEN)✅ All workflow data deleted$(COLOR_RESET)"; \
	else \
		echo "$(COLOR_BLUE)Cancelled$(COLOR_RESET)"; \
	fi

# Development helpers
workflow-test-docker:
	@echo "$(COLOR_BLUE)🐳 Testing Docker services...$(COLOR_RESET)"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "backend|frontend|postgres|redis" || echo "$(COLOR_YELLOW)No services running$(COLOR_RESET)"

workflow-logs-backend:
	@docker logs --tail 50 ciber-backend 2>/dev/null || echo "$(COLOR_RED)Backend container not running$(COLOR_RESET)"

workflow-logs-frontend:
	@docker logs --tail 50 ciber-frontend 2>/dev/null || echo "$(COLOR_RED)Frontend container not running$(COLOR_RESET)"

# Quick commands for common scenarios
quick-feature:
	@echo "$(COLOR_GREEN)🚀 Quick Feature Implementation$(COLOR_RESET)"
	@echo ""
	@echo "In Claude Code, say:"
	@echo "  $(COLOR_YELLOW)\"Implement [your feature description]\"$(COLOR_RESET)"
	@echo ""
	@echo "The orchestrator will automatically:"
	@echo "  1. Capture baseline"
	@echo "  2. Coordinate agents (docker, backend, frontend)"
	@echo "  3. Run regression tests"
	@echo "  4. Visual validation"
	@echo "  5. Generate report"

quick-fix:
	@echo "$(COLOR_GREEN)⚡ Quick Fix Implementation$(COLOR_RESET)"
	@echo ""
	@echo "In Claude Code, say:"
	@echo "  $(COLOR_YELLOW)\"Fix [bug description]\"$(COLOR_RESET)"
	@echo ""
	@echo "The orchestrator will automatically:"
	@echo "  1. Capture baseline"
	@echo "  2. Make backend/frontend changes"
	@echo "  3. Run regression tests"
	@echo "  4. Report results"
	@echo ""
	@echo "$(COLOR_BLUE)Fast mode: No approval gates$(COLOR_RESET)"

# Install/Update workflow system
workflow-update:
	@echo "$(COLOR_BLUE)🔄 Updating Workflow System...$(COLOR_RESET)"
	@echo ""
	@echo "This will update templates from the latest version."
	@echo "Your .workflow-config.json will NOT be overwritten."
	@echo ""
	@echo "$(COLOR_YELLOW)To execute: Re-run skill 08-init-project with update mode$(COLOR_RESET)"
