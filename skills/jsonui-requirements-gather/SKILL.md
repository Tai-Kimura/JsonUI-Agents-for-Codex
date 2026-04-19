---
name: jsonui-requirements-gather
description: Gathers screen definitions through dialogue one screen at a time. Saves each screen's requirements immediately after confirmation.
tools: Read, Write, Glob, Grep
---

# JsonUI Requirements Gather Skill

## Purpose

Gather screen definitions from users through friendly dialogue. **Process ONE screen at a time** and save requirements immediately after each screen is confirmed.

The requirements document structure matches the `screen-spec-template.json` format, making it easy to convert requirements to specifications later.

## CRITICAL: Read Template First

**Before starting, read the spec template to understand the target structure:**

```
Read: {skill_directory}/examples/screen-spec-template.json
```

This template defines the structure that requirements will eventually be converted to.

## CRITICAL: One Screen at a Time

**You MUST complete and save each screen before moving to the next:**

1. Gather requirements for ONE screen
2. Confirm with user
3. **IMMEDIATELY save to `docs/requirements/{screen_name}.md`**
4. Ask if there are more screens
5. Repeat

**NEVER gather requirements for multiple screens before saving.**

## Input Variables

- `platforms` - Target platforms (iOS, Android, Web)
- `app_concept` - Basic app idea from user
- `project_directory` - Where to save documents
- `skill_directory` - Path to this skill's directory

## Workflow

### Phase 1: Introduction

Confirm what you're building:

```
I'll help you define the screens for "{app_concept}".
Target platform(s): {platforms}

Let's design your screens one by one.
I'll save each screen's requirements as we complete them.
```

### Phase 2: Screen Name & Purpose

Ask about the screen:

```
What is the first (or main) screen of your app?

For example:
- "Login screen"
- "Home dashboard"
- "Product list"

What screen would you like to define, and what is its purpose?
```

### Phase 3: Layout & Sections

```
How is the "{screen_name}" screen organized?

For example:
- Header at the top with title and back button
- Main content area in the middle
- Bottom navigation bar

What sections does this screen have?
```

### Phase 4: Components (UI Elements)

For each section identified, ask:

```
What elements appear in the {section_name}?

For example:
- Text labels (title, description, etc.)
- Input fields (text box, dropdown, etc.)
- Buttons (submit, cancel, etc.)
- Images or icons
- Lists or tables

Please list what the user sees in this section.
```

### Phase 5: User Actions

```
What actions can users take on this screen?

For example:
- Tap a button → submit form
- Select an item from a list → view details
- Enter text in a field → update value

What interactions does this screen support?
```

### Phase 6: Navigation (Transitions)

```
Where can users go from this screen?

List the possible destinations:
- Button tap → goes to {screen}
- List item tap → goes to {screen}
- Back button → goes to {screen}

Any special animations when navigating?
```

### Phase 7: Data Flow

```
What data does this screen need?

1. **Input data** - Data passed from previous screen
2. **API calls** - Data fetched from server
3. **User input** - Data entered on this screen
4. **Output data** - Data passed to next screen

Where does the data come from and go?
```

### Phase 8: State Management

```
What state does this screen need to track?

For example:
- Loading state (showing spinner while fetching)
- Form values (what user has entered)
- Error state (showing error messages)
- Selection state (which item is selected)

What local state does this screen manage?
```

### Phase 9: Validation

```
What validation is needed on this screen?

For example:
- Email must be valid format
- Required fields must be filled
- Password must be 8+ characters

What rules should be enforced, and when?
(on submit / on blur / on change)
```

### Phase 10: Review and Confirm

Summarize the screen definition:

```
Here's the "{screen_name}" screen definition:

**Purpose:** {description}

**Layout:**
{sections}

**Components:**
{list of components by section}

**User Actions:**
{actions and their effects}

**Navigation:**
{navigation paths}

**Data Flow:**
- Input: {input data}
- API: {api calls}
- Output: {output data}

**State:**
{local state}

**Validation:**
{validation rules}

Is this correct? Would you like to change anything?
```

### Phase 11: SAVE IMMEDIATELY (MANDATORY)

**After user confirms, you MUST IMMEDIATELY save the requirements file.**

Create: `{project_directory}/docs/requirements/{screen_name}.md`

Use this template (matches screen-spec-template.json structure):

