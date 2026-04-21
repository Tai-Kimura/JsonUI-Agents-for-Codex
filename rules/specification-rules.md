# Specification Rules

## Absolute Rules for All Specification Work

These rules must be followed by ALL agents and skills that create or modify specification documents.

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

### 3. Examples

**Wrong:**
```
User: "Add a login button"
Agent: [Creates a blue rounded button with "Login" text, centered, 200px wide]
```

**Correct:**
```
User: "Add a login button"
Agent: "I'll add a login button. A few questions:
1. What should the button text be? (e.g., 'Login', 'Sign In', 'Log In')
2. Where should it be positioned in the layout?
3. Any specific styling requirements?"
```

**Wrong:**
```
User: "The form should validate email"
Agent: [Implements email validation with specific regex, error messages, and styling]
```

**Correct:**
```
User: "The form should validate email"
Agent: "For email validation, I need to confirm:
1. What error message should be displayed for invalid emails?
2. When should validation occur? (on blur, on submit, real-time)
3. Are there any specific email format requirements beyond standard validation?"
```

## Why This Matters

- Specifications are the **single source of truth**
- Incorrect assumptions propagate to all downstream agents
- Fixing misinterpretations later is expensive
- The user knows their requirements better than we do

---

## Custom Components — spec first, then `jui g converter`

Any Layout JSON node whose `type` is **not** a standard JsonUI component (e.g. `CodeBlock`, `NavLink`, `Collapse`, `Details`, `PlatformBadge`, `NetworkImage`) is a **custom component**. Custom components MUST be introduced in this order. Skipping steps produces a converter whose attributes don't match the actual component — layouts render wrong or emit invalid JSX.

### 1. Write a `component_spec` FIRST

Before any layout or screen spec references the custom type:

```
mcp__jui-tools__doc_init_component with name: "CodeBlock", category: "display", displayName: "Code block"
```

Creates `{component_spec_directory}/codeblock.component.json`. Fill in:

- `metadata.name` (PascalCase), `displayName`, `description`, `category`
- `props.items[]` — every attribute the layout can pass. `name` camelCase, `type` is a spec type (`String`, `Int`, `Bool`, `String?`, `[String]`, `(() -> Void)?`).
- `slots.items[]` — non-empty = container (renders children); empty = leaf.

Validate with `mcp__jui-tools__doc_validate_component`.

### 2. Generate the converter FROM the spec

```bash
jui g converter --from codeblock.component.json   # single spec
jui g converter --all                             # every component spec
```

The spec-driven path reads `props.items[]` → `--attributes` and `slots.items[]` non-empty → `--container`. **Never pass `--attributes` by hand** in production — it defeats the lockstep between the component's contract and the generated converter.

### 3. Register in `.jsonui-doc-rules.json` (doc-site / non-JsonUI projects)

```json
{ "rules": { "componentTypes": { "screen": ["CodeBlock", "…"] } } }
```

### 4. THEN write layouts / screen specs that reference it

Only after 1-3 may a screen spec or Layout JSON reference `{"type": "CodeBlock", "language": "bash", "code": "…"}`.

If you find a Layout using a custom `type` with no matching `component_spec`, stop the current task, run Task 4 of `/agent define` for the missing component, then continue. Do not try to reverse-engineer the converter from the layout alone.
