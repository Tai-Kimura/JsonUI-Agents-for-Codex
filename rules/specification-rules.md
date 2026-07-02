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

## Why This Matters

- Specifications are the **single source of truth**
- Incorrect assumptions propagate to all downstream agents
- Fixing misinterpretations later is expensive
- The user knows their requirements better than we do

---

## 🔴 HARD RULE: The spec describes intent. The Layout JSON describes the UI.

**EVERY screen spec MUST reference an external Layout JSON via `metadata.layoutFile`.**
**NEVER write the UI tree inline in `structure.components` / `structure.layout` / `structure.collection.cell.children`.**

Why:
- `docs/screens/layouts/*.json` is the **single source of truth** for rendering. `jui build` reads from there, distributes to every platform, and auto-extracts strings/colors/styles.
- Duplicating the UI inline in the spec creates drift — `jui verify` will flag it, and platform-side copies silently fall out of date.
- All generators (sjui/kjui/rjui) + both runtimes (SwiftJsonUI, KotlinJsonUI Dynamic) are built around the Layout JSON path. The inline shape is a legacy escape hatch kept only for backwards compatibility.

What this means in practice:

| Field | Value |
|---|---|
| `metadata.layoutFile` | **required**. Snake_case, no extension (e.g. `"login"`, `"bar_list/bar_cell"`). |
| `structure.components` | **empty array `[]`**. |
| `structure.layout` | **empty object `{}`**. |
| `structure.collection` | `null` unless the screen IS a collection. If it is, `cell.layoutFile` references an external cell Layout JSON — not `cell.children`. |
| `structure.tabView` | `null` unless it's a TabView screen. Each tab uses `layoutFile`. |

The one legitimate exception: `screen_parent_spec` index files, where `structure` can hold a brief `rootComponents` summary for human readers, but the real UI still lives in the referenced Layout JSON.

The rest of this document is the reference for the spec fields that remain (metadata, dataFlow, stateManagement, relatedFiles, etc.). Layout itself is documented in `rules/file-locations.md` + the Layout JSON files themselves.

---

## Spec types

Three `type` values, checked at `validator.py:226-234`:

| `type` | Purpose | Required top-level |
|---|---|---|
| `screen_spec` | Standalone screen | `type`, `version`, `metadata`, `structure` |
| `screen_parent_spec` | Index for a screen split across multiple sub-specs | `type`, `version`, `metadata`, `subSpecs` |
| `screen_sub_spec` | Piece of a parent spec | `type`, `version`, `metadata` |

`structure` is required on `screen_spec` but the **validator treats `components` + `layout` as optional when `metadata.layoutFile` is set** (`validator.py:393-405`). That's the path every new spec should take.

---

## Top-level skeleton (`screen_spec`)

```json
{
  "type": "screen_spec",
  "version": "1.0",
  "metadata": {
    "name": "Login",
    "displayName": "ログイン画面",
    "description": "ユーザー認証画面",
    "platforms": ["ios", "android", "web"],
    "layoutFile": "login"
  },
  "structure": {
    "components": [],
    "layout": {},
    "collection": null,
    "tabView": null
  },
  "dataFlow": { ... },
  "stateManagement": { ... },
  "userActions": [ ... ],
  "transitions": [ ... ],
  "relatedFiles": [ ... ],
  "notes": [ ... ]
}
```

Everything after `structure` is optional, but most real specs fill in `dataFlow`, `stateManagement`, `relatedFiles`.

## `metadata`

Required (`validator.py` via `screen_spec_schema.py:50`): `name`, `displayName`, `description`.
You should also always include: `platforms`, `layoutFile`.

```json
"metadata": {
  "name": "Login",                       // ^[A-Z][a-zA-Z0-9]*$  PascalCase
  "displayName": "ログイン画面",
  "description": "…",
  "platforms": ["ios", "android", "web"],
  "layoutFile": "login",                 // REQUIRED for any screen that renders UI
  "createdAt": "2026-04-21",             // YYYY-MM-DD, optional
  "updatedAt": "2026-04-21"
}
```

For `screen_sub_spec`, use `parentSpec` instead of duplicating the parent's `layoutFile`:

```json
"metadata": {
  "name": "Chat - Core",
  "parentSpec": "chat.spec.json",
  "description": "…"
}
```

## `structure`

