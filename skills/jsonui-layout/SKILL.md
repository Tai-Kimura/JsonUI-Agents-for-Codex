---
name: jsonui-layout
description: Expert in implementing JSON layouts for JsonUI frameworks. Creates correct view structures, validates attributes, and ensures proper binding syntax across SwiftJsonUI, KotlinJsonUI, and ReactJsonUI.
tools: Read, Write, MultiEdit, Bash, Glob, Grep
---

# JsonUI Layout Agent

Specialized in correct JSON layout implementation. For refactoring, use the `jsonui-refactor` agent.

## Rule Reference

Read the following rule files first:
- `rules/file-locations.md` - File placement rules

## Input Parameters

Received from parent agent:
- `<tools_directory>`: Path to tools directory (e.g., `/path/to/project/sjui_tools`)
- `<specification>`: Path to screen specification JSON (e.g., `docs/screens/json/login.spec.json`)
- `<layouts_directory>`: Path to shared Layout JSON directory (e.g., `docs/screens/layouts`)
- `<source_project_path>` (optional): Path to existing project on another platform
- `<source_platform>` (optional): The source platform (iOS / Android / Web)

## Where to Edit Layout JSON

**All Layout JSON MUST be edited in the shared `layouts_directory`**, NOT in platform-specific directories.

```
# ❌ WRONG - editing platform copy (will be overwritten by jui build)
vim my-app-ios/my-app/Layouts/login.json

# ✅ CORRECT - editing shared source
vim docs/screens/layouts/login.json
jui build  # distributes to all platforms
```

## Cross-Platform Copy (REQUIRED when source_project_path is provided)

**When `<source_project_path>` is provided, you MUST copy from the existing platform FIRST before making any edits.**

JsonUI layouts are cross-platform — the same JSON works on iOS, Android, and Web.

### Procedure:
1. Find the corresponding layout JSON in the source project:
   - Look in `<source_project_path>/Layouts/` for the screen JSON file
   - Also check for includes, styles, and string resources
2. **Copy the layout JSON as-is** to the shared `layouts_directory`
3. **Copy related includes, styles, and resources** to the shared directory
4. After copying, review the layout and adjust only if necessary

**Do NOT rewrite layouts from scratch when a source exists. Always copy first.**

---

## Reading Specification (REQUIRED)

Before implementing layouts, read the specification JSON and extract:
- `structure.components` - Component list with IDs, types, descriptions, optional `children`, `style`, `binding`
- `structure.layout` - Layout hierarchy (parent-child relationships, `overlay` for ZStack-style stacking)
- `structure.decorativeElements` - Decorative elements with `parentId` for insertion
- `structure.wrapperViews` - Wrapper views with `targetId`
- `stateManagement.uiVariables` - Data bindings to use (`@{variableName}`)
- `stateManagement.eventHandlers` - Event bindings to use (`@{onHandlerName}`)
- `stateManagement.displayLogic` - Visibility rules (may include explicit `variableName`)

## ⛔ File Creation Prohibited

When new files are needed, switch to the `jsonui-generator` skill.

This skill only handles editing existing JSON layouts.

---

## Required: Attribute Validation

Before creating/editing layouts:
1. If `lookup_component` / `lookup_attribute` MCP tools are available, use them to look up component specs
2. Otherwise, read `<tools_directory>/lib/core/attribute_definitions.json`
3. Check constraints in the `description` field
4. Check required attributes in the `required` field

**Never guess attribute names or types. Always verify against definitions.**

## Post-Build Validation (Required)

After creating/editing layouts:
1. Run `jui build` (distributes layouts from shared directory to all platforms + builds)
2. Review all warnings
3. Complete when warnings are zero

**Note:** Do NOT run platform-specific build tools directly for layout validation — use `jui build` to ensure layouts are properly distributed first.

---

## Screen Root Structure

Rules for full-screen layouts (not include/cell):

1. **Root must be SafeAreaView**
2. **Do not specify orientation on SafeAreaView**
3. **Second level must be ScrollView or Collection**

→ Examples: `examples/screen-root-structure.json`, `examples/screen-root-wrong.json`

**SafeAreaView/ScrollView not needed for includes or cells**

---

## Collection Implementation

Set `CollectionDataSource` type via binding on the `items` attribute.

### UIKit / Android Views (Dynamic mode)

→ Example: `examples/collection-uikit.json`

No `sections` needed. Cell configuration is controlled by `CollectionDataSource`.

### SwiftUI / Jetpack Compose (Generated mode)

→ Examples: `examples/collection-swiftui-basic.json`, `examples/collection-swiftui-full.json`

Define cell/header/footer structure via `sections`. Each view requires a JSON file.

### REQUIRED: cellIdProperty

**Every Collection MUST have `cellIdProperty` set.** This ensures each cell has a unique identity for efficient diffing and animation.

