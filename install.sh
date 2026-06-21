#!/usr/bin/env bash
# Installer for the Self-Improving Expert System (Claude Code).
#
# Copies the .claude/ overlay (experts commands, /sync-experts, SessionEnd
# hook) into a target repo and registers the hook in that repo's
# .claude/settings.json. Safe to re-run; never clobbers an existing
# SessionEnd hook.
#
# Usage:
#   ./install.sh [TARGET_REPO]      # default TARGET_REPO = current directory
#
# Run it from inside this cloned repo (it copies the .claude/ that sits
# next to this script).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$SCRIPT_DIR/.claude"
TARGET="${1:-$(pwd)}"
DST="$TARGET/.claude"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
warn() { printf '\033[33m%s\033[0m\n' "$1"; }
ok()   { printf '\033[32m%s\033[0m\n' "$1"; }

[ -d "$SRC" ] || { echo "error: $SRC not found — run this from the cloned repo root."; exit 1; }
[ -d "$TARGET" ] || { echo "error: target '$TARGET' is not a directory."; exit 1; }

bold "Installing expert system into: $TARGET"

# 1. Copy the command + hook overlay (merges into an existing .claude/).
mkdir -p "$DST/commands" "$DST/hooks"
cp -R "$SRC/commands/experts" "$DST/commands/"
cp "$SRC/commands/sync-experts.md" "$DST/commands/"
cp "$SRC/hooks/sync_experts_on_session_end.sh" "$DST/hooks/"
chmod +x "$DST/hooks/sync_experts_on_session_end.sh"
ok "  copied: commands/experts/, commands/sync-experts.md, hooks/sync_experts_on_session_end.sh"

# 2. Register the SessionEnd hook in settings.json (safe deep-merge).
SETTINGS="$DST/settings.json"
SNIPPET="$SCRIPT_DIR/settings.snippet.json"
if [ ! -f "$SETTINGS" ]; then
  cp "$SNIPPET" "$SETTINGS"
  ok "  created: .claude/settings.json with SessionEnd hook"
elif command -v jq >/dev/null 2>&1; then
  if jq -e '.hooks.SessionEnd' "$SETTINGS" >/dev/null 2>&1; then
    warn "  settings.json already has a SessionEnd hook — not touching it."
    warn "  Merge this manually if you want auto-sync:"
    sed 's/^/      /' "$SNIPPET"
  else
    tmp="$(mktemp)"
    jq -s '.[0] * .[1]' "$SETTINGS" "$SNIPPET" > "$tmp" && mv "$tmp" "$SETTINGS"
    ok "  merged: SessionEnd hook into existing settings.json"
  fi
else
  warn "  jq not found — add this to .claude/settings.json by hand:"
  sed 's/^/      /' "$SNIPPET"
fi

# 3. Gitignore the runtime artifacts.
GI="$TARGET/.gitignore"
for line in ".claude/.last_sync.log" ".claude/.sync.lock.d/"; do
  if [ ! -f "$GI" ] || ! grep -qxF "$line" "$GI"; then
    echo "$line" >> "$GI"
  fi
done
ok "  gitignored: .claude/.last_sync.log, .claude/.sync.lock.d/"

cat <<'EOF'

Done. Next steps (in a Claude Code session inside your repo):

  1. Edit  .claude/commands/experts/_meta.yaml  — replace example-domain
     with a real domain + its file globs.
  2. Scaffold the expert trio from _templates/ (see INSTALL.md step 5),
     then tailor that domain's self-improve.md.
  3. Run  /experts:<domain>:self-improve true   to populate it from code.
  4. Ask  /experts:<domain>:question <your question>

Full guide: .claude/commands/experts/README.md
EOF
