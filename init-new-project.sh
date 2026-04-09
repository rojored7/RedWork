#!/bin/bash
# Framework Initialization Script
# Creates a new project with complete framework setup

set -e

echo "=========================================="
echo "Framework Project Initialization"
echo "=========================================="
echo ""

# Check if project name provided
if [ -z "$1" ]; then
    echo "ERROR: Project name required"
    echo ""
    echo "Usage: bash init-new-project.sh <project-name>"
    echo ""
    echo "Example:"
    echo "  bash init-new-project.sh lms-project"
    echo ""
    exit 1
fi

PROJECT_NAME=$1
PROJECT_PATH="../$PROJECT_NAME"
FRAMEWORK_PATH=$(pwd)

# Check if project already exists
if [ -d "$PROJECT_PATH" ]; then
    echo "ERROR: Project directory already exists: $PROJECT_PATH"
    echo "Please choose a different name or remove the existing directory"
    exit 1
fi

echo "Creating new project: $PROJECT_NAME"
echo "Location: $PROJECT_PATH"
echo ""

# Create project structure
echo "Step 1: Creating project structure..."
mkdir -p "$PROJECT_PATH"
mkdir -p "$PROJECT_PATH/.framework"
mkdir -p "$PROJECT_PATH/outputs"
mkdir -p "$PROJECT_PATH/backend"
mkdir -p "$PROJECT_PATH/frontend"
mkdir -p "$PROJECT_PATH/docs"
echo "✓ Project directories created"
echo ""

# Copy framework files
echo "Step 2: Copying framework files..."
cp -r agents "$PROJECT_PATH/.framework/"
cp -r scripts "$PROJECT_PATH/.framework/"
cp -r skills "$PROJECT_PATH/.framework/"

# Copy .project-state-templates for Agent 25 task initialization
if [ -d .project-state-templates ]; then
    cp -r .project-state-templates "$PROJECT_PATH/.framework/"
fi

# Copy workflow-status.json template
if [ -f workflow-status.json ]; then
    cp workflow-status.json "$PROJECT_PATH/"
fi

# Copy pipeline v3.0 (parent-child architecture)
cp .gitlab-ci.yml "$PROJECT_PATH/"

