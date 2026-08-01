# MCP Tool Policy

JsonUI agents call the `jsonui-mcp-server` (the `jui-tools` MCP) to interact with specs, layouts, and the build pipeline. Bash shell-outs to the `jui` CLI are a last resort.

---

## MCP-first

| Action | Prefer | Bash fallback |
|---|---|---|
| Read project config | `mcp__jui-tools__get_project_config` | — |
| List specs / layouts / components | `mcp__jui-tools__list_screen_specs`, `list_layouts`, `list_component_specs` | — |
| Read spec / layout files | `mcp__jui-tools__read_spec_file`, `read_layout_file` | — |
| Look up components / attributes | `mcp__jui-tools__lookup_component`, `lookup_attribute`, `search_components` | — |
| Screen identity rules (what is a screen, ids, `assert:"screen"`) | `mcp__jui-tools__get_screen_identity` | `jui screens` |
| Create spec / component template | `mcp__jui-tools__doc_init_spec`, `doc_init_component` | — |
| Generate screen scaffold from spec | `mcp__jui-tools__jui_generate_screen` | `jui g screen` |
| Generate Layout JSON + VM stubs | `mcp__jui-tools__jui_generate_project` | — |
| Generate custom converter | `mcp__jui-tools__jui_generate_converter` | `jui g converter` (incl. `--skip-existing`) |
| Build + distribute | `mcp__jui-tools__jui_build` | — |
| Verify spec ↔ layout | `mcp__jui-tools__jui_verify` | — |
| Migrate platform layouts | `mcp__jui-tools__jui_migrate_layouts` | `jui migrate-layouts` |
| Sync project-local platform tools with ~/.jsonui-cli/ | `mcp__jui-tools__jui_sync_tool` | `jui sync_tool` |
| Validate spec | `mcp__jui-tools__doc_validate_spec`, `doc_validate_component` | — |
| Generate docs | `mcp__jui-tools__doc_generate_spec`, `doc_generate_html` | — |
| Lint @generated markers | — | `jui lint-generated` (CI only) |
| List swagger / OpenAPI files | `mcp__jui-tools__list_api_specs` | `jui ls api-specs --json` |
| List generated DTO + Domain files (with orphan detection) | `mcp__jui-tools__list_api_models` | `jui ls api-models --json` |
| Preview swagger filter + emit plan without writing | `mcp__jui-tools__preview_api_model_sync` | `jui g api --dry-run --json` |
| Pull run artifacts (screenshots / recordings) | `mcp__jui-tools__test_artifacts_pull` | `jsonui-test artifacts pull` |
| Show artifacts config + already-pulled files | `mcp__jui-tools__test_artifacts_status` | `jsonui-test artifacts status` |
| Regenerate API mocks from swagger | `mcp__jui-tools__test_mock_generate` | `jsonui-test mock generate` |
| Validate test files (always `no_install: true`) | `mcp__jui-tools__test_validate` | `jsonui-test validate --no-install` |

Only **one** `jui` subcommand has no MCP equivalent today: `jui lint-generated`. Everything else goes through MCP.

---

## Declaring MCP tools in agents (Codex variant)

Codex CLI agents declare their allowed tools in the agent's `.toml` file via the `allowed_tools` array. MCP tools appear as `mcp__<server>__<tool>`.

**Pattern: explicit enumeration** (recommended)

List only the MCP tools each agent actually needs. This keeps prompt tokens low and focuses the agent.

```toml
# agents/define.toml
model_reasoning_effort = "high"
sandbox_mode = "workspace-write"

allowed_tools = [
  "Read",
  "Write",
  "Edit",
  "Glob",
  "Grep",
  "mcp__jui-tools__get_project_config",
  "mcp__jui-tools__list_screen_specs",
  "mcp__jui-tools__read_spec_file",
  "mcp__jui-tools__doc_init_spec",
  "mcp__jui-tools__doc_validate_spec",
  "mcp__jui-tools__doc_generate_spec",
  "mcp__jui-tools__jui_verify",
  "mcp__jui-tools__lookup_component",
  "mcp__jui-tools__lookup_attribute",
  "mcp__jui-tools__search_components",
]

developer_instructions = """..."""
```

Register the agent in `.codex/config.toml`:

```toml
[agents.define]
description = "..."
config_file = "agents/define.toml"
```

**Avoid:** wildcard `mcp__jui-tools__*`. It loads all 42 tool schemas into the prompt, wasting tokens and increasing agent confusion.

**Avoid:** allowing every built-in tool. Only grant `Write` / `Edit` / `Bash` when the agent genuinely needs them.

> **Claude variant:** Claude Code agents use YAML frontmatter's `tools:` field instead of `allowed_tools`. The tool names and discipline are identical; only the declaration syntax differs.

---

## Per-agent MCP tool inventory

Generated from each agent's `allowed_tools` in `agents/*.toml` — the `allowed_tools` array is canonical. After changing an agent's tools, run `scripts/contract_check.py --fix` to refresh this table (CI fails on drift). Tool names are sorted; non-MCP tools (Read, Bash, ...) are governed by the sections below, and `debug` is READ-ONLY by contract regardless of this table.