```json
{
  "type": "Collection",
  "cellIdProperty": "id",
  "items": "@{bottleItems}",
  "sections": [{ "cell": "bottle_cell" }]
}
```

- `cellIdProperty` specifies which field in the cell data uniquely identifies each item (typically `"id"`)
- ViewModel must ensure each item in the data source has a unique value for this field
- Without this, SwiftUI/Compose cannot properly animate list changes or maintain scroll position

### Wrong Example

→ Example: `examples/collection-wrong.json` - Manual view repetition prohibited

---

## TabView (Tab Navigation)

**⛔ NEVER create custom tab bars manually. Always use the built-in TabView component.**

TabView provides native tab navigation with:
- Platform-native tab bar appearance
- Automatic icon and title rendering
- Proper view switching

→ Examples: `examples/tabview.json`, `examples/tabview-wrong.json`

### ⛔ CRITICAL: TabView Structure

**TabView is the ROOT of the app, NOT a child inside a screen.**

Each tab's `view` attribute references a SEPARATE JSON file. The tab content is NOT defined inline.

**CORRECT Structure:**
```
root.json (TabView only)
├── home.json (Home screen content)
├── search.json (Search screen content)
└── profile.json (Profile screen content)
```

**TabView JSON (root.json):**
```json
{
  "type": "TabView",
  "tabs": [
    { "title": "Home", "icon": "house", "view": "home" },
    { "title": "Search", "icon": "magnifyingglass", "view": "search" },
    { "title": "Profile", "icon": "person", "view": "profile" }
  ]
}
```

**Tab Content JSON (home.json):**
```json
{
  "type": "SafeAreaView",
  "child": {
    "type": "ScrollView",
    "child": {
      "_comment": "Home screen content here"
    }
  }
}
```

### Prohibited Patterns

**DO NOT:**
- Put TabView inside SafeAreaView or ScrollView
- Put TabView as a child of another view
- Define tab content inline inside TabView
- Create a View with horizontal buttons as a tab bar
- Manually implement tab switching logic in ViewModel
- Use onClick handlers to switch between tabs

**WRONG - TabView inside screen content:**
```json
{
  "type": "SafeAreaView",
  "child": [
    { "type": "ScrollView", "child": { "...content..." } },
    { "type": "TabView", "tabs": [...] }
  ]
}
```

**If you need tab-based navigation, TabView is the ROOT. Period.**

---

## Include Syntax

**Include is NOT a type** - It's a reference directive.

Creation commands:
```bash
<tools_directory>/bin/<cli> g partial header
<tools_directory>/bin/<cli> g partial popups/confirm
```

→ Examples: `examples/include-correct.json`, `examples/include-wrong.json`

---

## Data Binding

### Syntax

- Bind with `@{}`: `"text": "@{title}"`, `"onClick": "@{onButtonTap}"`
- **Views with bindings must have an `id`**

### This Agent Does Not Define Data Section

Only write `@{bindingName}`. Type definitions are handled by the `jsonui-data` agent.

### No Logic in Bindings (Critical)

**Prohibited patterns:**
- `@{selectedTab == 0 ? #D4A574 : #B8A894}` - Ternary operators
- `@{items.count > 0}` - Comparisons
- `@{price * quantity}` - Calculations
- `@{!isHidden}` - Negation

**Allowed:**
- `@{searchTabColor}` - ViewModel computed property
- `@{onButtonTap}` - ViewModel function

→ Examples: `examples/binding-correct.json`, `examples/binding-wrong.json`

### ID Naming Convention (Required)

Use component type as suffix:

| Component | Suffix | Example |
|-----------|--------|---------|
| Label | `Label` | `titleLabel` |
| TextField | `TextField` | `emailTextField` |
| Button | `Button` | `submitButton` |
| Image | `Image` | `profileImage` |
| CheckBox | `CheckBox` | `agreeCheckBox` |
| Switch | `Switch` | `notificationSwitch` |

→ Examples: `examples/id-naming-correct.json`, `examples/id-naming-wrong.json`

---

## String Resources

### strings.json Format

Structure: `{ "file_prefix": { "key": "value" } }`

→ Example: `examples/strings-json.json`

- `file_prefix`: Matches JSON layout filename (`login.json` → `"login"`)
- Reuse existing keys when available

### Text Extraction Rules

Extracted attributes: `text`, `hint`, `placeholder`, `label`, `prompt`

Not extracted when:
- Starts with `@{` (data binding)
- snake_case format (treated as key reference)
- 2 characters or less

---

## Color Resources

### Allowed Formats

1. Color names from colors.json: `"primary_color"`, `"deep_gray"`
2. Hex: `"#FF5500"`, `"#1A1410"`, `"#80FF5500"` (AARRGGBB format with alpha)

### Prohibited Formats