# Copy child pipeline definitions (parent-child architecture)
if [ -d .gitlab/ci ]; then
    mkdir -p "$PROJECT_PATH/.gitlab/ci"
    cp .gitlab/ci/*.yml "$PROJECT_PATH/.gitlab/ci/"
fi

# Copy critical scripts to project root scripts/ for CI access
# These must be accessible outside .framework/ since .framework/ is gitignored
mkdir -p "$PROJECT_PATH/scripts/workflow"
mkdir -p "$PROJECT_PATH/scripts/hooks"

# Workflow scripts for CI and manual use
for script in \
    validate-no-nestjs-contamination.sh \
    validate-sprint-completeness.sh \
    auto-commit-task.sh \
    update-workflow-status.sh \
    resume-development.sh \
    pipeline-helper.sh \
    validate-agent-00.sh \
    validate-agent-01.sh \
    validate-agent-02.sh \
    validate-agent-03.sh \
    validate-agent-04.sh \
    validate-agent-05.sh \
    validate-agent-06bis.sh \
    validate-agent-07bis.sh \
    validate-agent-22.sh \
    validate-agent-23.sh \
    validate-agent-24.sh \
    validate-git-setup.sh; do
    cp "scripts/workflow/$script" "$PROJECT_PATH/scripts/workflow/" 2>/dev/null || true
done

# Post-wave hooks for CI and Agent 25
for hook in \
    post-wave-3-backend.sh \
    post-wave-4-api.sh \
    post-wave-5-frontend.sh \
    post-commit-workflow; do
    cp "scripts/hooks/$hook" "$PROJECT_PATH/scripts/hooks/" 2>/dev/null || true
done

# Hook installer (needs to be accessible from project root too)
cp scripts/install-workflow-hooks.sh "$PROJECT_PATH/scripts/" 2>/dev/null || true

chmod +x "$PROJECT_PATH/scripts/workflow/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/scripts/hooks/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/scripts/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/.framework/scripts/workflow/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/.framework/scripts/hooks/"*.sh 2>/dev/null || true
chmod +x "$PROJECT_PATH/.framework/scripts/"*.sh 2>/dev/null || true

echo "  OK - Framework files copied (agents + scripts + skills)"
echo "  OK - Pipeline .gitlab-ci.yml v3.0 copied (parent-child, 8 cards)"
echo "  OK - Child pipelines copied to .gitlab/ci/"
echo "  OK - ALL validation scripts copied to scripts/workflow/"
echo "  OK - Post-wave hooks copied to scripts/hooks/"
echo "  OK - .project-state-templates copied for Agent 25"
echo ""

# Create project-specific .gitignore
echo "Step 3: Creating .gitignore..."
cat > "$PROJECT_PATH/.gitignore" << 'EOF'
# Framework (NEVER commit - stays local only)
.framework/

# Outputs (tracked)
# outputs/

# Dependencies
node_modules/
__pycache__/
*.pyc
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Environment
.env
.env.local

# Build
dist/
build/
*.log

# Testing
coverage/
.pytest_cache/

# Learning data (never commit)
.learning/
EOF
echo "✓ .gitignore created"
echo ""

# Create learning structure
echo "Step 4: Creating learning structure..."
mkdir -p "$PROJECT_PATH/.learning/analysis"
mkdir -p "$PROJECT_PATH/.learning/proposed-skills"
mkdir -p "$PROJECT_PATH/.learning/errors-kb"

cat > "$PROJECT_PATH/.learning/.gitignore" << 'EOF'
# Never commit learning data to project repository
# This data is local to your machine and used by Agent 21

*
!.gitignore
EOF

cat > "$PROJECT_PATH/.learning/README.md" << 'EOF'
# Learning Directory

This directory is used by **Agent 21: Learning Agent** to store analysis data and skill proposals.

## What's Here

- `analysis/` - Git pattern analysis, output analysis reports
- `proposed-skills/` - Auto-generated skill proposals from detected patterns
- `errors-kb/` - Knowledge base of errors and solutions

## Usage

```bash
# Run learning agent
lanza el agente 21-learning-agent

# Review proposed skills
ls proposed-skills/

# Read a proposal
cat proposed-skills/09-skill-name.md

# Approve a skill
cp proposed-skills/09-skill-name.md ../.framework/agents/workflow-orchestrator/skills/
```

## Important

This directory is **NOT committed to git** (see .gitignore). All learning data stays local to your machine.

To share approved skills with the framework, manually copy them to the framework repository.
EOF

echo "✓ Learning structure created"
echo ""

# Create README
echo "Step 5: Creating README.md..."
cat > "$PROJECT_PATH/README.md" << EOF
# $PROJECT_NAME

Project created with Framework Agents v2.

## Quick Start (v2 Workflow)

### Step 1: Push to GitLab

\`\`\`bash
git remote add origin <your-gitlab-repo-url>
git push -u origin main
\`\`\`

### Step 2: Run Agent 00 (Project Type Detection)

\`\`\`
In Claude Code:
"lanza el agente 00-project-type-detector"
\`\`\`

This detects project type and validates FastAPI mandate. Must run before anything else.

### Step 3: Discovery Phase (Agents 01-05)

\`\`\`
"lanza el agente 01-product-discovery quiero un [YOUR_PROJECT_IDEA]"
"lanza el agente 02-domain-modeling-agent"
"lanza el agente context-mapping-agent"
"lanza el agente architecture-decision"
"lanza el agente service-design-architect"
\`\`\`

### Step 4: Planning Phase (Agents 05c, 06-09)

\`\`\`
"lanza el agente 05c-api-first-specification"
"lanza el agente 06-epic-generation"
"lanza el agente 07-user-story-generator"
"lanza el agente 08-tech-lead-delivery"
"lanza el agente 09-sprint-orchestrator"
\`\`\`

### Step 5: Development (Agent 25 orchestrates everything)

\`\`\`
"lanza el agente 25-development-orchestrator"
\`\`\`

Agent 25 Phase 0 automatically:
- Installs git hooks v2 (pre-commit + post-commit)
- Verifies FastAPI mandate
- Verifies completeness gate is present
- Prints "FRAMEWORK ACTIVATED" banner
- Then runs development agents (10, 11, 12, 13, 14) in wave order

From this point, every commit automatically triggers:
- Workflow status update
- Wave completion detection
- Post-wave validation (linting, smoke tests, security)
- Sprint completeness gate

## Project Structure

\`\`\`
$PROJECT_NAME/
├── .framework/          # Framework (agents, scripts, skills) — NOT committed
├── .learning/           # Learning data (Agent 21) — NOT committed
├── outputs/             # Agent outputs
├── backend/             # FastAPI backend (Python) — MANDATORY STACK
├── frontend/            # React frontend with UX design system
├── scripts/             # Workflow scripts (for CI access)
├── .gitlab-ci.yml       # Pipeline v3.0 (parent-child, 8 stages)
└── .gitlab/ci/          # Child pipeline definitions
\`\`\`

## Framework Mandate

- Backend: **FastAPI (Python) exclusively**. NestJS/Express/Spring are blocked.
- Frontend: **Full UX design** with design system, not blank pages.
- API: **Beautiful API with DX-first principles**.
- Completeness: Every sprint is gated at 100% task implementation.

## Support

Framework: https://gitlab.com/rojored7-group/redwork
Created: $(date +%Y-%m-%d)
EOF
echo "OK - README.md created"
echo ""

# Update workflow paths in scripts
echo "Step 6: Updating script paths..."
cd "$PROJECT_PATH/.framework/scripts/workflow"

# Update auto-commit script to use outputs/ directory
sed -i 's|"01_product_discovery.md"|"outputs/01_product_discovery.md"|g' auto-commit-agent-output.sh 2>/dev/null || true
sed -i 's|"02_domain_model.md"|"outputs/02_domain_model.md"|g' auto-commit-agent-output.sh 2>/dev/null || true
sed -i 's|"03_context_map.md"|"outputs/03_context_map.md"|g' auto-commit-agent-output.sh 2>/dev/null || true
sed -i 's|"04_architecture_decision.md"|"outputs/04_architecture_decision.md"|g' auto-commit-agent-output.sh 2>/dev/null || true
sed -i 's|"05_service_design.md"|"outputs/05_service_design.md"|g' auto-commit-agent-output.sh 2>/dev/null || true

cd "$FRAMEWORK_PATH"
echo "✓ Script paths updated"
echo ""

# GitLab CI v2.0 already uses outputs/ paths - no modification needed
echo "Step 7: GitLab CI v2.0 ready (already uses outputs/ paths)"
echo ""

# Initialize Git
echo "Step 8: Initializing Git repository..."
cd "$PROJECT_PATH"
git init
git add .
git commit -m "feat: Initial project setup with Framework Agents

Project: $PROJECT_NAME
Created: $(date +%Y-%m-%d)
Framework: Quality Enforcement Framework v1.0

Structure:
- .framework/ - Framework agents and scripts
- outputs/ - Agent output files
- backend/ - Backend application
- frontend/ - Frontend application

Next steps:
1. Install hooks: bash .framework/scripts/install-workflow-hooks.sh
2. Push to GitLab
3. Run pipeline and execute agents"

echo "✓ Git repository initialized"
echo ""

# Success message
echo "=========================================="
echo "PROJECT CREATED SUCCESSFULLY (v2)"
echo "=========================================="
echo ""
echo "Project: $PROJECT_NAME"
echo "Location: $PROJECT_PATH"
echo ""
echo "Next steps:"
echo ""
echo "  1. cd $PROJECT_PATH"
echo ""
echo "  2. Push to GitLab:"
echo "     git remote add origin <your-gitlab-repo-url>"
echo "     git push -u origin main"
echo ""
echo "  3. In Claude Code, run agents in order:"
echo ""
echo "     a) \"lanza el agente 00-project-type-detector\""
echo "        -> Detects project type, validates FastAPI mandate"
echo ""
echo "     b) \"lanza el agente 01-product-discovery quiero un [IDEA]\""
echo "        -> Then agents 02, 03, 04, 05 (Discovery)"
echo ""
echo "     c) \"lanza el agente 05c-api-first-specification\""
echo "        -> Then agents 06, 07, 08, 09 (Planning)"
echo ""
echo "     d) \"lanza el agente 25-development-orchestrator\""
echo "        -> Phase 0 installs hooks automatically"
echo "        -> Activates completeness gate"
echo "        -> Runs development agents in wave order"
echo ""
echo "  NO manual hook installation needed."
echo "  Agent 25 Phase 0 handles it automatically."
echo ""
echo "=========================================="

cd "$FRAMEWORK_PATH"
exit 0