<!-- inventory:begin — generated from agent allowed_tools; edit the agent .toml, then run scripts/contract_check.py --fix -->
| Agent | MCP tools |
|---|---|
| `conductor` | `get_project_config`, `list_api_models`, `list_api_specs`, `list_component_specs`, `list_layouts`, `list_screen_specs` |
| `debug` | `doc_validate_spec`, `get_platform_mapping`, `get_project_config`, `jui_build`, `jui_verify`, `list_api_models`, `list_api_specs`, `list_component_specs`, `list_layouts`, `list_screen_specs`, `lookup_attribute`, `lookup_component`, `preview_api_model_sync`, `read_layout_file`, `read_spec_file`, `search_components` |
| `define` | `doc_generate_component`, `doc_generate_spec`, `doc_init_component`, `doc_init_spec`, `doc_rules_init`, `doc_rules_show`, `doc_validate_component`, `doc_validate_spec`, `get_project_config`, `jui_verify`, `list_api_specs`, `list_component_specs`, `list_screen_specs`, `lookup_attribute`, `lookup_component`, `preview_api_model_sync`, `read_spec_file`, `search_components` |
| `ground` | `get_project_config`, `jui_build`, `jui_init` |
| `implement` | `get_binding_rules`, `get_modifier_order`, `get_platform_mapping`, `get_project_config`, `jui_build`, `jui_generate_project`, `jui_verify`, `list_api_models`, `list_api_specs`, `list_layouts`, `list_screen_specs`, `lookup_attribute`, `lookup_component`, `read_layout_file`, `read_spec_file`, `search_components` |
| `navigation-android` | `get_platform_mapping`, `get_project_config`, `get_screen_identity`, `jui_build`, `list_screen_specs`, `read_layout_file`, `read_spec_file` |
| `navigation-ios` | `get_platform_mapping`, `get_project_config`, `get_screen_identity`, `jui_build`, `list_screen_specs`, `read_layout_file`, `read_spec_file` |
| `navigation-web` | `get_platform_mapping`, `get_project_config`, `get_screen_identity`, `jui_build`, `list_screen_specs`, `read_layout_file`, `read_spec_file` |
| `test` | `doc_generate_html`, `get_project_config`, `get_screen_identity`, `list_layouts`, `list_screen_specs`, `read_layout_file`, `read_spec_file`, `test_artifacts_pull`, `test_artifacts_status`, `test_mock_generate`, `test_validate` |
<!-- inventory:end -->

---

## Test tooling: agent use of the test_* MCP tools

The MCP server exposes eight `test_*` tools. Agent consumption is deliberate, not implied — a tool not listed as agent-consumed stays unused by agents until this policy changes:

**Agent-consumed** (declared by `test`):

- `test_artifacts_pull` / `test_artifacts_status` — collect and inspect run artifacts
- `test_mock_generate` — regenerate `generated/` mocks from the swagger
- `test_validate` — validate test files, **always with `no_install: true`**. The wrapper's default (like the CLI's) installs tests as a side effect, and authoring-time validation must not consume the files. Servers built before 2026-08-01 do not know the parameter and **silently drop it** (the SDK's zod validation strips unknown keys), so the install runs anyway — if validation appears to install despite `no_install: true`, update `~/.jsonui-mcp-server` (`bash ~/.jsonui-mcp-server/install.sh`) and restart before trusting this path.

**Deliberately not agent-consumed:**

- `test_generate_screen` / `test_generate_flow` / `test_generate_description` — template scaffolders for humans working without the pack. Agents author complete files via the `jsonui-screen-test` / `jsonui-flow-test` / `jsonui-test-doc` skills; a skeleton adds nothing.
- `test_report` — converts run results to JUnit / HTML. That is a runner / CI stage after execution, outside agent authoring scope.

---

## Bash tool policy

Include `Bash` in the `tools:` frontmatter when the agent needs the one remaining uncovered CLI command (`jui lint-generated`, typically CI-only), or needs to run platform-specific native commands (e.g. `xcodebuild`, `./gradlew`, `npm run dev`, `git`, `rbenv` diagnostics). Every other `jui` / `jsonui-doc` operation is an MCP call — prefer that.

- `ground`: needs Bash for initial platform scaffolding
- `debug`: needs Bash for impl-side grep and CI-style checks
- `navigation-*`: may need Bash for platform-native build verification
- `implement`: may need Bash for platform-native runs alongside the MCP build gate
- `test`: needs Bash for running platform test suites (`jsonui-test validate --no-install` stays available as the human/CI fallback, but agent validation goes through `test_validate`)

`conductor` and `define` stay Bash-free.

---

## MCP server availability

Agents assume the `jsonui-mcp-server` is installed and running. If an MCP call fails because the server is unreachable, the agent should:

1. Surface the failure to the user with a clear message
2. Suggest installing / starting the server
3. **Do not** silently fall back to Bash for the same operation (that hides misconfiguration)

---

## Future extensions

The MCP server is expected to gain `lookup_spec_section`, `get_dataflow_linkage_rules`, `get_viewmodel_protocol_rules`, etc. (see `docs/plans/agent-redesign.md`). When they land, skills that currently duplicate spec schema documentation in their prompts should be rewritten to call these MCP tools instead.
