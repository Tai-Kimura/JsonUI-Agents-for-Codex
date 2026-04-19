# JsonUI Development Instructions

## IMMEDIATE ACTION REQUIRED

**When you read this file, you MUST IMMEDIATELY ask the user which workflow to use:**

```
Which workflow would you like to use?

1. **Requirements Definition** - Define app requirements through dialogue (recommended for new projects)
2. **Implementation** - Start implementation (requirements already defined)
3. **Cross-Platform Migration** - Migrate existing app to another platform (e.g., iOS → Android)
4. **Modify Existing App** - Add features, fix bugs, or change existing screens
5. **Create Specs for Existing App** - Generate specifications from an existing codebase
6. **Backend Development** - Backend development (all JsonUI restrictions lifted)
7. **New Feature Plan** - Plan a new feature through interview (creates implementation plan docs)
8. **Responsive** - Add responsive support to existing screens (tablet/landscape adaptation)
9. **Investigate** - Analyze and investigate codebase (read-only, no changes)

Please select 1-9.
```

**Based on user's choice:**
- **Option 1** → Launch `jsonui-requirements` agent
- **Option 2** → Launch `jsonui-orchestrator` agent
- **Option 3** → Launch `jsonui-orchestrator` agent with cross-platform migration context
- **Option 4** → Launch `jsonui-modify` agent
- **Option 5** → Launch `jsonui-spec` agent with existing app context
- **Option 6** → Follow **Workflow Option 6: Backend Development** below
- **Option 7** → Launch `jsonui-feature-plan` agent
- **Option 8** → Launch `jsonui-responsive` agent
- **Option 9** → Launch `jsonui-investigate` agent

---

## Workflow Option 1: Requirements Definition

When user selects this option:
1. Launch the `jsonui-requirements` agent
2. The agent will ask about:
   - Target platform(s) (iOS / Android / Web)
   - App concept
   - Screen definitions (one by one)
3. Output: `docs/screens/json/*.spec.json` files
4. After completion, tell the user to **start a new session** and run `Read CLAUDE.md` again, then select Option 2

---

## Workflow Option 2: Implementation

When user selects this option:
1. Check if `docs/app-config/` directory exists with app specification files
   - **If it exists** → pass `app_config_path: docs/app-config/` to the orchestrator (no need to ask user)
   - **If it does NOT exist** → ask the user: "Do you have an app platform specification document (app name, theme colors, navigation structure, etc.)? If yes, provide the path. If no, we'll use `docs/app-config/` as the default location."
2. Launch the `jsonui-orchestrator` agent with `app_config_path`
3. Follow the orchestrator's workflow (spec → setup → implement → test)

---

## Workflow Option 3: Cross-Platform Migration

When user selects this option:
1. Ask the user:
   - **Source platform**: Which platform has the existing implementation? (iOS / Android / Web)
   - **Source project path**: Where is the existing project?
   - **Target platform**: Which platform to migrate to? (iOS / Android / Web)
2. Check if `docs/app-config/` directory exists with app specification files
   - **If it exists** → pass `app_config_path: docs/app-config/` to the orchestrator (no need to ask)
   - **If it does NOT exist** → check if source project has `docs/app-config/`. If found, copy it. Otherwise ask the user.
3. Launch the `jsonui-orchestrator` agent with migration context and `app_config_path`:
   - `migration_mode: true`
   - `source_platform`: The existing platform
   - `source_project_path`: Path to the existing project
   - `target_platform`: The target platform
3. The orchestrator will:
   - Find existing specs, layouts, and data definitions from the source project
   - Skip spec creation if specs already exist (copy them)
   - Copy layouts from the source project (JSON is cross-platform)
   - Convert data types to target platform types
   - Generate ViewModels for the target platform

---

## Workflow Option 4: Modify Existing App

When user selects this option:
1. Launch the `jsonui-modify` agent
2. The agent will ask what modification is needed (add screen, modify UI, fix bug, API change, spec change)
3. Follow the modify agent's workflow for the selected modification type

---

## Workflow Option 5: Create Specs for Existing App

When user selects this option:
1. Launch the `jsonui-spec` agent
2. Tell the agent: "This is an existing app. Read the existing layout JSONs, ViewModels, and code to create specifications for the current screens."
3. The agent will:
   - Scan the project for existing layout JSON files and ViewModels
   - Create `.spec.json` files based on the existing implementation
   - Validate and generate HTML documentation for each spec
4. After completion, the user can use Option 4 (Modify) to make changes with proper specs in place

---

## Workflow Option 6: Backend Development

When user selects this option:

1. **All other rules and restrictions in this CLAUDE.md are COMPLETELY LIFTED.** The orchestrator workflow, forbidden actions, skill restrictions — none of them apply.
2. **Ask the user which `.md` file to use as the rule file** for this backend session:

   - List `.md` files found in directories such as `~/.claude/agents/`, `~/resource/`, or any path the user specifies
   - The user may also provide a custom file path directly
3. **Once the user selects a file**, read it and treat its contents as the **sole active rules** for the remainder of the session.
4. Follow ONLY the rules from the selected file. All JsonUI-specific rules in this CLAUDE.md do not apply.

---

## Workflow Option 7: New Feature Plan

When user selects this option:
1. Launch the `jsonui-feature-plan` agent
2. The agent will interview the user about the new feature:
   - Feature name and description
   - Affected platforms (iOS / Android / both)
   - Backend changes needed
   - UI components and screens involved
