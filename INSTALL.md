# Install — Self-Improving Expert System

A Claude Code add-on: per-domain "experts" (namespaced slash commands) that
hold a mental model of your codebase and refresh themselves from the code.
Ships **empty** — the mechanism only. You add your own domains.

What's in this bundle:

```
.claude/
├── commands/
│   ├── sync-experts.md                       ← /sync-experts orchestrator
│   └── experts/
│       ├── README.md                         ← how the system works
│       ├── _meta.yaml                        ← domain → file-glob map (EDIT THIS)
│       └── _templates/{expertise.yaml, question.md, self-improve.md}
└── hooks/
    └── sync_experts_on_session_end.sh        ← auto-refresh on session close
settings.snippet.json                          ← hook registration to merge
```

## Requirements

- Claude Code CLI (`claude` on PATH)
- `git` (repo with an `origin/main`, or edit the hook for your default branch)
- `jq` (used by the hook)
- macOS/Linux. The hook uses an atomic `mkdir` lock (works without `flock`).

## Steps

### 1. Drop the files into your repo

From the bundle root, copy the `.claude/` tree into your project root
(merge if you already have a `.claude/`):

```bash
cp -R .claude/. /path/to/your/repo/.claude/
chmod +x /path/to/your/repo/.claude/hooks/sync_experts_on_session_end.sh
```

### 2. Register the SessionEnd hook

Merge `settings.snippet.json` into `/path/to/your/repo/.claude/settings.json`.
If you have no `settings.json` yet, just copy the snippet in as the whole file.
If you already have one, add the `SessionEnd` entry under the existing
`"hooks"` object (don't clobber other hooks).

> Auto-refresh is optional. Skip this step and you still get every
> `/experts:*` and `/sync-experts` command — you just refresh manually.

### 3. Gitignore the runtime artifacts

Add to `.gitignore`:

```
.claude/.last_sync.log
.claude/.sync.lock.d/
```

### 4. Define your first domain

Edit `.claude/commands/experts/_meta.yaml`: delete the `example-domain`
block and add a real one, e.g.:

```yaml
experts:
  payments:
    globs:
      - "src/payments/**/*.ts"
      - "migrations/*payment*.sql"
```

### 5. Scaffold the expert trio

```bash
cd /path/to/your/repo
mkdir -p .claude/commands/experts/payments
for f in expertise.yaml question.md self-improve.md; do
  sed 's/{DOMAIN}/payments/g' \
    .claude/commands/experts/_templates/$f \
    > .claude/commands/experts/payments/$f
done
```

Then **rewrite `payments/self-improve.md`** to be domain-specific — list the
actual files, structs, and drift surfaces of that domain. The generic template
produces a thin, useless YAML; the value is in tailoring it.

### 6. Populate from code

In a Claude Code session in your repo:

```
/experts:payments:self-improve true
```

This reads the matching files and writes `payments/expertise.yaml`. Now:

```
/experts:payments:question How are refunds handled?
```

### 7. (recommended) Route to experts from CLAUDE.md

Add a small table to your `CLAUDE.md` so future sessions reach for the expert
before grepping:

```
| Question about… | Ask |
|---|---|
| payments / refunds / billing | /experts:payments:question |
```

## Verify it works

- `/experts:payments:question ping` — should load the YAML and answer.
- Make a change under a domain glob, then run `/sync-experts` — it should mark
  that domain "affected" and refresh it.
- Close Claude Code with uncommitted changes, reopen, and check
  `.claude/.last_sync.log` for a timestamped run line.

See `.claude/commands/experts/README.md` for the full design and the
"Adding a new expert" checklist.
