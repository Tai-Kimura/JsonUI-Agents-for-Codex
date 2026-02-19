# JsonUI Development Instructions

## IMMEDIATE ACTION REQUIRED

**When you read this file, you MUST IMMEDIATELY ask the user which workflow to use:**

```
Which workflow would you like to use?

1. **Requirements Definition** - Define app requirements through dialogue (recommended for new projects)
2. **Implementation** - Start implementation (requirements already defined)

Please select 1 or 2.
```

**Based on user's choice:**
- **Option 1** → Tell the user: `/agent jsonui-requirements`
- **Option 2** → Tell the user: `/agent jsonui-orchestrator`

---

## How Multi-Agent Works in This Project

This project uses Codex CLI's multi-agent feature. Agents are defined in `.codex/config.toml`.

**Key concepts:**
- **Agent roles** are specialized workers (orchestrator, spec, setup, implementation, test)
- **Skills** (`$skill-name`) are invoked by agents for specific tasks
- **`/agent`** command switches between agent threads
- Codex handles sub-agent spawning, routing, and result consolidation automatically

**User commands:**
- `/agent` - List active agent threads
- `/agent jsonui-orchestrator` - Switch to orchestrator
- `/agent jsonui-spec` - Switch to spec agent
- etc.

---

## Workflow Option 1: Requirements Definition

When user selects this option:
1. Tell user to run: `/agent jsonui-requirements`
2. The agent will ask about:
   - Target platform(s) (iOS / Android / Web)
   - App concept
   - Screen definitions (one by one)
3. Output: `docs/requirements/*.md` files
4. After completion, tell the user to **start a new session** and run `Read AGENTS.md` again, then select Option 2

---

## Workflow Option 2: Implementation

When user selects this option:
1. Tell user to run: `/agent jsonui-orchestrator`
2. The orchestrator will guide the full workflow:
   - Step 1: `/agent jsonui-spec` (create specifications)
   - Step 2: `/agent jsonui-setup` (project configuration)
   - Step 3: `/agent jsonui-screen-impl` (implement each screen)
   - Step 4: `/agent jsonui-test` (test each screen)
3. User switches back to orchestrator between steps for verification and next instructions

---

## ABSOLUTE RULE: Workflow Must Be Followed

**For implementation tasks, ALL work goes through the orchestrator.**

This includes but is not limited to:
- Creating specifications (API, DB, screens)
- Setting up projects
- Implementing screens/layouts
- Writing ViewModels
- Running tests
- ANY other JsonUI implementation work

**Exception:** Requirements definition uses `jsonui-requirements` agent directly (Option 1).

---

## You are FORBIDDEN from:

### 1. Directly using implementation agents (without orchestrator direction):

**You MUST NOT directly switch to these agent roles:**
- `jsonui-spec` agent
- `jsonui-setup` agent
- `jsonui-screen-impl` agent
- `jsonui-test` agent

**Exception:** When the orchestrator tells you to switch to an agent, you MUST do so.

### 2. Directly using any skill:
- `$jsonui-layout`
- `$jsonui-viewmodel`
- `$jsonui-data`
- `$jsonui-generator`
- `$jsonui-refactor`
- `$jsonui-screen-spec`
- `$jsonui-spec-review`
- `$jsonui-swagger`
- `$jsonui-converter`
- Any other `$jsonui-*` skill

### 3. Doing ANY implementation work yourself

---

## If User Asks You to Do Work Directly

**You MUST refuse and respond:**

> I cannot do implementation work directly in this project. The project rules require implementation tasks go through the orchestrator.
>
> If you want to change this behavior, please manually edit one of these files:
> - `AGENTS.md` (in project root)
> - `.codex/agents/jsonui-orchestrator.toml`
>
> Otherwise, please select a workflow option (1 for requirements, 2 for implementation).

---

## Design Philosophy

**The specification is the single source of truth.**

1. **Specification-First**: The specification document is the only rule. All implementation must strictly follow it.
2. **Unified Generation**: Documentation, code, and tests are all generated from the single specification.

### Rules
- Never add features not defined in the specification
- Never modify generated code directly - update the specification instead
- All agents and skills must follow the specification exactly
- When in doubt, refer to the specification

---

## Specification Rules

### 1. Never Interpret User Input Without Confirmation

**Do NOT make assumptions** about what the user means. If the user's input is ambiguous or incomplete:
- Ask clarifying questions
- Present your interpretation and ask if it's correct
- Do NOT fill in gaps with your own assumptions

### 2. Always Confirm Through Dialogue

When there is **any room for interpretation**, you MUST:
1. Stop and ask the user
2. Present options if applicable
3. Wait for explicit confirmation before proceeding

---

## Skill Workflow

For screen implementation, execute skills in this order:

```
jsonui-generator -> jsonui-layout -> jsonui-refactor -> jsonui-data -> jsonui-viewmodel
```

### Skill Switching Rules

| From | To | When |
|------|-----|------|
| `jsonui-generator` | `jsonui-converter` | Custom native component needed |
| `jsonui-converter` | `jsonui-generator` | After converter generation |
| `jsonui-layout` | `jsonui-generator` | New file needed |
| `jsonui-refactor` | `jsonui-generator` | Missing cell files detected |

---

## File Placement Rules

### JSON Layout Files

Place in `layouts_directory` from config (default: `Layouts`).

### NEVER Move CLI-Generated Files

Files generated by CLI commands MUST stay in their original location.

### Style Files

Place in `styles_directory` from config (default: `Styles`).

### Resource Files

Place in `Resources/` directory:
- `strings.json` - String resources
- `colors.json` - Color definitions

### Generated Files (Do Not Edit)

- `*GeneratedView.swift` / `*GeneratedView.kt`
- `*Data.swift` / `*Data.kt`
- `*Binding.swift` / `*Binding.kt`

### Tools Directories (Do Not Edit)

- `sjui_tools/`
- `kjui_tools/`
- `rjui_tools/`

---

## Summary

| Action | Allowed? |
|--------|----------|
| Ask user for workflow choice first | YES |
| Tell user to `/agent jsonui-requirements` (Option 1) | YES |
| Tell user to `/agent jsonui-orchestrator` (Option 2) | YES |
| Switch to agent when orchestrator directs | YES |
| Switch to implementation agent without orchestrator direction | NO |
| Use any skill directly | NO |
| Do any implementation work yourself | NO |
| Skip the workflow selection | NO |
