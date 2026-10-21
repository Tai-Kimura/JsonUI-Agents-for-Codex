#!/usr/bin/env bash
# test_install.sh — install.sh's -s (one skill) against a pack built from this checkout, offline.
#
#   bash scripts/test_install.sh
#
# The pack tarball is made from the files git knows here (tracked and new, not ignored), served through
# JSONUI_AGENTS_TARBALL_URL=file://… (install.sh's own testing hook). Each case runs install.sh in a fresh temp
# project and compares what it should and should not have written, by content (sha256), not by time. This pack
# installs into the project root (.codex/config.toml, agents/, skills/, rules/, AGENTS.md), so every file of the
# project is compared.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT="$(pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
FAIL=0
fail() { printf 'FAIL %s\n' "$*" >&2; FAIL=1; }
ok() { printf 'ok   %s\n' "$*"; }
if command -v sha256sum >/dev/null; then SUM=(sha256sum); else SUM=(shasum -a 256); fi

mkdir -p "$WORK/pack/x"
git ls-files -co --exclude-standard -z | (cd "$ROOT" && xargs -0 tar -cf -) | tar -xf - -C "$WORK/pack/x"
tar -czf "$WORK/pack.tar.gz" -C "$WORK/pack" x
export JSONUI_AGENTS_TARBALL_URL="file://$WORK/pack.tar.gz"
SKILL="$(basename "$(ls -d "$ROOT"/skills/*/ | head -1)")"
OTHER="$(basename "$(ls -d "$ROOT"/skills/*/ | sed -n 2p)")"

# every file of the project except one skill's folder, by content
snapshot() { (cd "$1" && find . -type f ! -path "./skills/$2/*" -print0 | sort -z | xargs -0 "${SUM[@]}"); }

project() {   # a project with the whole pack installed, then made its own: config.toml and AGENTS.md edited,
  local p="$WORK/$1"   # a file of theirs in another skill, an agent edited, the target skill removed
  mkdir -p "$p" && (cd "$p" && bash "$ROOT/install.sh" >/dev/null) || { fail "full install for $1"; return 1; }
  printf '\n# my own setting\n[agents]\n' >> "$p/.codex/config.toml"
  echo "<!-- local -->" >> "$p/AGENTS.md"
  echo "mine" > "$p/skills/$OTHER/notes.md"
  echo "# local edit" >> "$p/agents/define.toml"
  rm -rf "$p/skills/$SKILL"
  echo "$p"
}

# 1. -s adds the one skill, byte for byte, and nothing else changes (config.toml and AGENTS.md included)
p="$(project one)" && {
  before="$(snapshot "$p" "$SKILL")"
  out="$(cd "$p" && bash "$ROOT/install.sh" -s "$SKILL" 2>&1)" || fail "-s $SKILL exited $?: $out"
  diff -r "$ROOT/skills/$SKILL" "$p/skills/$SKILL" >/dev/null && ok "-s writes skills/$SKILL as the pack has it" \
    || fail "skills/$SKILL differs from the pack"
  [ "$before" = "$(snapshot "$p" "$SKILL")" ] && ok "-s leaves every other file byte for byte (config.toml, AGENTS.md, agents, other skills)" \
    || fail "-s changed a file outside skills/$SKILL: $(diff <(echo "$before") <(snapshot "$p" "$SKILL") | head -3)"
}

# 2. a name the pack does not have writes nothing and lists the pack's skills
p="$(project unknown)" && {
  before="$(cd "$p" && find . -type f -print0 | sort -z | xargs -0 "${SUM[@]}")"
  out="$(cd "$p" && bash "$ROOT/install.sh" -s "$SKILL" -s no-such-skill 2>&1)"; code=$?
  after="$(cd "$p" && find . -type f -print0 | sort -z | xargs -0 "${SUM[@]}")"
  [ "$code" -eq 1 ] && [ "$before" = "$after" ] && [ ! -e "$p/skills/$SKILL" ] \
    && ok "an unknown name exits 1 and writes nothing (not even the known one beside it)" \
    || fail "unknown name: exit $code, changed: $([ "$before" = "$after" ] && echo no || echo yes)"
  grep -q "no skill named 'no-such-skill'" <<<"$out" && grep -q "^  $SKILL$" <<<"$out" && ok "it names the skills the pack has" \
    || fail "unknown name's message: $out"
}

# 3. a name that is a path to a folder the pack has is refused
p="$(project path)" && {
  out="$(cd "$p" && bash "$ROOT/install.sh" -s "../agents" 2>&1)"; code=$?
  [ "$code" -eq 1 ] && ok "-s ../agents (a folder the pack has, outside skills/) is refused" || fail "-s ../agents exited $code"
}

# 4. -s repeats; an empty project gets only skills/<names>
p="$WORK/bare" && mkdir -p "$p" && {
  out="$(cd "$p" && bash "$ROOT/install.sh" -s "$SKILL" -s "$OTHER" 2>&1)" || fail "-s twice exited $?: $out"
  got="$(cd "$p" && find . -type f | sed 's#^\./##' | cut -d/ -f1-2 | sort -u | tr '\n' ' ')"
  [ "$got" = "skills/$SKILL skills/$OTHER " ] && ok "-s twice writes the two skills and nothing else" \
    || fail "-s twice wrote: $got"
}

# 5. without -s the installer still installs the whole pack (the full install is unchanged)
p="$WORK/full" && mkdir -p "$p" && (cd "$p" && bash "$ROOT/install.sh" >/dev/null) && {
  [ "$(ls "$p/skills" | wc -l | tr -d ' ')" = "$(ls -d "$ROOT"/skills/*/ | wc -l | tr -d ' ')" ] \
    && [ -f "$p/.codex/config.toml" ] && [ -f "$p/AGENTS.md" ] \
    && ok "without -s: every skill, config.toml and AGENTS.md, as before" || fail "the full install changed"
}

[ "$FAIL" -eq 0 ] && echo "install test: OK" || { echo "install test: FAILED" >&2; exit 1; }
