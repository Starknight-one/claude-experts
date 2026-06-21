# {DOMAIN} Self-Improve

Update {DOMAIN} expertise from codebase.

## Variables

USE_DIFF: $ARGUMENTS (true|false, default: false)
EXPERTISE: .claude/commands/experts/{DOMAIN}/expertise.yaml
META: .claude/commands/experts/_meta.yaml

## Instructions

- IMPORTANT: rewrite this file to be DOMAIN-SPECIFIC — list the actual
  files, structs, and drift surfaces of {DOMAIN}. A generic copy of this
  template produces a thin, useless YAML.
- Scan codebase for {DOMAIN} knowledge (use this domain's globs in META)
- Update expertise.yaml with findings
- Keep the YAML actionable (mature experts land ~600–1000 lines)

## Workflow

### Step 1: Load Current Expertise
Read EXPERTISE to understand current state.

### Step 2: Load Domain Globs
Read META and find the `{DOMAIN}` entry under `experts:` to get the
file globs that define this domain's surface.

### Step 3: Scan Codebase
If USE_DIFF = true:
```bash
git diff HEAD~5 --name-only
```
Focus on changed files that match this domain's globs.

Otherwise, scan all files matching this domain's globs.

### Step 4: Extract Knowledge
For each relevant file:
- File purpose
- Key patterns
- Important structures
- Dependencies

### Step 4.5: Extract Integration Gotchas (CRITICAL)
This prevents spec-to-implementation bugs:

**Data Types:**
- Check interface parameter types (UUID vs string vs slug)
- Check numeric types (int cents vs float dollars)

**Database Constraints:**
- Read migration files for REFERENCES (foreign keys)
- Document: "creating X requires Y to exist first"

**External APIs:**
- Extract API versions from adapter code
- Document auth headers, base URLs

**SQL/Filter Logic:**
- Check how WHERE conditions combine (AND vs OR)
- Document edge cases

Add findings to `gotchas`, `external_apis`, `integration_patterns` sections.

### Step 5: Update Expertise
Update expertise.yaml:

**PRESERVE (never modify):**
- `overview.architecture` — architectural pattern name
- `overview.description` — high-level description
- `layer_rules` — dependency rules between layers
- `patterns` — naming conventions and patterns

**UPDATE (from codebase scan):**
- `project_structure` — actual files and directories
- `core_implementation` — current implementation details
- `api_endpoints` — actual endpoints
- `run_commands` — verified commands
- `migration_status` — current state

Rules:
- Keep format consistent
- Stay within line limit
- Focus on actionable knowledge

### Step 6: Report Changes

## Constraints

- DO NOT: pad with prose — focus on patterns, not docs
- DO: include file paths (file:line where useful)
- DO: keep it actionable

## Output

```
{DOMAIN} Expertise Updated

Changes:
- Added: <what>
- Updated: <what>
- Removed: <what>

Lines: N
```