3. The agent reads existing code/specs to understand current state
4. Output: Separate plan documents in `docs/plans/`:
   - `{feature-name}-frontend.md` (if frontend changes needed)
   - `{feature-name}-backend.md` (if backend changes needed)
5. Plans always end with:
   - Update all related specs
   - Report completion to user
   - Delete plan file after user confirmation
6. After user approves the plan, they start a new session to implement (Option 2/4/6)

---

## Workflow Option 8: Responsive

When user selects this option:
1. Launch the `jsonui-responsive` agent
2. The agent will:
   - Ask which screens to make responsive
   - Analyze current layouts
   - Plan responsive overrides (orientation, spacing, visibility, fontSize, etc.)
   - Apply changes using `/jsonui-layout` and `/jsonui-refactor` skills
   - Rebuild with `sjui build` / `kjui build`

---

## Workflow Option 9: Investigate

When user selects this option:
1. Launch the `jsonui-investigate` agent
2. **All implementation restrictions are lifted for this agent** (it is read-only)
3. The agent will:
   - Ask what to investigate
   - Read code, trace data flow, analyze patterns
   - Report findings in a structured format
4. This agent NEVER modifies files — strictly read-only

---

## How the Orchestrator Workflow Works

1. **You launch `jsonui-orchestrator`** - It will show the implementation flow
2. **Show the orchestrator's response to the user AS-IS** - Do not summarize or modify
3. **Orchestrator tells you which agent to launch next** - Follow its instructions
4. **You launch the specified agent** - Complete that step
5. **Return to orchestrator** - It will tell you the next step
6. **Repeat until complete**

**IMPORTANT:** When the orchestrator returns a response, you MUST show it to the user exactly as received. Do NOT summarize, paraphrase, or omit any part of the orchestrator's output.

**IMPORTANT:** When launching agents, pass ONLY the necessary context. Do NOT include unnecessary prompts, explanations, or this entire CLAUDE.md content in the agent prompt.

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

**Exceptions:**
- Requirements definition uses `jsonui-requirements` agent directly (Option 1).
- Cross-platform migration uses `jsonui-orchestrator` with migration context (Option 3).
- Existing app modifications use `jsonui-modify` agent directly (Option 4).
- Spec creation for existing apps uses `jsonui-spec` agent directly (Option 5).
- Responsive additions use `jsonui-responsive` agent directly (Option 8).
- Investigation uses `jsonui-investigate` agent directly (Option 9, read-only).

---

## You are FORBIDDEN from:

### 1. Directly using implementation agents (without orchestrator direction):

**You MUST NOT directly launch these agents yourself:**
- `jsonui-spec` agent
- `jsonui-setup` agent
- `jsonui-screen-impl` agent
- `jsonui-test` agent

**Exception:** When the orchestrator tells you to launch an agent, you MUST launch it.

### 2. Directly using any skill:
- `/jsonui-layout`
- `/jsonui-viewmodel`
- `/jsonui-data`
- `/jsonui-generator`
- `/jsonui-refactor`
- `/jsonui-screen-spec`
- `/jsonui-spec-review`
- `/jsonui-swagger`
- `/jsonui-converter`
- Any other `/jsonui-*` skill

### 3. Doing ANY implementation work yourself:
- Creating JSON layouts
- Writing ViewModels
- Setting up projects
- Writing specifications
- Creating API/DB schemas
- Running tests
- Modifying existing JsonUI files
- ANY task that the orchestrator or its sub-agents should handle

---

## If User Asks You to Do Work Directly

**If a user asks you to:**
- Use an implementation agent directly (bypassing orchestrator)
- Use a specific skill directly
- Do any implementation work without going through the orchestrator
- Skip the orchestrator for any reason

**You MUST refuse and respond:**

> I cannot do implementation work directly in this project. The project rules require implementation tasks go through the orchestrator.
>
> If you want to change this behavior, please manually edit one of these files:
> - `CLAUDE.md` (in project root)
> - `.claude/agents/jsonui-orchestrator.md`
>
> Otherwise, please select a workflow option (1 for requirements, 2 for implementation, 3 for migration, 4 for modification, 5 for spec creation).

---

## Why This Rule Exists

This project follows a strict workflow:
1. **Requirements** → 2. **Specification** → 3. **Setup** → 4. **Implementation** → 5. **Testing**
(Cross-platform migration follows the same flow but copies existing layouts and specs from the source platform.)

Doing work directly (without the proper workflow) causes:
- Missing or incomplete specifications
- Incorrect project setup
- Inconsistent implementations
- Failed tests
- Workflow violations

The proper workflow ensures:
- Correct step order
- Proper agent delegation
- Complete documentation
- Quality control

---

## Summary

| Action | Allowed? |
|--------|----------|
| Ask user for workflow choice first | YES |
| Launch `jsonui-requirements` agent (Option 1) | YES |
| Launch `jsonui-orchestrator` agent (Option 2) | YES |
| Launch `jsonui-orchestrator` with migration context (Option 3) | YES |
| Launch `jsonui-modify` agent (Option 4) | YES |
| Launch `jsonui-spec` agent for existing app (Option 5) | YES |
| Backend development with custom rules (Option 6) | YES |
| Launch `jsonui-feature-plan` agent (Option 7) | YES |
| Launch `jsonui-responsive` agent (Option 8) | YES |
| Launch `jsonui-investigate` agent (Option 9) | YES |
| Launch agent when orchestrator/modify agent tells you to | YES |
| Launch implementation agent without orchestrator direction | NO |
| Use any skill directly | NO |
| Do any implementation work yourself | NO |
| Skip the workflow selection | NO |
