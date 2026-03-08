---
name: jsonui-spec-review
description: Reviews implementation against specification and reports differences. Compares actual code with .spec.json to identify discrepancies.
tools: Read, Glob, Grep
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

### Step 2: Read Specification

Read the specification JSON and extract:
- `structure.components` - Expected components
- `structure.layout` - Expected hierarchy
- `stateManagement.uiVariables` - Expected data variables
- `stateManagement.eventHandlers` - Expected handlers
- `dataFlow.apiEndpoints` - Expected API calls

### Step 3: Read Implementation

Read the actual implementation files:

1. **Layout JSON** - `Layouts/{ScreenName}.json`
   - Extract actual component IDs and types
   - Extract actual hierarchy
   - Extract `data` section properties

2. **ViewModel** - `ViewModel/{ScreenName}/{ScreenName}ViewModel.swift|kt|tsx`
   - Extract actual event handler methods
   - Extract actual API calls
   - Extract actual state management

### Step 4: Compare and Report

Generate a detailed report of differences:

```
## Specification Review: {ScreenName}

### Summary
- Components: {matched}/{total} match
- Data Variables: {matched}/{total} match
- Event Handlers: {matched}/{total} match
- Overall: {PASS|NEEDS_UPDATE}

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
- Overall: PASS

No differences found. Specification matches implementation.
```

**If differences found:**
Output the full diff report as shown above.

## Important Rules

- **Read-only** - This skill does NOT modify any files
- **Be thorough** - Check every component, variable, and handler
- **Be specific** - Report exact IDs, types, and names
- **Be actionable** - Recommendations should be clear enough for spec update
- **No assumptions** - Report only what is actually different, not what "should" be
- **Check both directions** - Report both "added in impl" and "missing in impl"

## Example Usage Flow

1. Implementation agent completes viewmodel step
2. Implementation agent invokes `/jsonui-spec-review`
3. This skill reports differences
4. If differences exist, implementation agent invokes `/jsonui-screen-spec` with the diff report
5. `/jsonui-screen-spec` updates the specification JSON
