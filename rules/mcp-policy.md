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
| Create spec / component template | `mcp__jui-tools__doc_init_spec`, `doc_init_component` | — |
| Generate screen scaffold from spec | `mcp__jui-tools__jui_generate_screen` | `jui g screen` |
| Generate Layout JSON + VM stubs | `mcp__jui-tools__jui_generate_project` | — |
| Generate custom converter | `mcp__jui-tools__jui_generate_converter` | `jui g converter` |
| Build + distribute | `mcp__jui-tools__jui_build` | — |
| Verify spec ↔ layout | `mcp__jui-tools__jui_verify` | — |
| Migrate platform layouts | `mcp__jui-tools__jui_migrate_layouts` | `jui migrate-layouts` |
| Sync project-local platform tools with ~/.jsonui-cli/ | `mcp__jui-tools__jui_sync_tool` | `jui sync_tool` |
| Validate spec | `mcp__jui-tools__doc_validate_spec`, `doc_validate_component` | — |
| Generate docs | `mcp__jui-tools__doc_generate_spec`, `doc_generate_html` | — |
| Lint @generated markers | — | `jui lint-generated` (CI only) |

Only **one** CLI command has no MCP equivalent today: `jui lint-generated`. Everything else goes through MCP.

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

**Avoid:** wildcard `mcp__jui-tools__*`. It loads all 30 tool schemas into the prompt, wasting tokens and increasing agent confusion.

**Avoid:** allowing every built-in tool. Only grant `Write` / `Edit` / `Bash` when the agent genuinely needs them.

> **Claude variant:** Claude Code agents use YAML frontmatter's `tools:` field instead of `allowed_tools`. The tool names and discipline are identical; only the declaration syntax differs.

---

## Per-agent MCP tool inventory

| Agent | MCP tools |
|---|---|
| `conductor` | `get_project_config`, `list_screen_specs`, `list_layouts`, `list_component_specs` |
| `define` | `doc_init_spec`, `doc_init_component`, `doc_validate_spec`, `doc_validate_component`, `doc_generate_spec`, `read_spec_file`, `lookup_component`, `lookup_attribute`, `search_components`, `jui_verify` |
| `ground` | `jui_init`, `jui_sync_tool`, `get_project_config` |
| `implement` | `jui_generate_project`, `jui_build`, `jui_verify`, `read_spec_file`, `read_layout_file`, `list_layouts`, `lookup_component`, `lookup_attribute`, `get_binding_rules`, `get_modifier_order`, `get_platform_mapping` |
| `navigation-ios` / `navigation-android` / `navigation-web` | `read_spec_file`, `read_layout_file`, `list_screen_specs`, `get_platform_mapping` |
| `test` | `list_screen_specs`, `read_spec_file`, `doc_generate_html` |
| `debug` (READ-ONLY) | `get_project_config`, `list_screen_specs`, `list_layouts`, `read_spec_file`, `read_layout_file`, `jui_verify`, `jui_build`, `doc_validate_spec`, `lookup_component`, `lookup_attribute`, `search_components` (+ `Read, Bash, Glob, Grep` for impl grep) |

Agents that do not appear in this table should still follow the "explicit enumeration" pattern.

---

## Bash tool policy

Include `Bash` in the `tools:` frontmatter when the agent needs the one remaining uncovered CLI command (`jui lint-generated`, typically CI-only), or needs to run platform-specific native commands (e.g. `xcodebuild`, `./gradlew`, `npm run dev`, `git`, `rbenv` diagnostics). Every other `jui` / `jsonui-doc` operation is an MCP call — prefer that.

- `ground`: needs Bash for initial platform scaffolding
- `debug`: needs Bash for impl-side grep and CI-style checks
- `navigation-*`: may need Bash for platform-native build verification

All other agents should not declare Bash.

---

## MCP server availability

Agents assume the `jsonui-mcp-server` is installed and running. If an MCP call fails because the server is unreachable, the agent should:

1. Surface the failure to the user with a clear message
2. Suggest installing / starting the server
3. **Do not** silently fall back to Bash for the same operation (that hides misconfiguration)

---

## Future extensions

The MCP server is expected to gain `lookup_spec_section`, `get_dataflow_linkage_rules`, `get_viewmodel_protocol_rules`, etc. (see `docs/plans/agent-redesign.md`). When they land, skills that currently duplicate spec schema documentation in their prompts should be rewritten to call these MCP tools instead.
