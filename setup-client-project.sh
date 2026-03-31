#!/bin/bash
# ============================================
# Setup Client Project with Framework
# ============================================
# This script sets up a new client project with:
# - Framework installed LOCALLY (not versioned)
# - .gitignore configured for CLIENT DELIVERY
# - Git initialized and ready
#
# Usage: bash setup-client-project.sh <project-name>

set -e

FRAMEWORK_PATH="C:/Users/Itac/Proyectos/Framework"
PROJECT_NAME=$1

if [ -z "$PROJECT_NAME" ]; then
  echo "❌ ERROR: Project name required"
  echo "Usage: bash setup-client-project.sh <project-name>"
  exit 1
fi

echo ""
echo "🚀 SETTING UP CLIENT PROJECT: $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# Step 1: Create Project Directory
# ============================================
echo "📁 Creating project directory..."

if [ -d "$PROJECT_NAME" ]; then
  echo "❌ ERROR: Directory $PROJECT_NAME already exists"
  exit 1
fi

mkdir "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "✅ Created: $PROJECT_NAME/"
echo ""

# ============================================
# Step 2: Initialize Git
# ============================================
echo "🔧 Initializing git..."

git init
echo "✅ Git initialized"
echo ""

# ============================================
# Step 3: Copy .gitignore for CLIENT DELIVERY
# ============================================
echo "📋 Setting up .gitignore for CLIENT DELIVERY..."

if [ -f "$FRAMEWORK_PATH/.gitignore-CLIENT-DELIVERY" ]; then
  cp "$FRAMEWORK_PATH/.gitignore-CLIENT-DELIVERY" ./.gitignore
  echo "✅ .gitignore configured (framework will NOT be versioned)"
else
  echo "⚠️  WARNING: .gitignore-CLIENT-DELIVERY not found in framework"
  echo "   Creating basic .gitignore..."
  cat > .gitignore << 'EOF'
# Framework (LOCAL only, not versioned)
.claude/
scripts/
.husky/
.project-orchestration/
FRAMEWORK_*.md
*_report.md

# Node
node_modules/
npm-debug.log*

# Environment
.env
.env.local
.env.*.local

# Build
dist/
build/

# OS
.DS_Store
Thumbs.db
EOF
  echo "✅ Basic .gitignore created"
fi
echo ""

# ============================================
# Step 4: Copy Framework LOCALLY (not versioned)
# ============================================
echo "⚙️  Installing framework LOCALLY (will not be versioned)..."

# Copy .claude/
if [ -d "$FRAMEWORK_PATH/.claude" ]; then
  cp -r "$FRAMEWORK_PATH/.claude" ./.claude
  echo "  ✅ .claude/ installed"
else
  echo "  ❌ ERROR: .claude/ not found in framework"
  exit 1
fi

# Copy agents/
if [ -d "$FRAMEWORK_PATH/agents" ]; then
  mkdir -p .claude/agents
  cp -r "$FRAMEWORK_PATH/agents/"* ./.claude/agents/
  echo "  ✅ agents/ installed (20 agents)"
else
  echo "  ⚠️  WARNING: agents/ not found, skipping"
fi

# Copy scripts/
if [ -d "$FRAMEWORK_PATH/scripts" ]; then
  cp -r "$FRAMEWORK_PATH/scripts" ./scripts
  echo "  ✅ scripts/ installed"
else
  echo "  ❌ ERROR: scripts/ not found in framework"
  exit 1
fi

# Copy .husky/
if [ -d "$FRAMEWORK_PATH/.husky" ]; then
  cp -r "$FRAMEWORK_PATH/.husky" ./.husky
  echo "  ✅ .husky/ installed"
else
  echo "  ⚠️  WARNING: .husky/ not found, skipping"
fi

echo ""

# ============================================
# Step 5: Install Git Hooks
# ============================================
echo "🔗 Installing git hooks..."

if [ -f "./scripts/install-git-hooks.sh" ]; then
  bash ./scripts/install-git-hooks.sh
  echo "✅ Git hooks installed"
else
  echo "⚠️  WARNING: install-git-hooks.sh not found"
fi
echo ""