The five shapes. Every time you author a spec, pick one of (1) / (2) / (3) / (4):

### (1) Plain screen — just `layoutFile`

```json
"structure": {
  "components": [],
  "layout": {},
  "collection": null,
  "tabView": null
}
```

Everything else lives in `docs/screens/layouts/{layoutFile}.json`. **Most screens are this.**

### (2) Collection screen

The spec identifies the Collection; each cell references an external Layout JSON.

Single-cell Collection:

```json
"structure": {
  "components": [],
  "layout": {},
  "collection": {
    "id": "bars_collection",
    "cell": {
      "viewName": "ItemCellView",
      "root": "bar_cell_root",
      "layoutFile": "bar_list/bar_cell",   // external Layout JSON
      "generateCellLayout": true,          // true → jui writes the cell Layout JSON on generate
      "uiVariables": [
        { "name": "barName", "type": "String", "description": "バー名", "defaultValue": "" },
        { "name": "shotPrice", "type": "String?", "description": "ショット価格" }
      ],
      "eventHandlers": [
        { "name": "onMapTap", "description": "Mapボタンタップ" }
      ]
    },
    "header": null,
    "footer": null
  }
}
```

Multi-cell Collection (`cellClasses` is an **array of strings** — Layout JSON refs):

```json
"collection": {
  "id": "message_list",
  "cellClasses": [
    "chat/message_cell",
    "chat/location_prompt_bubble",
    "chat/streaming_cell"
  ]
}
```

Section-based Collection (each section routes to a cell ref):

```json
"collection": {
  "id": "message_list",
  "cellClasses": ["chat/message_cell", "chat/streaming_cell"],
  "sections": [
    { "cell": "chat/message_cell", "header": "chat/section_header" },
    { "cell": "chat/streaming_cell" }
  ]
}
```

**Do not write `cell.children` inline.** The Collection validator enforces one of `cell` / `cellClasses` / `sections[].cell` (`validator.py:657-684`); when `cell.layoutFile` is set, `children` is NOT required — the tree comes from the external file.

### (3) TabView screen

```json
"structure": {
  "components": [],
  "layout": {},
  "tabView": {
    "id": "main_tabs",
    "tabs": [
      { "title": "Candidates", "layoutFile": "chat/candidates_tab" },
      { "title": "Purchases",  "layoutFile": "chat/purchases_tab" }
    ]
  }
}
```

Each tab is a separate Layout JSON. Per-tab `dataFlow` / `stateManagement` lives in that tab's own sub-spec if the screen is large enough to split.

### (4) Parent + sub-specs (large screens)

Parent spec (`screen_parent_spec`):

```json
{
  "type": "screen_parent_spec",
  "version": "1.0",
  "metadata": {
    "name": "Chat",
    "displayName": "チャット画面",
    "description": "...",
    "layoutFile": "chat"
  },
  "subSpecs": [
    { "file": "chat/chat-core.spec.json",      "name": "Chat - Core",      "description": "Core structure" },
    { "file": "chat/chat-streaming.spec.json", "name": "Chat - Streaming", "description": "Streaming cell" }
  ]
}
```

Sub-spec (`screen_sub_spec`) — references the parent and covers one slice:

```json
{
  "type": "screen_sub_spec",
  "version": "1.0",
  "metadata": {
    "name": "Chat - Core",
    "parentSpec": "chat.spec.json",
    "description": "Core screen structure (root view, message list, input area)"
  },
  "structure": { ... },          // optional — only fill fields this sub-spec is responsible for
  "dataFlow": { ... },
  "stateManagement": { ... }
}
```

Sub-specs never duplicate the parent's `layoutFile`. Parent authors the Layout; sub-specs inherit via `parentSpec` (`validator.py:353-405`).

## `dataFlow`

### 🔴 HARD RULE: `dataFlow` is REQUIRED for any screen that isn't pure-static display

Agents have shipped specs with empty or missing `dataFlow` even when the screen clearly has interaction or data. That is a spec bug — downstream `/agent implement` has nothing to generate the Protocol / Base / Repository / UseCase from, and `jui build` will pass with an empty contract that humans then have to fix by hand.

**Every screen spec (except pure-static display screens) MUST author ALL of the following when applicable:**