```markdown
# {Screen Name} Requirements

## Metadata
- **Screen Name:** {screen_name}
- **Screen ID:** {screen_id} (snake_case)
- **Description:** {purpose}
- **Platforms:** {platforms}
- **Tags:** {relevant tags}

## Components

### {Section Name}

| ID | Type | Description | Data Binding | Events |
|----|------|-------------|--------------|--------|
| {id} | {type} | {description} | {binding} | {events} |

## Layout

- **Type:** {vertical/horizontal/grid/absolute}
- **Sections:**
  1. {section1} - {components}
  2. {section2} - {components}
  3. {section3} - {components}

## Data Flow

### Inputs
| Name | Type | Source | Required |
|------|------|--------|----------|
| {name} | {type} | {previous screen / navigation params} | {yes/no} |

### Outputs
| Name | Type | Destination | Trigger |
|------|------|-------------|---------|
| {name} | {type} | {next screen / API} | {action} |

### API Calls
| Endpoint | Method | Request Params | Response Mapping | Error Handling |
|----------|--------|----------------|------------------|----------------|
| {endpoint} | {GET/POST/PUT/DELETE} | {params} | {mapping} | {error handling} |

## State Management

### Local State
| Name | Type | Initial Value | Description |
|------|------|---------------|-------------|
| {name} | {type} | {initial} | {description} |

### Shared State
| Name | Scope | Type |
|------|-------|------|
| {name} | {app/module} | {type} |

## User Actions

| Action ID | Trigger | Component | Handler | Effects |
|-----------|---------|-----------|---------|---------|
| {id} | {tap/longPress/change} | {component} | {handler} | {effects} |

## Validation

### Rules
| Field | Rules | Error Message |
|-------|-------|---------------|
| {field} | {rules} | {message} |

### Form Validation
- **Validate On:** {submit/blur/change}
- **Show Errors:** {inline/toast/alert}

## Transitions

### Entry Animation
{description or "none"}

### Exit Animation
{description or "none"}

### Navigation
| Target | Trigger | Params |
|--------|---------|--------|
| {screen} | {action} | {params} |

## Accessibility
- **Screen Reader Text:** {description}
- **Focus Order:** {order}

## Notes
{any additional notes or open questions}
```

**After saving, report:**

```
✓ Saved: docs/requirements/{screen_name}.md

Do you have more screens to define?
1. Yes, define another screen
2. No, I'm done
```

### Phase 12: Next Screen or Complete

If user wants more screens → Go back to Phase 2

If user is done → Go to Phase 13

### Phase 13: Generate Summary

Create summary file: `{project_directory}/docs/requirements/screens-summary.md`

```markdown
# Screen Requirements Summary

## Overview
- **App:** {app_concept}
- **Platforms:** {platforms}
- **Total Screens:** {count}

## Screen List

| Screen | ID | Description | Main Actions |
|--------|-----|-------------|--------------|
| {screen1} | {id1} | {purpose} | {main actions} |
| {screen2} | {id2} | {purpose} | {main actions} |

## Screen Flow

```
{screen1} --({action})--> {screen2}
{screen2} --({action})--> {screen3}
```

## Data Flow Overview

| Screen | Input From | Output To |
|--------|------------|-----------|
| {screen1} | - | {screen2} |
| {screen2} | {screen1} | {screen3}, API |

## Shared State

| State Name | Used By | Type |
|------------|---------|------|
| {state} | {screens} | {type} |

## Files Created

- docs/requirements/{screen1}.md
- docs/requirements/{screen2}.md
- docs/requirements/screens-summary.md

## Next Steps

1. Review requirements with stakeholders
2. Create screen specifications (spec.json) from these requirements
3. Begin implementation
```

**Final report:**

```
Requirements gathering complete!

Files created:
- docs/requirements/{screen1}.md
- docs/requirements/{screen2}.md
- docs/requirements/screens-summary.md

Total screens defined: {count}

Next steps:
1. Review the requirements in docs/requirements/
2. Run specification creation to generate spec.json files
3. Begin implementation
```

---

## Important Rules

- **ONE screen at a time** - Complete and save before moving to next
- **Save IMMEDIATELY after confirmation** - Do NOT wait until all screens are done
- **One question at a time** - Never ask multiple questions together
- **Simple language** - Avoid technical jargon
- **Use examples** - Always provide concrete examples
- **Confirm before saving** - Always ask "Is this correct?" before saving
- **User's language** - Respond in the language the user uses
- **Match spec template** - Requirements structure should map to screen-spec-template.json

---

## If User Doesn't Know

When user is unsure, provide suggestions:

```
No problem! Here are some common patterns:

1. {option1} - {description}
2. {option2} - {description}
3. {option3} - {description}

Which one sounds closest? Or feel free to say "I'm not sure" - that's okay too.
```

---

## Component Type Reference

When asking about components, reference these common types:

- **Text**: label, title, heading, paragraph
- **Input**: textField, textArea, dropdown, checkbox, radio, switch, datePicker
- **Button**: button, iconButton, floatingButton
- **Media**: image, icon, video
- **Container**: card, section, list, grid, scrollView
- **Navigation**: tabBar, navbar, drawer, breadcrumb

## Data Type Reference

Common data types to use:

- **Primitives**: string, number, boolean
- **Collections**: array, object
- **Special**: date, email, url, phone
