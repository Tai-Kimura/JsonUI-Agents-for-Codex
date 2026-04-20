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
