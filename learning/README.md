# Learning System - Framework Documentation

**Auto-learning system for framework skill generation using Agent 21**

---

## Overview

The Learning System enables the framework to learn from project execution patterns and automatically propose new workflow skills. It analyzes:

- Git commit history (agent execution sequences)
- Agent output files (content patterns)
- Error logs (problems and solutions)

Based on detected patterns, **Agent 21** proposes new skills that can be approved and integrated into the framework.

---

## Architecture

### Local Learning (Per Project)

Each project created with `init-new-project.sh` includes:

```
project/.learning/
├── analysis/           # Git/output analysis reports (JSON/MD)
├── proposed-skills/    # Auto-generated skill proposals (.md)
└── errors-kb/          # Error knowledge base (JSON)
```

**Important**: `.learning/` directory is **NOT committed** to project repository (see .gitignore). All learning data stays local.

### Framework Learning (Global)

Skills approved in projects can be manually shared back to the framework:

```
Framework/learning/
├── README.md           # This file
└── approved-skills/    # Community-contributed skills
```

---

## How It Works

### 1. Data Capture (Automatic)

While you work on projects using framework agents:
- Git commits with agent executions are recorded
- Agent outputs in `outputs/` are analyzed
- Error commits and fixes are cataloged

### 2. Pattern Detection (On Demand)

When you run **Agent 21**:

```bash
# In Claude Code
lanza el agente 21-learning-agent
```

Agent 21 analyzes:
- Last 50 git commits
- All files in `outputs/`
- Error patterns in commit messages

### 3. Skill Proposal (Automatic)

If patterns are detected (frequency ≥3, confidence ≥80%):
- Generates skill proposal in `.learning/proposed-skills/XX-name.md`
- Includes evidence (commits, frequencies, success rates)
- Provides complete skill template ready to use

### 4. Review and Approval (Manual)

Review proposed skills:

```bash
cd project-name
ls .learning/proposed-skills/

# Read proposal
cat .learning/proposed-skills/09-discovery-sequence.md

# If approved, activate in project
cp .learning/proposed-skills/09-discovery-sequence.md \
   .framework/skills/learned/
```

### 5. Share to Framework (Optional)

Share approved skills with the community:

```bash
# Copy approved skill to framework
cp project/.framework/skills/learned/09-discovery-sequence.md \
   <framework-repo>/skills/learned/

# Commit to framework repo
cd ~/Proyectos/Framework
git add skills/learned/09-discovery-sequence.md
git commit -m "feat: add community skill 09-discovery-sequence

Learned from project: project-name
Pattern: Agent 01→02→03 sequence (5 occurrences, 100% success)
"
git push origin framework
```

---

## Agent 21: Learning Agent

### When to Use

Run Agent 21 periodically to discover new optimization opportunities:
- After completing 5+ workflows
- Every 2-3 weeks of active development
- When you notice repetitive patterns
- Before starting a new sprint (to optimize workflow)

### What It Analyzes

**Git History:**
- Agent execution sequences
- Time between agent executions
- Success/failure patterns
- Commit frequency

**Agent Outputs:**
- Common section structures
- Repeated content patterns
- Template opportunities
- Standardization possibilities

**Errors:**
- Frequent error messages
- Resolution patterns
- Common troubleshooting steps
- Prevention strategies

### What It Generates

**Analysis Reports** (`.learning/analysis/`):
- `git-patterns-{date}.json` - Detected sequences
- `output-patterns-{date}.json` - Content analysis
- `summary-{date}.md` - Human-readable summary

**Skill Proposals** (`.learning/proposed-skills/`):
- `XX-{name}.md` - Complete skill definition
- Includes evidence and statistics
- Ready to use after review

**Knowledge Base** (`.learning/errors-kb/`):
- `{error-type}.json` - Error → solution mappings
- Frequency tracking
- Prevention strategies

---

## Pattern Examples

### Sequence Pattern

**Detected:**
```
Commits show: agent_01 → agent_02 → agent_03 (5 times, 100% success)
```

**Generated Skill:**
```
09-discovery-sequence.md

Purpose: Execute Discovery phase agents 01-03 in sequence
Process:
1. Execute agent 01
2. Auto-commit output
3. Execute agent 02
4. Auto-commit output
5. Execute agent 03
```

### Template Pattern

**Detected:**
```
All domain models have sections:
- Domain Entities
- Value Objects
- Aggregates
- Business Rules
```

**Generated Skill:**
```
10-domain-model-template.md

Purpose: Generate standard domain model structure
Process:
1. Create file with standard sections
2. Fill with project-specific entities
3. Validate completeness
```

### Error Pattern

**Detected:**
```
Error "port 3000 in use" occurred 3 times
Solution: kill process on port 3000
```

**Generated Knowledge:**
```
errors-kb/port-conflicts.json

{
  "error": "EADDRINUSE :::3000",
  "solutions": [
    "lsof -ti:3000 | xargs kill -9",
    "netstat -ano | findstr :3000 && taskkill /F /PID <PID>"
  ],
  "prevention": "Check port before starting server"
}
```

---

## Usage Workflow

### Initial Setup (One Time)

When creating a new project:

