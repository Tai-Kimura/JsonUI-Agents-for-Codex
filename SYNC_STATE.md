# Sync state — Codex mirror of JsonUI-Agents-for-claude

This repository is a **Codex CLI adaptation** of the Claude Code agent pack.
The Claude repository is the source of truth for all content; this repo only
adapts the packaging and reference syntax.

<!-- machine-readable — scripts/check_sync.sh parses these two lines -->
source_repo: JsonUI-Agents-for-claude
source_commit: 98d205e2610d68684fc9c683d46e56d3c71ff1fe

- **Last sync date:** 2026-09-29
- **Source commit subject:** `rules + define: jsonui-cli 1.9.3's wider set of texts-file prose fields and the validator's new refusals`
- **Note on this sync:** ports 98d205e (ee48b81 on the PR branch; GitHub's rebase merge rewrote the SHA, the tree is the same): `rules/specification-rules.md` "Long prose: texts files" gains the prose-field table (purpose, processing, handling, rule, meaning, note, reason, a transition's condition) and the validator's new refusals, plus the `search_specs` line (verbatim); `agents/define.toml` Task 2's texts bullet matches `jsonui-define.md` with the rules path adapted. The sync before: 52a7cdc (55ae058 on the PR branch, same tree) — `rules/specification-rules.md` gains "Long prose: texts files" (verbatim), `skills/jsonui-screen-spec/SKILL.md` its unitContracts pointer (verbatim), and `agents/define.toml` Task 2 the same bullet as `jsonui-define.md` with the rules path adapted. b0afde7 (invariants: the coverage gate line prints 1.9.0) was already ported as f480590, so the recorded commit moves past it too. The sync before: 2fe7d75 — (landed with jsonui-cli 1.9.1): jsonui-test B2.4 — from 1.9.1 the generated web rows wait with `settleQuiet`, and a hand-written test's `settle()` / `settle(n)` is 1.8.120's turn-based wait again. `agents/test.toml` carries the same text (the sentence has no agent reference). The syncs before it: 77f857b (from 1.9.1 `--fail-on-diff` counts the initial values; an include's data under its id's prefix), 65481a2 (thirty 1.9.0 units and 1.9.1's web nested-tap sentence; one line of `rules/invariants.md` keeps the announced gate name), then c8a8865, 1917e23 and 2f61608 (landed with jsonui-cli 1.8.120).

Run `scripts/check_sync.sh /path/to/JsonUI-Agents-for-claude` to see what has
changed on the Claude side since the recorded commit.

## File mapping

| Claude (source of truth) | Codex (this repo) | Transform |
|---|---|---|
| `.claude/agents/jsonui-<name>.md` | `agents/<name>.toml` | YAML frontmatter → TOML shell (`allowed_tools`, `model_reasoning_effort`, `sandbox_mode`); markdown body → `developer_instructions = '''...'''` with reference adaptations (below) |
| `.claude/jsonui-rules/<name>.md` | `rules/<name>.md` | verbatim, except two `mcp-policy.md` spots: the "Declaring MCP tools in agents" section (rewritten as Codex variant: `allowed_tools` array + `.codex/config.toml` registration) and the generated inventory block's prose/marker (frontmatter/`contract_check.sh` → `allowed_tools`/`contract_check.py`; regenerate with `scripts/contract_check.py --fix`, table rows come out identical) |
| `.claude/jsonui-workflow.md` | `AGENTS.md` | rewritten as the Codex workflow entry (multi-agent `/agent` model); keep routing content aligned when the Claude side changes |
| `skills/<name>/SKILL.md` (+ `examples/`) | `skills/<name>/SKILL.md` (+ `examples/`) | verbatim (skills already use `rules/...` paths and CLI names) |
| `scripts/gen-skill-action-tables.mjs` | `scripts/gen-skill-action-tables.mjs` | verbatim (repo-root-relative by design; regenerates the marker blocks in the two test skills from the jsonui-test-runner pin recorded inside it — both CIs run it in check mode) |
| `.claude/commands/jsonui.md` | — (covered by `AGENTS.md` + `/agent conductor`) | not mirrored |
| `.claude/settings.json` | — | not mirrored (Claude-harness-only) |
| `install.sh`, `installer/` | `install.sh` | independent per-repo installers; not content-synced |

## Reference adaptations (applied inside mirrored bodies)

| Claude form | Codex form |
|---|---|
| `jsonui-<agent>` agent reference (e.g. `` `jsonui-define` ``) | `` `/agent <agent>` `` (e.g. `` `/agent define` ``); `jsonui-navigation-{ios,android,web}` → `navigation-{ios,android,web}` |
| `/jsonui-<skill>` skill invocation | `$jsonui-<skill>` |
| `.claude/jsonui-rules/<file>.md` | `rules/<file>.md` |
| `.claude/jsonui-workflow.md` | `AGENTS.md` |
| Agent doc heading `# X Agent` | `# X Agent (Codex)` as the first line of `developer_instructions` |
| `tools:` frontmatter list | `allowed_tools` TOML array (keep MCP tool names identical) |
| Links into `.claude/` paths of sibling repos | flattened to prose (no `.claude/` paths in this repo) |

MCP tool names (`mcp__jui-tools__*`), CLI names (`jui`, `jsonui-test`), and
skill names are identical on both sides — never translate those.

## Intentional divergences from the Claude source (public-repo hygiene)

Consumer-project identifiers are genericized in this repo. Current list
(check_sync.sh will report these files as "differs" — that is expected):

| File | Claude source | This repo |
|---|---|---|
| `rules/specification-rules.md` | `jsonui-implement` (Claude agent name in the dataFlow prose) | `/agent implement` (Codex invocation; the consumer-flavored examples were genericized on the Claude side too in b3b9b4c — vocabulary now matches verbatim) |
| `rules/file-locations.md` | the FQN example `com.example.app.model` | `com.example.myapp.model` (spelling-only difference) |
| `agents/navigation-{ios,android,web}.toml` | domain-flavored route examples (product detail / review form / product routes) | `ProductDetail`, `ReviewForm`, `Product`, `/product/[id]`, `/review/…` |
| `rules/specification-rules.md` (5) | markdown link into JsonUIDocument's `.claude/` path | plain-prose reference |
| `rules/specification-rules.md` HARD RULE | `jsonui-implement` agent ref | `/agent implement` |
| `rules/mcp-policy.md` | Claude frontmatter example in "Declaring MCP tools in agents"; inventory prose/marker names frontmatter + `contract_check.sh` | Codex-variant section; inventory prose/marker names `allowed_tools` + `contract_check.py` (structural, per mapping table) |

When the Claude side genericizes these itself, drop the corresponding row.

## Sync procedure (next time)

1. `scripts/check_sync.sh <claude-checkout>` → list of changed source files.
2. For skills: copy changed files verbatim (re-apply any divergence rows above).
3. For rules: copy verbatim except the two `mcp-policy.md` spots above; after
   copying it, re-run `scripts/contract_check.py --fix` so the inventory block
   carries this repo's marker and matches `allowed_tools`.
4. For agents: apply the Claude commit diff hunk-by-hunk onto the matching
   `agents/<name>.toml` `developer_instructions`, applying the reference
   adaptations table; mirror `tools:` frontmatter changes into `allowed_tools`.
5. Gates before committing:
   - `python3 scripts/contract_check.py` → OK (tool declarations, name
     resolution, example existence, inventory table)
   - `python3 -c 'import tomllib,glob; [tomllib.load(open(f,"rb")) for f in glob.glob("agents/*.toml")]'`
   - `grep -rn '\.claude/' agents/ rules/ skills/ AGENTS.md` → must be empty
   - grep for downstream identifiers (project names and product-domain nouns —
     the concrete list is kept privately, not in this repo — plus `/Users/` paths) → must be empty
6. Update `source_commit` + date in this file.