# ============================================
# Step 6: Create README.md for Client
# ============================================
echo "📄 Creating README.md..."

cat > README.md << EOF
# $PROJECT_NAME

**Client Project - Generated with Quality Enforcement Framework**

---

## Setup

\`\`\`bash
# Install dependencies
npm install

# Start development
npm run dev

# Build for production
npm run build

# Run tests
npm test
\`\`\`

---

## Project Structure

\`\`\`
$PROJECT_NAME/
├── backend/         # Backend application
├── frontend/        # Frontend application
├── docs/            # Documentation
└── README.md        # This file
\`\`\`

---

## Environment Variables

Copy \`.env.example\` to \`.env.local\` and configure:

\`\`\`bash
cp .env.example .env.local
# Edit .env.local with your values
\`\`\`

---

## License

[Your License]

EOF

echo "✅ README.md created"
echo ""

# ============================================
# Step 7: Create package.json skeleton
# ============================================
echo "📦 Creating package.json..."

cat > package.json << EOF
{
  "name": "$PROJECT_NAME",
  "version": "1.0.0",
  "description": "Client project",
  "private": true,
  "workspaces": [
    "backend",
    "frontend"
  ],
  "scripts": {
    "backend": "npm run start:dev --workspace=backend",
    "frontend": "npm start --workspace=frontend",
    "build": "npm run build --workspaces",
    "test": "npm test --workspaces",
    "lint": "npm run lint --workspaces"
  },
  "keywords": [],
  "author": "",
  "license": "MIT"
}
EOF

echo "✅ package.json created"
echo ""

# ============================================
# Step 8: Verify Framework is NOT Tracked
# ============================================
echo "🔍 Verifying framework is NOT tracked by git..."

git status > /tmp/git-status.txt

if grep -q ".claude" /tmp/git-status.txt; then
  echo "⚠️  WARNING: .claude/ is being tracked by git"
  echo "   Check your .gitignore"
else
  echo "  ✅ .claude/ is ignored by git"
fi

if grep -q "scripts/hooks" /tmp/git-status.txt; then
  echo "⚠️  WARNING: scripts/hooks/ is being tracked by git"
else
  echo "  ✅ scripts/hooks/ is ignored by git"
fi

echo ""

# ============================================
# Step 9: Initial Commit
# ============================================
echo "💾 Creating initial commit..."

git add .gitignore README.md package.json
git commit -m "chore: Initial project setup

- Add .gitignore (configured for client delivery)
- Add README.md
- Add package.json
- Framework installed locally (not versioned)

🤖 Generated with Quality Enforcement Framework"

echo "✅ Initial commit created"
echo ""

# ============================================
# Step 10: Summary
# ============================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ PROJECT SETUP COMPLETE: $PROJECT_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📁 Project Location:"
echo "   $(pwd)"
echo ""
echo "📊 What's Installed:"
echo "   ✅ Framework (LOCAL, not versioned):"
echo "      .claude/                  (ignored by git)"
echo "      .claude/agents/           (20 agents)"
echo "      scripts/                  (enforcement scripts)"
echo "      .husky/                   (git hooks)"
echo ""
echo "   ✅ Client Files (VERSIONED):"
echo "      .gitignore                (tracked by git)"
echo "      README.md                 (tracked by git)"
echo "      package.json              (tracked by git)"
echo ""
echo "🔍 Verification:"
git ls-files
echo ""
echo "   ☝️  Git should ONLY track: .gitignore, README.md, package.json"
echo "   ☝️  Framework should NOT appear above"
echo ""
echo "🎯 Next Steps:"
echo ""
echo "   1. cd $PROJECT_NAME"
echo "   2. Create backend/frontend structure"
echo "   3. Start development (framework is active locally)"
echo "   4. git push origin main (only code, NOT framework)"
echo ""
echo "📖 Documentation:"
echo "   - CLIENT_DELIVERY_WORKFLOW.md (how to work with framework)"
echo "   - AGENTS_SETUP.md (agent configuration)"
echo ""
echo "✅ Framework is ready to use!"
echo "✅ Client will NEVER see the framework when you push"
echo ""