```bash
cd ~/Proyectos/Framework
bash init-new-project.sh my-project
```

The `.learning/` structure is created automatically.

### Regular Usage

**Phase 1: Work normally**
```bash
# Execute agents as usual
lanza el agente 01-product-discovery quiero un LMS

# Commit outputs
bash .framework/scripts/workflow/auto-commit-agent-output.sh outputs/01_*
```

**Phase 2: Analyze periodically**
```bash
# After 5+ workflows, run learning agent
lanza el agente 21-learning-agent

# Review proposals
ls .learning/proposed-skills/
cat .learning/proposed-skills/09-discovery-sequence.md
```

**Phase 3: Approve skills**
```bash
# If approved, activate
cp .learning/proposed-skills/09-discovery-sequence.md \
   .framework/skills/learned/

# Now you can use it
# In learning-agent: "Execute skill 09"
```

**Phase 4: Share (optional)**
```bash
# Share with community
cp .framework/skills/learned/09-discovery-sequence.md \
   <framework-repo>/skills/learned/

cd ~/Proyectos/Framework
git add skills/learned/09-discovery-sequence.md
git commit -m "feat: community skill 09-discovery-sequence"
git push origin framework
```

---

## Best Practices

### When to Run Agent 21

**Good Times:**
- After completing 5+ similar workflows
- Every 2 weeks of active development
- Before planning a new sprint
- When noticing repetitive manual steps

**Avoid Running:**
- With less than 20 commits (insufficient data)
- Immediately after project creation
- When changing workflows significantly (wait for pattern stability)

### Reviewing Proposals

**High Confidence (Approve)**:
- Frequency ≥5
- Success rate ≥90%
- Clear, consistent pattern
- Saves significant time

**Medium Confidence (Review Carefully)**:
- Frequency 3-4
- Success rate 80-90%
- Pattern has variations
- Moderate time savings

**Low Confidence (Reject/Wait)**:
- Frequency <3
- Success rate <80%
- Unclear pattern
- Minimal benefit

### Sharing Skills

**Good to Share:**
- Applicable to multiple project types
- Well-tested in your project
- Clear, documented process
- Significant value for community

**Keep Local:**
- Very project-specific
- Experimental or untested
- Company/client specific
- Contains sensitive logic

---

## Troubleshooting

### "No patterns detected"

**Cause**: Insufficient data or no repetitive patterns yet

**Solution**:
- Continue executing workflows (need 3+ repetitions)
- Re-run Agent 21 after more commits
- Check that agents are being used consistently

### "Low confidence proposals"

**Cause**: Patterns exist but have variations

**Solution**:
- Wait for more data (increase frequency)
- Review if pattern is actually consistent
- Consider if variations are intentional

### ".learning/ directory not created"

**Cause**: Project created before learning system was added

**Solution**:
```bash
cd project-name
mkdir -p .learning/{analysis,proposed-skills,errors-kb}
echo "*" > .learning/.gitignore
echo "!.gitignore" >> .learning/.gitignore
```

---

## File Formats

### Analysis Files

**git-patterns-{date}.json**:
```json
{
  "analysis_date": "ISO-8601",
  "commits_analyzed": 50,
  "patterns_found": [{
    "pattern": ["agent_01", "agent_02"],
    "frequency": 5,
    "confidence": "high"
  }]
}
```

**output-patterns-{date}.json**:
```json
{
  "analysis_date": "ISO-8601",
  "files_analyzed": 8,
  "common_sections": [{
    "section": "## Domain Entities",
    "frequency": "100%"
  }]
}
```

### Proposed Skills

**XX-skill-name.md**:
```markdown
# Proposed Skill: {Name}

## Detection Details
- Pattern type: sequence
- Frequency: 5
- Success rate: 100%

## Proposed Skill Content
[Complete skill definition following standard format]

## Evidence
[Commits, files, statistics]
```

### Error Knowledge Base

**{category}.json**:
```json
{
  "error_category": "port-conflicts",
  "occurrences": 3,
  "solutions": [
    {
      "error_message": "...",
      "solution": "...",
      "commands": ["..."],
      "success_rate": 1.0
    }
  ]
}
```

---

## Statistics and Metrics

Track learning system effectiveness:

```bash
# Count proposed skills
ls -1 .learning/proposed-skills/ | wc -l

# Count approved skills
ls -1 .framework/skills/learned/ | grep -E '^[0-9]' | wc -l

# Review analysis history
ls -lt .learning/analysis/
```

---

## Future Enhancements

Potential improvements for learning system:

- **Automatic skill testing** before proposal
- **Confidence scoring** based on multiple factors
- **Cross-project pattern detection** (analyzing multiple projects)
- **Skill effectiveness tracking** (measure time saved)
- **Community skill marketplace** (share/discover skills)

---

## Support

For issues or questions about the learning system:

1. Check Agent 21 documentation: `agents/21-learning-agent.md`
2. Review this README
3. Check project `.learning/analysis/summary-{date}.md` for insights
4. Create issue in framework repository

---

## Version

- **Learning System**: v1.0
- **Agent 21**: v1.0
- **Created**: 2026-04-01
- **Framework**: Quality Enforcement Framework

---

**The more you use the framework, the smarter it becomes.**