| Sub-section | When to fill | What to write |
|---|---|---|
| `dataFlow.viewModel.methods` | Screen has ANY user action that does work (tap → fetch, submit, navigate, validate, toggle state the VM owns). | One entry per public ViewModel method. **Every `stateManagement.eventHandlers` entry that reaches the VM must have a corresponding `viewModel.methods` entry** — if a handler only toggles pure-UI state, leave it as an eventHandler and note the omission. |
| `dataFlow.viewModel.vars` | Screen has any observable state (loading flags, fetched data, form values the VM owns, derived display strings). | One entry per observable property. camelCase, typed. Do not let UI-bound `stateManagement.uiVariables` stand in for VM vars — the spec needs both when the VM owns the source of truth. |
| `dataFlow.repositories[]` | Screen reads/writes ANYTHING outside the VM — API, disk, keychain, cache, shared state, platform SDK (StoreKit, Firebase, CoreLocation). | At minimum one Repository with `methods[]` and `endpoint` (or SDK description in `description`). API calls via ViewModel directly are NOT allowed — see design-philosophy.md. |
| `dataFlow.useCases[]` | Screen has orchestration across multiple repositories, multi-step validation, or business logic that doesn't belong in either the VM or a Repo. | Declare the UseCase and link it to Repositories via `useCase.repositories` or `methods[].calls`. Skip the UseCase for 1-API single-repo screens. |
| `dataFlow.apiEndpoints[]` | Every endpoint referenced by `repositories[*].methods[*].endpoint` must have a matching entry here. | `{path, method, request, response, notes}`. Paths must match repo entries exactly. |

**Pure-static display screens** (no interaction, no dynamic data, no observable state — e.g. a help page with hard-coded text) are the ONE exception. For those, still write `dataFlow.viewModel: { methods: [], vars: [] }` **explicitly** — do not omit the `dataFlow` key entirely, so the next editor can see it was a considered choice rather than a skip.

**Validation gate before moving to HTML generation:** if the spec has any `stateManagement.eventHandlers` OR any `uiVariables` with callback type `(() -> Void)?` OR any dynamic binding (`@{...}`) in the referenced Layout JSON, then `dataFlow.viewModel.methods` MUST be non-empty. If it's empty, go back and ask the user — do not let the spec pass.

**How to ask the user when they didn't volunteer this info:**

```
Looking at the screen description, I see <tap/submit/fetch/etc>. I need to author the dataFlow section — a few questions:

1. ViewModel methods: what should the VM do on each action? (I'll draft one method per action with the signature.)
2. Observable state: what state does the VM own and the UI observes? (isLoading, fetchedItems, errorMessage, etc.)
3. Data source: does this screen hit any API / SDK / storage? If yes, I'll draft a Repository with those methods.
4. Orchestration: does a single user action trigger work across multiple repos or multi-step validation? If yes, I'll draft a UseCase.
```

Do this BEFORE writing `dataFlow`. Do not guess method names / var names / repo names from the screen description alone — they become part of the generated Protocol that downstream platforms must implement, and renaming later is a breaking change.

### dataFlow structure reference

```json
"dataFlow": {
  "repositories": [
    {
      "name": "AuthRepository",
      "description": "認証関連API",
      "methods": [
        {
          "name": "emailLogin",
          "params": [
            { "name": "email", "type": "String" },
            { "name": "password", "type": "String" }
          ],
          "returnType": "TwoFaRequiredResponse",
          "isAsync": true,                       // default: true for repository methods
          "endpoint": "POST /api/auth/login",
          "platforms": ["ios"]                   // optional
        }
      ]
    }
  ],
  "useCases": [
    { "name": "LoginUseCase", "methods": [ ... ], "repositories": ["AuthRepository"] }
  ],
  "viewModel": {
    "description": "Login ViewModel",
    "methods": [
      {
        "name": "onEmailChanged",
        "params": [{ "name": "email", "type": "String" }],
        "returnType": "Void",
        "isAsync": false                         // default: false for viewModel methods (UI events)
      }
    ],
    "vars": [
      { "name": "isLoading", "type": "Bool",
        "optional": false, "observable": true, "readOnly": false,
        "platforms": ["ios", "android"] }
    ]
  },
  "apiEndpoints": [
    { "path": "/api/auth/login", "method": "POST",
      "request": {}, "response": {}, "notes": "..." }
  ]
}
```

