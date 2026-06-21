# Self-Improving Expert System for Claude Code

Per-domain "experts" for your codebase — namespaced slash commands that hold a
structured mental model of one business domain and **refresh themselves from
the code**. Instead of "ask Claude to grep around," you `/experts:payments:question`
and get grounded `file:line` answers from a cheat-sheet that stays current.

> This repo ships the **mechanism**, empty. You define your own domains and
> Claude populates the expertise from your code. Nothing here is tied to any
> specific codebase.

## What you get

- `/experts:<domain>:question <prompt>` — answer questions about a domain (no code changes)
- `/experts:<domain>:self-improve true` — re-read the code and update the domain's `expertise.yaml`
- `/sync-experts` — refresh every domain touched by your recent changes
- A `SessionEnd` hook that auto-runs `/sync-experts --auto` headlessly when you close Claude Code

These are **slash commands + a hook**, not a `SKILL.md` skill — they live in your
repo's `.claude/` and the expertise files get committed alongside your code.

## Install

```bash
git clone https://github.com/Starknight-one/claude-experts.git
cd claude-experts
./install.sh /path/to/your/project      # defaults to the current directory
```

The installer copies the `.claude/` overlay into your project, registers the
hook in `settings.json` (without clobbering existing hooks), and gitignores the
runtime artifacts. Requires `git`, `jq`, and the `claude` CLI.

Full step-by-step (including defining your first domain): see [INSTALL.md](INSTALL.md).

## How it works

Each domain lives in `.claude/commands/experts/<name>/` as three files —
`expertise.yaml` (the mental model), `question.md` (the ask command), and
`self-improve.md` (the refresh command). `_meta.yaml` maps each domain to file
globs; the hook and `/sync-experts` use those globs to decide which experts a
given diff affects. See [`.claude/commands/experts/README.md`](.claude/commands/experts/README.md).

## License

MIT