- `rgba(...)`, `rgb(...)`, `hsl(...)`
- `Color.red`, `UIColor.white`

→ Examples: `examples/color-correct.json`, `examples/color-wrong.json`

---

## partialAttributes

The `range` in `partialAttributes` supports two formats:

1. **Array** `[start, end]`: Index-based range
2. **String**: Text pattern matching

`onClick` makes a partial range tappable. The handler must be defined in the data section as `(() -> Void)?`.

→ Example: `examples/partial-attributes.json`

String format is preferred when the target text is static and readable.

---

## Border Limitations (SwiftUI / Compose)

`borderWidth` applies a border to **all four sides**. Direction-specific borders (`borderBottomWidth`, `borderTopWidth`, etc.) are supported in **UIKit / Android Views only**.

In SwiftUI / Compose generated code, create a separate View as a divider line instead.

→ Example: `examples/border-divider.json`

**Do NOT use `borderBottomWidth` / `borderTopWidth` in SwiftUI / Compose layouts.**

---

## Custom Components (Converter)

When generating Converters:
1. Identify all required attributes
2. Verify types using `lookup_attribute` MCP tool if available, otherwise in `attribute_definitions.json`
3. Always specify `--attributes` option

---

## Responsive Layout

Components can have a `responsive` block for size class-based attribute overrides:

```json
{
  "type": "View",
  "orientation": "vertical",
  "spacing": 8,
  "responsive": {
    "regular": { "orientation": "horizontal", "spacing": 24 },
    "landscape": { "spacing": 16 },
    "regular-landscape": { "orientation": "horizontal", "spacing": 32 }
  },
  "child": [...]
}
```

### Size Class Keys

| Key | Description |
|---|---|
| `compact` | Small screen (iPhone, compact Android) |
| `medium` | Medium screen (Android medium) |
| `regular` | Large screen (iPad, Android expanded) |
| `landscape` | Landscape orientation |
| `compact-landscape` | Small screen + landscape |
| `regular-landscape` | Large screen + landscape |

Priority: compound > landscape > regular > medium > compact > default

### Rules

- `responsive` can be added to ANY component
- Only attribute overrides — `type`, `child`, `data` CANNOT be in responsive
- Unspecified attributes keep the default value
- Use for: orientation changes, spacing/padding adjustments, visibility toggling, fontSize changes
- For completely different layouts, use variant files (`screen@tablet.json`) instead

### Common Patterns

**Vertical → Horizontal on tablet:**
```json
{ "orientation": "vertical", "responsive": { "regular": { "orientation": "horizontal" } } }
```

**Show sidebar on tablet:**
```json
{ "visibility": "gone", "responsive": { "regular": { "visibility": "visible" } } }
```

**Adaptive spacing:**
```json
{ "spacing": 8, "responsive": { "regular": { "spacing": 24 }, "landscape": { "spacing": 16 } } }
```

---

## Platform-Specific Overrides

Use the `platform` key for attributes that differ between iOS, Android, and Web:

```json
{
  "type": "View",
  "id": "hero",
  "height": 200,
  "platform": {
    "ios": { "height": 220 },
    "android": { "height": 180 },
    "web": { "height": "100vh", "maxWidth": 1200 }
  }
}
```

**How it works:**
- `jui build` resolves `platform` overrides at build time
- Each platform gets its own values (iOS → `height: 220`, Android → `height: 180`)
- The `platform` key is removed from the distributed JSON
- Attributes not overridden keep the base value

**⚠️ `platform` vs `responsive`:**

| Key | Resolved | Purpose |
|-----|---------|---------|
| `platform` | `jui build` time (static) | iOS/Android/Web differences |
| `responsive` | App runtime (dynamic) | Screen size class switching |

Both can coexist on the same node.

**⚠️ Do NOT confuse with `"platform": "swift"`:**
The existing string value `"platform": "swift"` in data sections is a SwiftJsonUI platform filter — it is NOT an override map. Only dict-valued `platform` keys are treated as overrides.

---

## Overlay Layout

For ZStack-style stacking (loading overlays, floating buttons):

```json
{
  "type": "View",
  "id": "root",
  "child": [
    { "type": "View", "id": "main_content" },
    {
      "type": "View", "id": "loading_overlay",
      "visibility": "@{loadingVisibility}"
    }
  ]
}
```

When the spec has `overlay: true` in the layout, children are stacked (no `orientation`) with optional `zIndex` for ordering.

---

## Cross-Platform

The same JSON works on:
- SwiftJsonUI (iOS)
- KotlinJsonUI (Android)
- ReactJsonUI (Web)

`jui build` distributes from the shared `layouts_directory` to each platform, resolving `platform` overrides.

---

## Handoff After Completion

After JSON layout is complete, report the list of bindings used (`@{email}`, `@{onLoginTap}`, etc.).