- `method` (in `apiEndpoints`) must be one of `GET|POST|PUT|PATCH|DELETE` (`validator.py:81`).
- Repository methods default to `isAsync: true`; ViewModel methods default to `isAsync: false`.
- `dataFlow.viewModel.methods` is the **public ViewModel contract**. `jui build` generates the Protocol / Base from this — hand-editing the generated file is a build failure.

## `stateManagement`

```json
"stateManagement": {
  "uiVariables": [
    { "name": "email",                           // ^[a-z][a-zA-Z0-9]*$  camelCase
      "type": "String",
      "description": "メール入力値",              // REQUIRED
      "defaultValue": "" },
    { "name": "onLoginTap",                      // callbacks ARE uiVariables
      "type": "(() -> Void)?",                   // or the "callback" alias
      "description": "ログインタップ" }
  ],
  "eventHandlers": [
    { "name": "onAppleSignInTap",                // ^on[A-Z][a-zA-Z0-9]*$
      "description": "Apple Sign In タップ" }
  ],
  "displayLogic": [
    {
      "condition": "loadingVisibility == 'visible'",
      "effects": [
        { "element": "loading_indicator", "state": "visible",
          "variableName": "loadingIndicatorVisibility" }   // optional; auto-derived from element_id
      ]
    }
  ],
  "cellDisplayLogic": [ ... ],                    // same shape — for visibility rules inside a cell
  "states": [
    { "name": "LoginFormState",
      "values": [
        { "value": "loginForm", "description": "…", "visibleElements": ["login_form_container"] }
      ] }
  ]
}
```

**The distinction that trips agents up:**
- `uiVariables` = typed data bound into the Layout JSON. Callbacks go here with `type: "(() -> Void)?"` or `"callback"`.
- `eventHandlers` = View-local handlers only (name + description, no type). Anything that needs to be called from the ViewModel or bound via `@{...}` must be a `uiVariables` entry, not an `eventHandler`.

## `userActions` / `transitions` / `validation`

All optional. See `screen_spec_schema.py` for the exact shape. These are for human documentation of navigation intent / form validation — they don't generate code.

## `relatedFiles`

Cross-references to generated and hand-written files. Accepted `type` values (`validator.py:76-82`):

`View`, `ViewModel`, `Layout`, `Repository`, `UseCase`, `Model`, `Test`, `Extension`, `Component`, `Hook`

```json
"relatedFiles": [
  { "type": "Layout",    "path": "docs/screens/layouts/login.json" },
  { "type": "View",      "path": "…/LoginView.swift",           "platform": "ios" },
  { "type": "ViewModel", "path": "…/LoginViewModel.swift",      "platform": "ios" },
  { "type": "Extension", "path": "…/ItemListing+Status.swift",   "platform": "ios" },
  { "type": "Component", "path": "…/LoginButton.tsx",           "platform": "web" },
  { "type": "Hook",      "path": "…/useLoginViewModel.ts",      "platform": "web" }
]
```

## Naming regex summary

Enforced by the schema. Violations are validation errors, not warnings:

| Field | Pattern | Example |
|---|---|---|
| `version` | `^\d+\.\d+$` | `"1.0"` |
| `metadata.name` | `^[A-Z][a-zA-Z0-9]*$` | `Login`, `ItemList` |
| Any `component.id` | `^[a-z][a-z0-9_]*$` | `bar_cell_root` |
| `uiVariable.name` | `^[a-z][a-zA-Z0-9]*$` | `loadingVisibility` |
| `eventHandler.name` | `^on[A-Z][a-zA-Z0-9]*$` | `onLoginTap` |

---

## Text and String References

In Layout JSON, a text-bearing attribute (`text`, `hint`, `summary`, `copyLabel`,
etc.) takes one of:

- **Literal text** — e.g. `"text": "Hello World"`. `jui build` auto-extracts
  the literal into `strings.json` and (on Swift/Kotlin/Web) rewrites the call
  site to `StringManager.*` lookups.
- **snake_case key** — e.g. `"text": "learn_installation_headline"`. Resolved
  by `StringManagerHelper` against the loaded `strings.json`. The key can be
  bare (matches any file in `strings.json`) or prefixed with the file name
  (`"<file>_<key>"`).
- **Data binding** — e.g. `"text": "@{currentLanguage}"`. Bound to a
  ViewModel property with the `@{...}` syntax.

