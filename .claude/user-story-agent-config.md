# User Story Generation Agent Configuration

## 07-User-Story-Generation-Agent Rules

### MANDATORY BEHAVIOR

When invoked for user story generation:

0. **FIRST ACTION - CREATE CONTROL DOCUMENT**
   - Create `07_user_stories/claude.md` FIRST (before any user stories)
   - Use template from `.claude/USER_STORIES_CLAUDE_TEMPLATE.md`
   - Fill in project context and epic catalog
   - This becomes the central control document for ALL user stories

1. **COMPLETENESS REQUIREMENT**
   - Process ALL epic files found in 06_epics/
   - Create user stories for EVERY epic (no exceptions)
   - Do NOT skip any epic numbers
   - Do NOT stop after a few examples
   - Do NOT create summaries instead of stories

2. **EPIC PROCESSING ORDER**
   ```
   MUST process in sequence:
   01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15

   NO SKIPPING ALLOWED
   ```

3. **OUTPUT STRUCTURE PER EPIC**
   ```
   07_user_stories/
   └── epic_XX_name/
       ├── US-XX1_story_name.md (minimum 2 stories per epic)
       ├── US-XX2_story_name.md
       ├── US-XX3_story_name.md (recommended 3-5 per epic)
       └── ...
   ```

4. **STORY COMPLETENESS**
   Each user story MUST include:
   - Story title with user role
   - Business value explanation
   - Acceptance criteria (minimum 5)
   - BDD scenarios (Given/When/Then)
   - Technical considerations
   - Story points estimate
   - Dependencies

5. **VALIDATION CHECKLIST**
   Before completing, verify:
   - [ ] Count of epic folders in 07_user_stories/ = Count of epic files in 06_epics/
   - [ ] Each epic has minimum 2 user stories
   - [ ] Each user story has all required sections
   - [ ] Story IDs follow numbering convention (US-010, US-020, etc.)
   - [ ] All stories reference epic business value

6. **NO LIMITS**
   - No time limits
   - No token limits
   - Quality over speed
   - Completeness is mandatory

7. **PROGRESS REPORTING**
   After each epic completion:
   ```
   ✅ Epic XX completed (Y stories created)
   Total progress: XX/15 epics
   Next: Epic XX+1
   ```

## Expected Output

**Minimum**: 15 epic folders with 2-5 stories each = 30-75 user stories
**Current**: 4 epic folders with 11 stories = INCOMPLETE

**Missing**:
- Epic 04: Colaboración Equipos (0 stories) ← SKIP BUG
- Epic 06-15: (0 stories each) ← STOPPED EARLY

## Error Recovery

If interrupted:
- Resume from last completed epic
- Do NOT recreate existing stories
- Continue until ALL 15 epics are done

## Quality Standards

Each user story must:
- Be written from user perspective ("As a [role], I want [feature], so that [value]")
- Have SMART acceptance criteria
- Include realistic BDD scenarios
- Reference domain model entities
- Consider technical feasibility
- Align with architecture decisions

## Epic-Specific Guidelines

### Epic 04 (Colaboración Equipos)
**WHY IT WAS SKIPPED**: Likely alphabetical/numbering confusion
**FIX**: Explicitly check for epic_04_colaboracion_equipos.md and process it

### Epics 06-15
**WHY THEY WERE SKIPPED**: Agent stopped after processing first batch
**FIX**: Mandate processing ALL epics in 06_epics/ directory

## Validation Command

```bash
# Count epics
epic_count=$(ls 06_epics/epic_*.md | wc -l)

# Count story folders
story_folder_count=$(ls -d 07_user_stories/epic_*/ 2>/dev/null | wc -l)

# Verify match
if [ $epic_count -ne $story_folder_count ]; then
  echo "❌ INCOMPLETE: $epic_count epics but $story_folder_count story folders"
  exit 1
fi

echo "✅ All $epic_count epics have user stories"
```

---

**Last Updated**: 2024-03-19
**Status**: Active Configuration
**Purpose**: Ensure 07-User-Story-Generation-Agent processes ALL epics
