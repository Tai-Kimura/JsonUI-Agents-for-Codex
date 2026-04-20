# JsonUI Agents for Codex CLI

A curated set of 9 specialized agents and 11 authoring skills for Codex CLI, driving JsonUI framework development across iOS (SwiftUI/UIKit), Android (Compose/XML), and Web (React/Next.js).

Claude Code variant: [JsonUI-Agents-for-claude](https://github.com/Tai-Kimura/JsonUI-Agents-for-claude). Design is identical; only the invocation syntax differs.

## Installation

```bash
# Install from main
curl -H "Cache-Control: no-cache" -sL "https://raw.githubusercontent.com/Tai-Kimura/JsonUI-Agents-for-Codex/main/install.sh?$(date +%s)" | bash

# Branch / commit / tag
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -b develop
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -c abc123
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -v 1.0.0
```

Enable Codex CLI's multi-agent feature (`/experimental` → toggle on, or add `[features] multi_agent = true` to `~/.codex/config.toml`), then:

```
Read AGENTS.md
```

You'll be asked to pick a workflow. Three of the four route through `/agent conductor`, which inspects the repo via MCP and tells you which specialized agent to switch to next.

## Directory layout

```
.
├── AGENTS.md              # Entry point
├── .codex/config.toml     # Agent registry
├── agents/                # 9 agents (.toml)
├── skills/                # 11 authoring skills
└── rules/                 # 5 rule files
```

## Agents (9)

| Agent | R/W | Responsibility |
|---|---|---|
| `conductor` | R | Entry point — reads repo state via MCP and routes to the right sub-agent |
| `define` | W | Spec authoring (screen / component / API/DB / doc-rules), validate, HTML docs |
| `ground` | W | `jui init`, platform scaffolding, test runner setup |
| `implement` | W | Layout / Styles / VM body + localize + `jui build` (0 warnings) + `jui verify` (no drift) |
| `navigation-ios` | W | SwiftUI NavigationStack / UIKit UINavigationController |
| `navigation-android` | W | Compose Navigation / XML NavGraph |
| `navigation-web` | W | React Router / Next.js App Router |
| `test` | W | Screen / flow test authoring + validation + HTML docs |
| `debug` | R | READ-ONLY spec-first bug trace, behavior walks, code archaeology |

Switch between them with `/agent <name>`. All agents are MCP-first — they call the `jsonui-mcp-server` for spec / layout reads, lookups, generation, build, verify. Bash shell-outs to the `jui` CLI are reserved for the four commands without MCP wrappers.

## Skills (11)

Authoring guides invoked from agents via `$skill-name`.

| Skill | Used by | Purpose |
|---|---|---|
| `jsonui-screen-spec` | `define` | Screen `.spec.json` authoring |
| `jsonui-component-spec` | `define` | Reusable component spec |
| `jsonui-swagger` | `define` | API / DB OpenAPI |
| `jsonui-dataflow` | `define`, `implement`, `debug` | `dataFlow.{viewModel,repositories,useCases,apiEndpoints}` + Mermaid linkage |
| `jsonui-layout` | `implement` | Layout JSON + Styles + includes |
| `jsonui-viewmodel-impl` | `implement` | VM / Repository / UseCase method body (signatures stay in spec) |
| `jsonui-localize` | `implement` | user-visible string extraction + `strings.json` registration |
| `jsonui-platform-setup` | `ground` | Consolidated platform + test runner setup |
| `jsonui-screen-test` | `test` | Screen test JSON authoring |
| `jsonui-flow-test` | `test` | Flow test JSON (multi-screen journey) |
| `jsonui-test-doc` | `test` | Description JSON + HTML docs |

## Rules (4 invariants)

Detailed rules in [`rules/`](rules/).

1. **`jui build` must pass with zero warnings.**
2. **`jui verify --fail-on-diff` must pass with no drift.**
3. **`@generated` files are never edited by hand.** Edit the spec; `jui build` regenerates.
4. **`$jsonui-localize` must run before a screen is declared done.**

See [`rules/invariants.md`](rules/invariants.md) and [`rules/mcp-policy.md`](rules/mcp-policy.md).

## Codex specifics

- Agent definitions are `.toml` files in `agents/`, registered in `.codex/config.toml`.
- Agent switching: `/agent <name>` (user-driven; Codex does not auto-spawn sub-agents like Claude Code does).
- Skill invocation: `$skill-name` in agent instructions. Skills themselves live in `skills/<name>/SKILL.md` with YAML frontmatter.
- Per-agent tool allowlists are declared via `allowed_tools = [...]` in each agent's `.toml`.

## Typical flow

```
Read AGENTS.md
  ↓ (workflow 1-3)
/agent conductor   — inspects repo via MCP
  ↓ tells user which /agent to switch to
┌──────────┬──────────┬──────────┬────────┬────────┐
│ ground   │ define   │ implement│ test   │ debug  │
│ (setup)  │ (spec)   │ (code)   │ (test) │ (R/O)  │
└──────────┴──────────┴──────────┴────────┴────────┘
                               │
                               ├→ navigation-ios / android / web
                               │
                               └→ jui build (0 warnings) → jui verify (no drift)
```

One screen at a time. No batching.

## Design principle

**Spec is the single source of truth for intent + contract. Layout JSON is the SSoT for UI structure. Everything else is generated, checked, or gated.**

See [`docs/plans/agent-redesign.md`](https://github.com/Tai-Kimura/JsonUI-Agents-for-claude/blob/main/docs/plans/agent-redesign.md) in the Claude variant repo for the full design rationale (shared with Codex).

## Related repos

### Frameworks
- [SwiftJsonUI](https://github.com/Tai-Kimura/SwiftJsonUI) — iOS (SwiftUI / UIKit)
- [KotlinJsonUI](https://github.com/Tai-Kimura/KotlinJsonUI) — Android (Compose / XML Views)
- [ReactJsonUI](https://github.com/Tai-Kimura/ReactJsonUI) — Web (React / Tailwind CSS)

### CLI tooling
- [jsonui-cli](https://github.com/Tai-Kimura/jsonui-cli) — `jui`, `sjui_tools`, `kjui_tools`, `rjui_tools`, `jsonui-doc`
- [jsonui-mcp-server](https://github.com/Tai-Kimura/jsonui-mcp-server) — MCP wrapper around `jui` and related tools

### Test runners
- [jsonui-test-runner](https://github.com/Tai-Kimura/jsonui-test-runner) — CLI + HTML doc generator
- [jsonui-test-runner-ios](https://github.com/Tai-Kimura/jsonui-test-runner-ios) — XCUITest driver
- [jsonui-test-runner-android](https://github.com/Tai-Kimura/jsonui-test-runner-android) — UIAutomator driver
- [jsonui-test-runner-web](https://github.com/Tai-Kimura/jsonui-test-runner-web) — Playwright driver

### Claude Code variant
- [JsonUI-Agents-for-claude](https://github.com/Tai-Kimura/JsonUI-Agents-for-claude) — same design for Claude Code (`.md` agents, Task-tool spawning, `/skill` invocation)

## License

MIT
