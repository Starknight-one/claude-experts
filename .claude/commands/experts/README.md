# Expert System (framework)

Per-domain mental models that Claude reads/refreshes to give grounded,
current answers about *your* codebase. Replaces "ask Claude to grep around"
with "ask the catalog expert" — same model, but with a structured
cheat-sheet already loaded.

> **Source of truth is always the code.** Expertise YAMLs are working
> memory that gets validated against the code via `self-improve`.

This is the **mechanism**, shipped empty — no domain experts yet. You
define your own domains in `_meta.yaml` and scaffold each from `_templates/`.

## The shape

Each expert covers ONE business domain across ALL layers (NOT one layer
across all domains — that pattern doesn't work). An expert lives in
`.claude/commands/experts/<name>/` with three files:

- `expertise.yaml` — the mental model (overview, key files, invariants, gotchas, related_experts)
- `question.md` — slash command `/experts:<name>:question <prompt>` answers without code changes
- `self-improve.md` — slash command `/experts:<name>:self-improve true` re-reads code and updates the YAML

Claude Code auto-discovers the trio from the directory name — no registration
needed beyond creating the files.

## How to use

**Ask a question** (no code changes):
```
/experts:<name>:question Why does X skip records without a SKU?
```
The expert answers using its YAML + reads the relevant code, returns specific
`file:line` refs, mentions related experts when the answer crosses layers.

**Refresh manually** after a big refactor in one domain:
```
/experts:<name>:self-improve true
```

**Refresh ALL changed domains at once**:
```
/sync-experts                # selective by default (auto)
/sync-experts --all          # full sync, every declared expert
/sync-experts --domain <name>
/sync-experts --diff HEAD~5  # diff from a non-default base
```

## Auto-sync at session close

When you close Claude Code (`/exit` or terminal close), a `SessionEnd` hook
spawns a background `claude --print "/sync-experts --auto"` in a fresh
headless session. It:

1. Diffs your work since `origin/main` + working-tree changes
2. Maps changed files to affected domains via `_meta.yaml` globs
3. For each affected domain, runs that expert's `self-improve`
4. Logs to `.claude/.last_sync.log`
5. Exits silently

The original Claude Code closes immediately — the background agent does its
work without blocking you. Headless invocation = fresh context, no need to
`/compact` your closing session.

**Auto-sync skips when:**
- Repo is fully clean (no diff vs `origin/main`, no working-tree edits, no untracked files)
- `reason == "clear"` (the `/clear` command isn't a real session close)
- Another sync is already running (atomic `mkdir` lock)

**Requirements:** the hook needs `git`, `jq`, and the `claude` CLI on PATH,
and the repo must have an `origin/main` to diff against (edit the hook if your
default branch differs).

**To disable auto-sync:** rename the hook script
(`mv .claude/hooks/sync_experts_on_session_end.sh{,.disabled}`) or delete
the `SessionEnd` block from `.claude/settings.json`.

**Caveat (macOS):** the lock uses `mkdir` (atomic on POSIX). `flock` doesn't
ship on macOS. If hooks seem not to run, check `.claude/.last_sync.log`; a
missing log file usually means the script aborted before that line.

## Files

```
.claude/
├── commands/
│   ├── experts/
│   │   ├── README.md             ← you are here
│   │   ├── _meta.yaml            ← single source of truth: domain → file globs
│   │   ├── _templates/           ← scaffolding for new experts
│   │   └── <name>/{expertise.yaml, question.md, self-improve.md}   ← your experts
│   └── sync-experts.md           ← /sync-experts slash command
├── hooks/
│   └── sync_experts_on_session_end.sh   ← SessionEnd hook
├── settings.json                 ← registers the hook (see INSTALL.md)
├── .last_sync.log                ← (gitignore this) last auto-sync run output
└── .sync.lock.d/                 ← (gitignore this) atomic lock dir during sync
```

## Adding a new expert

1. Add a top-level domain block to `_meta.yaml` with its `globs:` list.
2. Create `.claude/commands/experts/<name>/` with the 3 files. Copy from
   `_templates/` and replace `{DOMAIN}` with your domain name. Claude Code
   auto-discovers the trio as `/experts:<name>:question` and
   `/experts:<name>:self-improve`.
3. Write a **domain-specific** `self-improve.md` (NOT a verbatim copy of the
   generic template — list the specific files, structs, and drift surfaces to
   check for THIS domain). This is what makes the refresh useful.
4. Run `/experts:<name>:self-improve true` to populate the YAML from code.
5. (optional) Add a routing table to your `CLAUDE.md`: "question about X → ask
   `/experts:<name>:question`" so future sessions reach for the expert first.

## Origin

ACT → LEARN → REUSE with vertical domain experts. Each expertise YAML lives
somewhere in the ~600–1000 line range when mature. Smaller = thin/incomplete.
Larger = either a real big domain or a signal the underlying module needs
splitting.
