#!/usr/bin/env bash
# check_sync.sh — drift detector against the Claude source-of-truth repo.
#
# Usage:
#   scripts/check_sync.sh /path/to/JsonUI-Agents-for-claude
#   CLAUDE_REPO=/path/to/JsonUI-Agents-for-claude scripts/check_sync.sh
#
# Reads the recorded source commit from SYNC_STATE.md and reports:
#   1. Claude-side commits + files changed since that commit (needs porting)
#   2. Content differences in the verbatim-mirrored trees (skills/, rules/)
#      — expected entries are listed in SYNC_STATE.md "Intentional divergences"
#
# It does NOT translate anything. See SYNC_STATE.md for the sync procedure.

set -euo pipefail

CLAUDE_REPO="${1:-${CLAUDE_REPO:-}}"
if [ -z "$CLAUDE_REPO" ]; then
  echo "usage: $0 /path/to/JsonUI-Agents-for-claude   (or set CLAUDE_REPO)" >&2
  exit 2
fi
if ! git -C "$CLAUDE_REPO" rev-parse --git-dir >/dev/null 2>&1; then
  echo "error: $CLAUDE_REPO is not a git repository" >&2
  exit 2
fi

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE="$(sed -n 's/^source_commit: *//p' "$ROOT/SYNC_STATE.md" | head -n1)"
if [ -z "$BASE" ]; then
  echo "error: source_commit not found in $ROOT/SYNC_STATE.md" >&2
  exit 2
fi

HEAD="$(git -C "$CLAUDE_REPO" rev-parse HEAD)"
echo "recorded source commit : $BASE"
echo "claude repo HEAD       : $HEAD"
echo

STATUS=0

# --- 1. commit delta on the paths we mirror -------------------------------
MIRRORED_PATHS=(.claude/agents .claude/jsonui-rules .claude/jsonui-workflow.md skills)
if [ "$HEAD" = "$BASE" ]; then
  echo "== commit delta: none (HEAD == recorded commit)"
else
  echo "== Claude commits since recorded sync:"
  git -C "$CLAUDE_REPO" log --oneline "$BASE..$HEAD" -- "${MIRRORED_PATHS[@]}" || true
  echo
  echo "== Claude files changed since recorded sync (need porting):"
  CHANGED="$(git -C "$CLAUDE_REPO" diff --name-status "$BASE" "$HEAD" -- "${MIRRORED_PATHS[@]}")"
  if [ -n "$CHANGED" ]; then
    echo "$CHANGED"
    STATUS=1
  else
    echo "(none — only unmirrored paths changed)"
  fi
fi
echo

# --- 2. verbatim mirror content check (skills/, rules/) -------------------
echo "== content check: skills/ (verbatim mirror) and rules/ vs Claude HEAD"
echo "   (expected diffs are listed in SYNC_STATE.md 'Intentional divergences')"
DIFFS=0

# skills/<...> maps 1:1
while IFS= read -r f; do
  rel="${f#skills/}"
  if [ ! -f "$ROOT/skills/$rel" ]; then
    echo "MISSING  skills/$rel"
    DIFFS=$((DIFFS+1))
  elif ! git -C "$CLAUDE_REPO" show "$HEAD:$f" 2>/dev/null | cmp -s - "$ROOT/skills/$rel"; then
    echo "DIFFERS  skills/$rel"
    DIFFS=$((DIFFS+1))
  fi
done < <(git -C "$CLAUDE_REPO" ls-tree -r --name-only "$HEAD" skills/)

# .claude/jsonui-rules/<f>.md -> rules/<f>.md
while IFS= read -r f; do
  rel="rules/${f#.claude/jsonui-rules/}"
  if [ ! -f "$ROOT/$rel" ]; then
    echo "MISSING  $rel"
    DIFFS=$((DIFFS+1))
  elif ! git -C "$CLAUDE_REPO" show "$HEAD:$f" 2>/dev/null | cmp -s - "$ROOT/$rel"; then
    echo "DIFFERS  $rel"
    DIFFS=$((DIFFS+1))
  fi
done < <(git -C "$CLAUDE_REPO" ls-tree -r --name-only "$HEAD" .claude/jsonui-rules/)

if [ "$DIFFS" -eq 0 ]; then
  echo "(no content differences)"
fi
echo
echo "note: agents/*.toml and AGENTS.md are adapted (not verbatim) — review the"
echo "      commit delta above for .claude/agents/ and .claude/jsonui-workflow.md."

exit $STATUS