> **⛔ Never use `"@string/<key>"`.** That is Android XML resource syntax and
> is only handled by the legacy `kjui_tools/lib/xml/` path — not by SwiftUI,
> Compose, React, or the Dynamic runtimes. It will render as the literal
> string `@string/<key>` on every other platform.

## Color References

Color-valued attributes (`background`, `fontColor`, `borderColor`, `tintColor`,
…) take one of:

- **Semantic key** — e.g. `"background": "primary_surface"`. Resolved against
  `{layouts_directory}/Resources/colors.json`. **Preferred for new code** —
  gives the value a name, keeps the hex out of the layout, and makes later
  theming changes one-file edits.
- **Hex literal** — e.g. `"background": "#F9FAFB"`. `jui build` auto-extracts
  it into `colors.json` with a generated name (e.g. `gray_light_1`) and
  rewrites the layout. Functional but produces machine-named colors.
- **Binding** — e.g. `"background": "@{themeAccent}"` (runtime-resolved).

> When writing a new layout, reach for a semantic key first. Hex is the
> fallback when no name applies yet — build will still clean up afterwards,
> but the generated names are not as readable as ones you'd pick yourself.

## Collection Cell: declaring typed data

To give a Collection cell its own typed `data` section in the generated
Layout JSON (instead of inheriting untyped values via the parent
Collection's `items` binding), declare the cell's variables and handlers
on `structure.collection.cell` using the same shape as the screen's
`stateManagement`:

```json
"collection": {
  "id": "bars_collection",
  "cell": {
    "viewName": "ItemCellView",
    "layoutFile": "bar_list/bar_cell",
    "generateCellLayout": true,
    "root": "bar_cell_root",
    "uiVariables": [
      { "name": "barName", "type": "String", "description": "バー名", "defaultValue": "" },
      { "name": "shotPrice", "type": "String?", "description": "ショット価格" },
      { "name": "openStatusVisibility", "type": "String", "description": "営業中バッジ表示", "defaultValue": "gone" }
    ],
    "eventHandlers": [
      { "name": "onMapTap", "description": "Mapボタンタップ" }
    ]
  }
}
```

Rules:
- `cellNode.uiVariables` — same shape as `stateManagement.uiVariables`
  (name / type / description / defaultValue). Each entry becomes a typed
  entry in the cell's Layout JSON `data` section.
- `cellNode.eventHandlers` — same shape as `stateManagement.eventHandlers`.
  Each handler becomes a callback property (`(() -> Void)?`) on the cell's
  `data` so Layout JSON bindings like `"onClick": "@{onMapTap}"` resolve.
- `dataKeys` (legacy) is a plain list of names — prefer `uiVariables` for
  new specs so types and default values round-trip into the generated
  Layout.
- Screen-level `stateManagement.uiVariables` is for the screen's own data
  (collection data source, visibility flags, toast messages…). Cell data
  belongs on the cell node, not on the screen.

## Collection: `lazy: true` (default) vs `lazy: false`

`Collection` components default to lazy/virtualized containers
(`LazyVStack` / `LazyColumn` / `LazyVerticalGrid`) with their own internal
scroll. Set `lazy: false` only when you know the Collection is already nested
inside a scrollable parent — the generated code then uses plain
`VStack` / `HStack` / `Column` / `Row` + `ForEach` with **no enclosing
ScrollView / verticalScroll**, so the outer scroll handles the viewport.

Use `lazy: false` when:
- The Collection sits inside an outer `ScrollView` / `verticalScroll` /
  Compose `Column { Modifier.verticalScroll() }` and nesting a Lazy container
  would break layout (Compose infinite-height constraint crash; SwiftUI
  double-scroll behavior).
- You know the item count is small and fixed (e.g. a few cards in a section
  on a screen that already scrolls as a whole).

Do NOT use `lazy: false` when:
- The list can grow to hundreds of items — eager rendering has no
  virtualization and will load everything at once.
- You need sticky headers, programmatic `scrollTo`, `defaultScrollAnchor`,
  or `paging` — those all require the lazy path to stay active. The
  generator/runtime silently ignores those attributes under `lazy: false`.

Platform details worth knowing when reviewing output:
- **SwiftUI** `lazy: false` → `VStack` / `HStack` (or `LazyVGrid` without
  an outer `ScrollView` for multi-column), no `ScrollView`.
- **Compose** `lazy: false` → `Column` / `Row` + `forEachIndexed`, no
  `LazyColumn` / `LazyVerticalGrid`, no `verticalScroll`.
- **React** `lazy: false` → the same `div` + `.map()`, but
  `overflow-y-auto` / `overflow-x-auto` / `flex-nowrap` Tailwind classes
  are dropped.
- **UIKit** (generated) ignores `lazy: false` silently — `UICollectionView`
  is inherently lazy.

## Custom Components — spec first, then `jui g converter`

Any Layout JSON node whose `type` is **not** a standard JsonUI component (i.e.
not in the framework's built-in component list, not already registered as a
converter in this project) is a **custom component**. Examples: `CodeBlock`,
`NavLink`, `Collapse`, `Details`, `PlatformBadge`, `NetworkImage`.

Custom components MUST be introduced in this exact order. Skipping any step
produces a converter that doesn't match the layout and silently renders
wrong (JSX syntax errors at worst, missing attributes at best).

### 1. Write a `component_spec` FIRST

Before any layout or screen spec references the custom type:

```
mcp__jui-tools__doc_init_component with name: "CodeBlock", category: "display", displayName: "Code block"
```

This creates `{component_spec_directory}/codeblock.component.json`. Fill in
at minimum:

```json
{
  "type": "component_spec",
  "version": "1.0",
  "metadata": {
    "name": "CodeBlock",
    "displayName": "Code block",
    "description": "Fenced code block with copy-to-clipboard button.",
    "category": "display"
  },
  "props": {
    "items": [
      { "name": "language", "type": "String", "description": "Syntax highlight language." },
      { "name": "code",     "type": "String", "description": "Body text." }
    ]
  },
  "slots": { "items": [] }
}
```

Naming:
- `metadata.name` → PascalCase (`^[A-Z][a-zA-Z0-9]*$`).
- `props.items[].name` → camelCase (`^[a-z][a-zA-Z0-9]*$`).
- `props.items[].type` → any spec type (`String`, `Int`, `Bool`, `String?`,
  `[String]`, `(() -> Void)?`, etc.).
- `slots.items[]` non-empty → the component is a **container** (children
  get rendered inside it). Empty → `--no-container`.

Validate with `mcp__jui-tools__doc_validate_component`. Fix any violations.

### 2. Generate the converter FROM the spec

The framework has spec-driven scaffolding. Do NOT pass `--attributes` by
hand; drive it from the spec so the attribute list and types stay in sync
with the component's contract.

**You must run this explicitly** — `jui build` does NOT auto-run
converter scaffolding. That was tried and reverted: the downstream
component generators (React/Swift/Kotlin component + adapter +
dynamic-component scaffolders) all prompt interactively on overwrite,
which blocks MCP / CI callers even when the outer `jui g converter`
honors `--skip-existing`. Keep `jui build` focused on "build what's
written"; scaffold explicitly when you add or change a spec.

```bash
jui g converter --from codeblock.component.json   # single spec
jui g converter --all                             # every component spec
jui g converter --all --skip-existing             # idempotent (skip existing
                                                   #   converter files silently)
```

Under the hood (`generate_cmd.py::_cmd_generate_converter`):
- Reads `props.items[]` → `--attributes name:type,…`
- Reads `slots.items[]` non-empty → `--container`, empty → `--no-container`
- Calls `sjui g converter` / `kjui g converter` / `rjui g converter` with
  the same args per platform listed in `jui.config.json::platforms`
- `--skip-existing` exports `JUI_SKIP_EXISTING=1` to each platform
  subprocess. That bypasses the interactive prompt in the outer
  `converter_generator.rb` only — the React/Swift/Kotlin component
  generators invoked downstream still prompt, so `--skip-existing` is
  **best-effort idempotency**, not a full non-interactive guarantee.
  Use it for agent/CI runs when you expect every converter to already
  exist; fall back to answering `n` for any leftover prompt.

The direct form `jui g converter CodeBlock --attributes …` exists but is
only for one-off prototyping. **Production code always uses `--from` or
`--all`.**

### 3. Register in `.jsonui-doc-rules.json` (doc-site projects only)

For projects with a `.jsonui-doc-rules.json`, add the component name to the
screen whitelist so spec validation accepts it as a known `type`:

```json
{
  "rules": {
    "componentTypes": { "screen": ["CodeBlock", "NavLink", "Collapse", "…"] }
  }
}
```

### 4. THEN write the layout that uses it

Only after steps 1-3 do screen specs / Layout JSONs get to reference
`{"type": "CodeBlock", "language": "bash", "code": "…"}`.

If you find a layout using a custom type with no matching
`component_spec`, that's a spec bug. Route back to define the component
first — do not try to scaffold the converter from the layout alone.

### Why this matters

The scaffolding generator's output is driven by the attribute list. If the
attributes don't match the component's actual props:
- Generated converters reference props that don't exist on the component.
- Actual component props get dropped on the floor (invisible in the UI).
- Multi-line String attributes produce invalid JSX unless the generator
  handles them — and it only knows to handle them when `props[].type`
  declares them String.

Spec-first guarantees the three sides (converter / component / layout)
agree on the attribute contract.

---

## Common mistakes (from actual agent runs)

1. **Inline UI in the spec** — writing `structure.components` / `structure.layout` / `cell.children`. The UI MUST live in the Layout JSON; the spec only references it via `layoutFile`.
2. **`cellClasses` entries as objects** — they are plain string paths (`"chat/message_cell"`), not `{id, layoutFile}` dicts. The schema type is `array of strings`.
3. **`cell.children` required when `layoutFile` is set** — it isn't. The validator's `_has_external_layout_ref` skips the inline-layout check when `layoutFile` (or legacy `layout`) is present.
4. **`@string/<key>` in text attributes** — Android XML only. Use literal / snake_case key / `@{binding}`.
5. **Hex color literals in new code** — build will auto-extract them, but the generated names are not as readable as a semantic key you pick yourself.
6. **Placing `Styles/` under `layouts/Styles/`** — legacy. The current convention is `styles_directory` (sibling to `layouts/`, default `docs/screens/styles/`). See `rules/file-locations.md`.
7. **Callbacks declared in `eventHandlers`** — `eventHandlers` is name + description only. Typed callbacks (`"(() -> Void)?"`) go into `stateManagement.uiVariables`.
8. **Naming convention violations** — the schema enforces:
   - `metadata.name`: PascalCase
   - Any `component.id`: snake_case
   - `uiVariable.name`: camelCase
   - `eventHandler.name`: must start with `on[A-Z]`
   Mismatched names fail validation silently (specs get SKIPPED during HTML generation).
9. **`relatedFiles.type` = unknown string** — only these 10 are accepted: `View`, `ViewModel`, `Layout`, `Repository`, `UseCase`, `Model`, `Test`, `Extension`, `Component`, `Hook`.
10. **Missing `metadata.layoutFile` + empty `structure`** — if no `layoutFile`, the validator requires `components` + `layout` to be filled. Always set `layoutFile`.
11. **Using a custom `type` in a layout without a `component_spec`** — any non-standard `type` (`CodeBlock`, `Collapse`, `NavLink`, etc.) must have a `{name}.component.json` defining its `props.items[]` + `slots.items[]` FIRST, then be scaffolded via `jui g converter --from {name}.component.json`. Skipping the spec produces a converter whose attributes don't match the actual component — layouts render wrong or emit invalid JSX. See "Custom Components — spec first" above.
12. **Empty or missing `dataFlow` on an interactive screen** — if the screen has any user action or observable state, `dataFlow.viewModel.methods` / `vars` MUST be filled. `dataFlow.repositories[]` MUST be filled if the screen touches any API / SDK / disk. Agents have shipped specs with empty `dataFlow`, which lets `jui build` generate an empty Protocol — then humans patch around it in hand-written VM code, defeating the spec-first design. See "HARD RULE: `dataFlow` is REQUIRED" above.
13. **`stateManagement.eventHandlers` without matching `dataFlow.viewModel.methods`** — an eventHandler that calls the VM (tap → fetch, submit → validate) MUST appear as a `viewModel.methods[]` entry too. eventHandlers on their own only handle pure-UI toggles. If the handler reaches the VM, you need both entries.
14. **API calls declared directly in `viewModel.methods` without a `repositories[]` entry** — ViewModels don't call APIs directly. Any `methods[].endpoint` or obvious fetch-y method name (`fetchX`, `loadX`, `saveX`, `deleteX`) implies a Repository exists and must be declared. Route API access through `dataFlow.repositories[]`.
