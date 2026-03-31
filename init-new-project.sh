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
cp workflow-status.json "$PROJECT_PATH/"
cp .gitlab-ci.yml "$PROJECT_PATH/"
echo "✓ Framework files copied"
echo ""

# Create project-specific .gitignore
echo "Step 3: Creating .gitignore..."
cat > "$PROJECT_PATH/.gitignore" << 'EOF'
# Framework (tracked, do not ignore)
# .framework/

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
EOF
echo "✓ .gitignore created"
echo ""

# Create README
echo "Step 4: Creating README.md..."
cat > "$PROJECT_PATH/README.md" << EOF
# $PROJECT_NAME

Project created with Framework Agents.

## Project Structure

\`\`\`
$PROJECT_NAME/
├── .framework/          # Framework files (agents, scripts, hooks)
├── outputs/             # Agent outputs (discovery docs, models, etc.)
├── backend/             # Backend application
├── frontend/            # Frontend application
├── docs/                # Additional documentation
└── .gitlab-ci.yml       # CI/CD pipeline configuration
\`\`\`

## Quick Start

### 1. Install hooks

\`\`\`bash
bash .framework/scripts/install-workflow-hooks.sh
\`\`\`

### 2. Start pipeline in GitLab

1. Push this repo to GitLab
2. Go to Pipelines
3. Click "Run pipeline"
4. Click Play on agent_01

### 3. Execute Agent 01

\`\`\`
In Claude Code:
"lanza el agente 01-product-discovery quiero un [YOUR_PROJECT_IDEA]"
\`\`\`

Agent will generate: \`outputs/01_product_discovery.md\`

### 4. Auto-commit

\`\`\`bash
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md
\`\`\`

The workflow will:
- Validate the file
- Push to GitLab
- GitLab pipeline detects it (30s max)
- Agent 02 auto-starts

### 5. Continue with remaining agents

Repeat for agents 02-05 (Discovery phase).

## Agents Available

**Discovery Phase (01-05)**:
1. Product Discovery
2. Domain Modeling
3. Context Mapping
4. Architecture Decision
5. Service Design

## Documentation

See \`.framework/agents/README.md\` for complete agent list and usage.

## Support

Framework repository: https://gitlab.com/rojored7-group/redwork

Created: $(date +%Y-%m-%d)
EOF
echo "✓ README.md created"
echo ""

# Update workflow paths in scripts
echo "Step 5: Updating script paths..."
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

# Update GitLab CI to look in outputs/
echo "Step 6: Updating GitLab CI paths..."
sed -i 's|FILE_NAME="0|FILE_NAME="outputs/0|g' "$PROJECT_PATH/.gitlab-ci.yml" 2>/dev/null || true
echo "✓ GitLab CI updated"
echo ""

# Initialize Git
echo "Step 7: Initializing Git repository..."
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
echo "PROJECT CREATED SUCCESSFULLY"
echo "=========================================="
echo ""
echo "Project: $PROJECT_NAME"
echo "Location: $PROJECT_PATH"
echo ""
echo "Next steps:"
echo ""
echo "1. Navigate to project:"
echo "   cd $PROJECT_PATH"
echo ""
echo "2. Install workflow hooks:"
echo "   bash .framework/scripts/install-workflow-hooks.sh"
echo ""
echo "3. Create GitLab repository and push:"
echo "   git remote add origin <your-gitlab-repo-url>"
echo "   git push -u origin main"
echo ""
echo "4. Start pipeline in GitLab:"
echo "   - Go to Pipelines"
echo "   - Click 'Run pipeline'"
echo "   - Click Play on agent_01"
echo ""
echo "5. Execute first agent in Claude Code:"
echo "   lanza el agente 01-product-discovery quiero un [YOUR_IDEA]"
echo ""
echo "6. Auto-commit output:"
echo "   bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_product_discovery.md"
echo ""
echo "=========================================="
echo "Ready to start development!"
echo "=========================================="

cd "$FRAMEWORK_PATH"
exit 0
