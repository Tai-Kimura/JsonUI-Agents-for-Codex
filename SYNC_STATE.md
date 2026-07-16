# Sync state — Codex mirror of JsonUI-Agents-for-claude

This repository is a **Codex CLI adaptation** of the Claude Code agent pack.
The Claude repository is the source of truth for all content; this repo only
adapts the packaging and reference syntax.

<!-- machine-readable — scripts/check_sync.sh parses these two lines -->
source_repo: JsonUI-Agents-for-claude
source_commit: 85f0f54d36fd301f433fdb02a87eed879fc5de5b

- **Last sync date:** 2026-07-16
- **Source commit subject:** `docs(test agent): artifacts pull/status + test_artifacts_pull MCP tool`

Run `scripts/check_sync.sh /path/to/JsonUI-Agents-for-claude` to see what has
changed on the Claude side since the recorded commit.

## File mapping

| Claude (source of truth) | Codex (this repo) | Transform |
|---|---|---|
| `.claude/agents/jsonui-<name>.md` | `agents/<name>.toml` | YAML frontmatter → TOML shell (`allowed_tools`, `model_reasoning_effort`, `sandbox_mode`); markdown body → `developer_instructions = '''...'''` with reference adaptations (below) |
| `.claude/jsonui-rules/<name>.md` | `rules/<name>.md` | verbatim, except `mcp-policy.md` "Declaring MCP tools in agents" section (rewritten as Codex variant: `allowed_tools` array + `.codex/config.toml` registration) |
| `.claude/jsonui-workflow.md` | `AGENTS.md` | rewritten as the Codex workflow entry (multi-agent `/agent` model); keep routing content aligned when the Claude side changes |
| `skills/<name>/SKILL.md` (+ `examples/`) | `skills/<name>/SKILL.md` (+ `examples/`) | verbatim (skills already use `rules/...` paths and CLI names) |
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
| `rules/specification-rules.md` | `BarCellView`, `bars_collection`, `bar_cell_root`, `barName`/`shotPrice` (+ JP labels), `bar_list/bar_cell` | `ItemCellView`, `items_collection`, `item_cell_root`, `itemName`/`unitPrice`, `item_list/item_cell` |
| `rules/file-locations.md` | consumer FQN example / `BarLegacy*` | `com.example.myapp.model` / `ItemLegacy*` (upstream genericized the FQN to `com.example.app.model` in 7db7a9e — spelling-only difference) |
| `skills/jsonui-layout/examples/strings-json.json` | whisky-flavored sample string | neutral wording |
| `agents/implement.toml` | domain-flavored Domain accessor example (`displayAbv`/`abv`) | `displayRating`/`rating` |
| `agents/test.toml` | fixture example schema `` `Bar` `` | `` `Product` `` |
| `agents/navigation-{ios,android,web}.toml` | whisky-domain route examples (`WhiskyDetail`, `TastingForm`, `Bottle`, `/whisky/[id]`, `/tasting/…`) | `ProductDetail`, `ReviewForm`, `Product`, `/product/[id]`, `/review/…` |
| `agents/debug.toml` / `agents/define.toml` | "bar search" example / `"bar_list"` layoutFile example | "product search" / `"item_list"` |
| `rules/specification-rules.md` (5) | markdown link into JsonUIDocument's `.claude/` path | plain-prose reference |
| `rules/specification-rules.md` HARD RULE | `jsonui-implement` agent ref | `/agent implement` |
| `rules/mcp-policy.md` | Claude frontmatter example in "Declaring MCP tools in agents" | Codex-variant section (structural, per mapping table) |

When the Claude side genericizes these itself, drop the corresponding row.

## Sync procedure (next time)

1. `scripts/check_sync.sh <claude-checkout>` → list of changed source files.
2. For skills: copy changed files verbatim (re-apply any divergence rows above).
3. For rules: copy verbatim except the `mcp-policy.md` Codex-variant section.
4. For agents: apply the Claude commit diff hunk-by-hunk onto the matching
   `agents/<name>.toml` `developer_instructions`, applying the reference
   adaptations table; mirror `tools:` frontmatter changes into `allowed_tools`.
5. Gates before committing:
   - `python3 -c 'import tomllib,glob; [tomllib.load(open(f,"rb")) for f in glob.glob("agents/*.toml")]'`
   - `grep -rn '\.claude/' agents/ rules/ skills/ AGENTS.md` → must be empty
   - grep for consumer identifiers (whisky/liquor/tanosys/pango/otta, project
     domain nouns, `/Users/` paths) → must be empty
6. Update `source_commit` + date in this file.
