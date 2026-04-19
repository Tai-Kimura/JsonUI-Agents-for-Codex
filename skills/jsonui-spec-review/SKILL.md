---
name: jsonui-spec-review
description: Reviews implementation against specification and reports differences. Uses jui verify for automated comparison, then manual analysis for deeper review.
tools: Read, Glob, Grep, Bash
---

# Specification Review Skill

## Role

Compare the actual implementation with the specification JSON and report all differences. This skill does NOT modify files - it only reports discrepancies.

## When to Use

Use this skill after implementation is complete (after viewmodel step) to:
1. Compare what was actually implemented vs what was specified
2. Generate a detailed diff report
3. Provide input for specification updates

## Workflow

### Step 1: Gather Inputs

Required inputs:
- `tools_directory`: Path to CLI tools
- `screen_name`: Name of the screen to review (lowercase)
- `spec_path`: Path to specification (default: `docs/screens/json/{screenname}.spec.json`)
- `layouts_directory`: Path to shared Layout JSON directory

### Step 2: Automated Comparison with jui verify

**First, run the automated diff tool:**

```bash
jui verify --file {screen_name}.spec.json --detail
```

This compares the spec against the Layout JSON in the shared `layouts_directory` and reports:
- Missing/extra components
- Type mismatches
- Data property differences
- Event handler differences

**If `jui verify` reports no differences and the scope is limited to layout, you may skip manual comparison.**

### Step 3: Read Specification

Read the specification JSON and extract:
- `structure.components` - Expected components (with children, style, binding)
- `structure.layout` - Expected hierarchy (including overlay)
- `structure.decorativeElements` - Expected decorative elements
- `structure.wrapperViews` - Expected wrapper views
- `stateManagement.uiVariables` - Expected data variables
- `stateManagement.eventHandlers` - Expected handlers
- `stateManagement.displayLogic` - Expected visibility rules (with variableName)
- `dataFlow.apiEndpoints` - Expected API calls

### Step 4: Read Implementation

Read the actual implementation files:

1. **Layout JSON** - `{layouts_directory}/{screen_name}.json` (shared directory)
   - Extract actual component IDs and types
   - Extract actual hierarchy
   - Extract `data` section properties
   - Check for `platform` overrides
   - Check cell layouts in `{layouts_directory}/{screen_name}/` subdirectory

2. **ViewModel** - `ViewModel/{ScreenName}/{ScreenName}ViewModel.swift|kt|tsx`
   - Extract actual event handler methods
   - Extract actual API calls
   - Extract actual state management

### Step 5: Compare and Report

Generate a detailed report of differences:

```
## Specification Review: {ScreenName}

### Summary
- Components: {matched}/{total} match
- Data Variables: {matched}/{total} match
- Event Handlers: {matched}/{total} match
- jui verify: {PASS|differences found}
- Overall: {PASS|NEEDS_UPDATE}

### jui verify Output
{paste jui verify --detail output here}

### Component Differences

**Added in Implementation (not in spec):**
- `{component_id}` ({ComponentType}) - {description if available}

**Missing in Implementation (in spec but not implemented):**
- `{component_id}` ({ComponentType})

**Changed:**
- `{component_id}`: type changed from `{spec_type}` to `{impl_type}`
- `{component_id}`: id changed from `{spec_id}` to `{impl_id}`

### Data Variable Differences

**Added in Implementation:**
- `{varName}`: {Type} - {usage context}

**Missing in Implementation:**
- `{varName}`: {Type}

**Changed:**
- `{varName}`: type changed from `{spec_type}` to `{impl_type}`

### Event Handler Differences

**Added in Implementation:**
- `{onHandlerName}` - {what it does}

**Missing in Implementation:**
- `{onHandlerName}`

**Renamed:**
- `{spec_name}` → `{impl_name}`

### Layout Hierarchy Differences

**Spec:**
```
{spec hierarchy tree}
```

**Implementation:**
```
{impl hierarchy tree}
```

### API Endpoint Differences

**Added:**
- `{METHOD} {path}`

**Missing:**
- `{METHOD} {path}`

### Recommendations

1. {Specific recommendation for spec update}
2. {Specific recommendation for spec update}
...
```

## Output Format

The report should be structured so that `/jsonui-screen-spec` can use it directly to update the specification.

**If no differences found:**
```
## Specification Review: {ScreenName}

### Summary
- Components: {n}/{n} match
- Data Variables: {n}/{n} match
- Event Handlers: {n}/{n} match
- jui verify: PASS
- Overall: PASS

No differences found. Specification matches implementation.
```

**If differences found:**
Output the full diff report as shown above.

## Important Rules

- **Read-only** - This skill does NOT modify any files
- **Run jui verify first** - Use automated comparison before manual analysis
- **Read from layouts_directory** - Layout JSON is in the shared directory, NOT platform copies
- **Be thorough** - Check every component, variable, and handler
- **Be specific** - Report exact IDs, types, and names
- **Be actionable** - Recommendations should be clear enough for spec update
- **No assumptions** - Report only what is actually different, not what "should" be
- **Check both directions** - Report both "added in impl" and "missing in impl"

## Example Usage Flow

1. Implementation agent completes viewmodel step
2. Implementation agent runs `jui verify --file {spec} --detail`
3. Implementation agent invokes `/jsonui-spec-review` for deeper analysis
4. This skill reports differences
5. If differences exist, implementation agent invokes `/jsonui-screen-spec` with the diff report
6. `/jsonui-screen-spec` updates the specification JSON
