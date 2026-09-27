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
| `metadata.layoutFile` | **required**. Snake_case, no extension (e.g. `"login"`, `"item_list/item_cell"`). |
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
    "id": "items_collection",
    "cell": {
      "viewName": "ItemCellView",
      "root": "item_cell_root",
      "layoutFile": "item_list/item_cell",   // external Layout JSON
      "generateCellLayout": true,          // true → jui writes the cell Layout JSON on generate
      "uiVariables": [
        { "name": "itemName", "type": "String", "description": "商品名", "defaultValue": "" },
        { "name": "unitPrice", "type": "String?", "description": "単価" }
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

### (5) Screen with embedded sub-screens (`Embed`)

Use the `Embed` view type when a parent screen hosts another screen as a region of its layout (tablet master/detail, dashboard panels). The embedded screen owns its own ViewModel — independent from the parent VM.

**Canonical reference**: the JsonUIDocument repository's `specification-rules.md` (5) section (the file authored at distribution time). Treat that section as authoritative for the JSON shape, attribute table, and validation rules.

**Quick recap of the rules (mirror these in spec / Layout JSON authoring):**

| Field | Where | Convention | Example |
|---|---|---|---|
| `structure.components[].id` (spec) | spec | snake_case | `detail_pane` |
| `Embed.id` (Layout JSON) | layout | camelCase | `detailPane` |
| `structure.embeds[].regionId` (spec) | spec | camelCase — references the Layout JSON `Embed.id` | `detailPane` |
| `Embed.screen` value | spec & layout | **snake_case layout JSON filename** (no extension) — codegen converts to PascalCase View name | `order_detail` |
| `params` keys | spec & layout | camelCase | `orderId` |
| `events` keys | spec | `^on[A-Z][a-zA-Z0-9]*$` | `onOrderUpdated` |
| `navigationMode` | spec & layout | `"delegate"` or `"isolated"` (in a spec from jsonui-cli 1.9.0; an earlier spec validator accepts `"delegate"` only) | `delegate` |

**Local-only validation** — `doc_validate_spec` checks the Embed block in isolation; the embedded screen's spec is NOT required to declare anything special. Type contracts beyond key/binding existence are runtime responsibilities (v1 scope). See `validator.py :: _validate_embed`.

**Embedded screen is unchanged.** Parents declare the embed; embedded VMs stay as-is. VMs that implement `applyInitParams(_:)` consume `params`; emit events via the lib-provided `emit(name, payload)` helper.

See `jsonui-cli/docs/plans/2026-05-11-embed-feature.md` for the full design.

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

**Reference the API document rather than copying it.** Once a method declares
`endpoint`, write `"params": "@canonical"` instead of restating the operation's
parameters; `doc_validate_spec` and `jui build` expand it from one shared
implementation. Mix in hand-written entries for arguments the API never declares
(`["@canonical", {"name": "onProgress", ...}]`), and write the list out in full
when the method deliberately differs from the document. `returnType` takes
`@canonical.wire` — never plain `@canonical` — because a spec's return type is
the domain type and the document's is the wire type. An unresolvable mark is an
ERROR, and omitting `params` still means "no parameters", not "resolve it".
Naming follows `spec.canonical_param_case` in `jui.config.json` (`asIs` by
default; set it before converting a project). Full rules: `jsonui-dataflow` skill.

**共有コンポーネントが呼ぶメソッドは、そのコンポーネントを使っている画面 spec すべてに
宣言する。**1 箇所にまとめない。spec を読んで「どこから呼ばれているか」が確認できる状態を
保つため。同じメソッドが複数 spec に出るのは正常で、**食い違いが異常**(実装は 1 つ)。
`jsonui-doc validate spec <dir>` が突き合わせて ERROR にする。

> **Swagger-driven Data Models** — When a Repository method's `returnType` (or a param type) is the name of a schema declared under `docs/api/*.json#components.schemas.*`, the type resolves to the **Domain wrapper** (`User`), not the DTO (`UserDto`). `jui build` auto-registers swagger schema names in TypeMapper, so no manual `.jsonui-type-map.json` entry is needed. To declare a return type as the raw DTO, write `returnType: "UserDto"` explicitly. See `file-locations.md` (API Specifications + Data Model section) for the DTO ↔ Domain layout and `invariants.md` (rules 6-9) for the editing contract.

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
        { "element": "loadingIndicator", "state": "visible",   // the layout's id, as written
          "variableName": "loadingIndicatorVisibility" }   // optional; auto-derived from element_id
      ]
    }
  ],
  "cellDisplayLogic": [ ... ],                    // same shape — for visibility rules inside a cell
  "states": [
    { "name": "LoginFormState",
      "values": [
        { "value": "loginForm", "description": "…", "visibleElements": ["loginFormContainer"] }
      ] }
  ]
}
```

**The distinction that trips agents up:**
- `uiVariables` = typed data bound into the Layout JSON. Callbacks go here with `type: "(() -> Void)?"` or `"callback"`.
- `eventHandlers` = View-local handlers only (name + description, no type). Anything that needs to be called from the ViewModel or bound via `@{...}` must be a `uiVariables` entry, not an `eventHandler`.

**`defaultValue` (1.9.0+).** The code generators and dynamic mode read a default from the Layout JSON `data` entry's `defaultValue`, which `jui g project` writes from a spec uiVariable's `default` or `defaultValue` (`default` when both are given). A `String` or `String?` default is written bare — the text as it is (`"defaultValue": "gone"`, `""` for empty). The code generators and dynamic mode (SwiftJsonUI 10.29.0 / KotlinJsonUI 2.42.0) also read `''` as empty, `"\"…\""` with JSON's escapes (as the text between the quotes when the escapes are not JSON's), and `"'…'"` as the text between the quotes. Bare is the spelling to write. A text of two or more characters that starts and ends with the same quote, `"` or `'`, is read as one of these spellings and loses those quotes. To keep them, write it `"\"…\""`, whose inside is read with JSON's escapes, so double any `\` in the text: `"\"'Tis'\""` is the text `'Tis'`. For a `String?` with no value, leave the default out. Do not write `"nil"`: the SwiftUI and Compose code read it as no value, but UIKit, web and dynamic mode show the text "nil". A value written per platform uses the keys `swift` / `kotlin` / `typescript` (optionally split by mode: `{"swift": {"swiftui": …, "uikit": …}}`), not a node's `ios` / `android` / `web`. A dictionary with none of those three keys is one value on every platform. For a String, the generated iOS and Android code shows its text and the web data model does not parse. For other types, the generated code does not build. A dictionary that mixes one of the three keys with other keys gives that platform its entry and gives the other platforms the whole dictionary, with no warning. A platform it does not name gets the type's default (`""` / 0 / 0.0 / false / []; none for an optional type, or for a type outside that list, which the SwiftUI data model then declares optional), and the SwiftUI, Compose and web builds warn: `<layout>: data '<name>' defaultValue is given for <platforms> but not <platform> — <platform> gets …` (UIKit mode prints nothing). Name every platform, or write one value.

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
| Any `component.id` | `^[a-z][a-z0-9_]*$` | `item_cell_root` |
| `uiVariable.name` | `^[a-z][a-zA-Z0-9]*$` | `loadingVisibility` |
| `eventHandler.name` | `^on[A-Z][a-zA-Z0-9]*$` | `onLoginTap` |

With `metadata.layoutFile` (the spec's own or its parent's — every screen spec has one), `displayLogic.effects[].element` and `states[].values[].visibleElements` are **Layout JSON ids, spelled exactly as the layout declares them** — the `component.id` pattern above is for `structure.components` and does not apply to them. `doc_validate_spec` checks them against the resolved layout (1.8.119+: reported as info; from 1.9.0 a WARNING when the id is not in the layout). An id inside an include is checked as the resolved layout spells it (`hero` + `type_badge` → `heroTypeBadge`). Web's old spelling of it — the included layout's own id — is reported as `cannot check` before 1.9.0 (the message names the spelling web uses from then) and as a mismatch from 1.9.0, when web generated by that release's `jui build` (with the project's rjui_tools synced) spells it the resolved way too. UIKit's spelling (the include's id in camelCase, then `_`, then the child's id) is always reported as `cannot check`: UIKit and XML layouts are outside the change. An id inside a cell layout, and every id when an include does not resolve, are reported as `cannot check`. When the message names layout ids (`the layout has '…'`), they are candidates, not matches: confirm which node the rule means — the one that carries the visibility binding — before changing the spec, and ask the user when there is no candidate. Never delete an effect or a `visibleElements` entry to clear the message.

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
  "id": "items_collection",
  "cell": {
    "viewName": "ItemCellView",
    "layoutFile": "item_list/item_cell",
    "generateCellLayout": true,
    "root": "item_cell_root",
    "uiVariables": [
      { "name": "itemName", "type": "String", "description": "商品名", "defaultValue": "" },
      { "name": "unitPrice", "type": "String?", "description": "単価" },
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

### Multiple Collections on one screen

A screen with more than one Collection declares the extras in
`structure.collections` (an **array** of the same collection shape).
`structure.collection` stays the primary slot — only it participates in
Layout JSON auto-generation — but every `collections[]` entry is
first-class for validation (`jsonui-doc validate spec`), doc generation,
and cell Layout generation (`jui g project` emits a cell Layout for each
entry with `generateCellLayout: true`):

```json
"collection": { "id": "fee_sections_collection", "cell": { ... } },
"collections": [
  { "id": "shipping_terms_sections_collection", "cell": { ... } },
  { "id": "gallery_thumbnail_row", "cell": { ... } }
]
```

Screens using `collections` are expected to author the screen Layout JSON
externally (`metadata.layoutFile`) — the auto-generated layout only places
the primary `collection`.

## Collection: `lazy` — `"lazy"` (default), `"eager"`, `"none"`

`lazy` takes a string (or a binding to one): `"lazy"`, `"eager"` or
`"none"`. A boolean is none of them: `lazy: false` gets the build warning
`Attribute 'lazy' in 'Collection' expects string or binding, got boolean`,
and every generator draws it as `"lazy"` — with its own scroll, the
opposite of what it is written for.

`Collection` components default to `"lazy"`: lazy/virtualized containers
(`LazyVStack` / `LazyColumn` / `LazyVerticalGrid`) with their own internal
scroll. `"eager"` keeps the scroll and draws every cell (no
virtualization), for heavy cells that suffer from lazy re-evaluation. Set
`"none"` only when you know the Collection is already nested inside a
scrollable parent — the generated code then uses plain
`VStack` / `HStack` / `Column` / `Row` + `ForEach` with **no enclosing
ScrollView / verticalScroll**, so the outer scroll handles the viewport.

Use `"none"` when:
- The Collection sits inside an outer `ScrollView` / `verticalScroll` /
  Compose `Column { Modifier.verticalScroll() }` and nesting a Lazy container
  would break layout (Compose infinite-height constraint crash; SwiftUI
  double-scroll behavior).
- You know the item count is small and fixed (e.g. a few cards in a section
  on a screen that already scrolls as a whole).

Do NOT use `"none"` when:
- The list can grow to hundreds of items — eager rendering has no
  virtualization and will load everything at once.
- You need sticky headers or `paging` — they require `"lazy"`. Under
  `"none"`, `scrollTo` and `defaultScrollAnchor` move nothing: the parent
  owns the scrolling.

Platform details worth knowing when reviewing output:
- **SwiftUI** `"none"` → `VStack` / `HStack` (or `LazyVGrid` without
  an outer `ScrollView` for multi-column), no `ScrollView`.
- **Compose** `"none"` → `Column` / `Row` + `forEachIndexed`, no
  `LazyColumn` / `LazyVerticalGrid`, no `verticalScroll`.
- **React** `"none"` → the same `div` + `.map()`, but
  `overflow-y-auto` / `overflow-x-auto` / `flex-nowrap` Tailwind classes
  are dropped (`"lazy"` and `"eager"` draw the same DOM on web).
- **UIKit** (generated) does not read `lazy` — `UICollectionView`
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
- `props.items[].type` → a type `g converter` knows (*Prop types*, below);
  `jsonui-doc validate component` accepts any string here.
- `slots.items[]` non-empty → the component is a **container** (children
  get rendered inside it). Empty or absent → no mode flag: the tool's
  default, which also draws children a layout gives it. `--from` / `--all`
  do not make a leaf of an empty `slots`; a leaf is declared once with
  `--no-container` (*Leaf components*, below), and later runs keep it.

Validate with `mcp__jui-tools__doc_validate_component`. Fix any violations.

### 2. Generate the converter FROM the spec

The framework has spec-driven scaffolding. Do NOT pass `--attributes` by
hand; drive it from the spec so the attribute list and types stay in sync
with the component's contract.

**You must run this explicitly** — `jui build` does NOT auto-run
converter scaffolding. That was tried and reverted: at the time the
downstream component generators (React/Swift/Kotlin component + adapter +
dynamic-component scaffolders) each prompted interactively on overwrite,
which blocked MCP / CI callers even when the outer `jui g converter`
honored `--skip-existing` (fixed in jsonui-cli 1.8.112, but the decision
stands). Keep `jui build` focused on "build what's written"; scaffold
explicitly when you add or change a spec.

```bash
jui g converter --from codeblock.component.json   # single spec
jui g converter --all                             # every component spec
jui g converter --all --skip-existing             # keep every existing
                                                   #   scaffold file, no prompts
jui g converter --all --force                     # replace every scaffold
                                                   #   file, no prompts (>= 1.8.113)
```

Under the hood (`generate_cmd.py::_cmd_generate_converter`):
- Reads `props.items[]` → `--attributes name:type,…`, and (jsonui-cli
  >= 1.8.113) each prop's `description` → `--attribute-descriptions`, so
  `attribute_definitions/<Name>.json` keeps the spec's sentence
- Reads `slots.items[]` non-empty → `--container`; empty or absent → no mode flag (the tool's default)
- Calls `sjui g converter` / `kjui g converter` / `rjui g converter` with
  the same args per platform listed in `jui.config.json::platforms`
- Every scaffold file (the converter and the downstream component /
  adapter scaffolds) goes through one overwrite decision (jsonui-cli
  >= 1.8.112): `--skip-existing` (exported as `JUI_SKIP_EXISTING=1`)
  keeps existing files without asking, and `--force` (>= 1.8.113;
  `sjui` / `kjui g converter` accept it too) replaces them without
  asking. With neither, the run asks only on a terminal: from jsonui-cli
  1.9.0 any other stdin (the MCP tool's, an agent's shell, CI) is
  not read, and each existing file is kept and named (`Kept existing
  <noun>: <path> (stdin is not a terminal; --force replaces it)`);
  before it, a closed stdin answered "no" and the MCP tool's open one
  waited until the call timed out. Scaffolds are the project's code once
  generated, so `--force` discards hand edits.

The direct form `jui g converter CodeBlock --attributes …` exists but is
only for one-off prototyping. **Production code always uses `--from` or
`--all`** — except to declare a leaf, once (below).

**Leaf components (1.9.0+).** A component that must never take
children keeps `slots.items` empty in its spec and is declared a leaf once,
by hand: `jui g converter <Name> --no-container` (an earlier `jui` rejects
the flag), or the MCP tool `jui_generate_converter` with `container: false`
from jsonui-mcp-server 2.14.0 — an earlier server passes
nothing and scaffolds the default form without an error. Then run `jui g
converter --from <name>.component.json --force`: it keeps the declaration,
says so (`<Name> is declared a leaf in attribute_definitions/<Name>.json —
kept (pass --container to change it)`), and writes the definition and the
scaffolds from the spec, leaf-shaped. `--force` is needed because the
direct run has already written the scaffolds, with placeholder descriptions
and only the attributes it was given (none without `--attributes`); without
it they are kept, and a prop missing from them is dropped from the view
without a warning. `--force` discards hand edits in the scaffolds. Later runs with neither flag —
`--from`, `--all`, with or without `--skip-existing` — keep the leaf; a
spec with slots makes `--from` pass `--container`, which turns it into a
container. The declaration is written by the project's own `sjui` / `kjui`
/ `rjui`, so run `jui sync_tool` after upgrading first — with older copies
`--no-container` exits 0 and declares nothing. Each platform tool's
`attribute_definitions/<Name>.json` then carries `"_children": "none"`,
and a layout that gives the component `child` / `children` (a node with a
`type` or an `include`, also through a style or inside an include) fails
the build by name:

`'<Name>' (id=<id>) takes no children — it is declared a leaf (`g converter <Name> --no-container`), so child[0] (id=<childId>) would be dropped. Remove the children, or regenerate the component with --container.`

That screen's view is not regenerated (web removes the one an earlier build
wrote; iOS and Android keep it), and `jui build` exits 1 (`… Pass
--allow-partial to accept a partial tree.` — never pass it to get past
this). When the children sit inside an included file, fix them there, in the file that holds the node. On iOS and Android the error is printed for that file and again for every layout that includes it, and none of those screens is regenerated (a partial is listed as `<file> (a partial, drawn by the layouts that include it) is refused: …`); web refuses the included file alone. The included file's own line names the node's `id=` as written there; a line for a layout that includes it names the id as that layout draws it — through an include with an `id`, prefixed (`<includeId><Id>`, e.g. `incBadge2` for `badge2`) — so look for the unprefixed id in the included file. Once it is fixed, the next `jui build` converts the refused layouts again — no `--clean`, also when only the component changed (on iOS and Android it then prints `The tool, a component or the config changed since the last build — every layout is converted`; web converts every layout on every build). Remove the children, or make the component a container: give its
spec `slots.items` entries and run `jui g converter --from
<name>.component.json --force`. Without `--force` the run keeps the
leaf-shaped scaffolds, names each of them (`<Name> would take children (…),
but this run kept … in the leaf form: … attribute_definitions/<Name>.json
still declares a leaf, so the build refuses children …`), and the component
stays a leaf. A platform tool run on its own (`sjui` / `kjui` / `rjui build`) prints the error and, in place of its success line, `Build finished with N stage(s) incomplete — see above` (sjui and kjui print their validation summary after it when there are warnings), but exits 0 — so judge by `jui build`, whose exit code is the verdict.

From 1.9.0 a component in the default mode or `--container`
declares `child` / `children` in its definition, which every `g converter`
run rewrites (`--skip-existing` keeps only the scaffolds). So `Unknown
attribute 'child' for component type '<Name>'` no longer appears for it.
Nothing in the build flags a layout that gives children to a default-mode
component whose spec lists no slots: the children are drawn. Read the
component spec before giving a custom component children.

**Prop types (1.9.0+).** `--from` / `--all` pass each
`props.items[].type` to `sjui` / `kjui` / `rjui g converter` as written. From
jsonui-cli 1.9.0, `sjui` in SwiftUI mode, `kjui` and `rjui`
read it through one table, so a component and its Dynamic adapter / wrapper
declare the same type (in UIKit mode `sjui g converter` writes a binding
handler and reads no table). Names are case-insensitive:

| Spec type | Swift | Kotlin | TypeScript |
|---|---|---|---|
| `String` | `String` | `String` | `string` |
| `Int` | `Int` | `Int` | `number` |
| `Long` | `Int` | `Long` | `number` |
| `Float` | `Double` | `Float` | `number` |
| `Double` | `Double` | `Double` | `number` |
| `CGFloat` | `CGFloat` | `Float` | `number` |
| `Bool` | `Bool` | `Boolean` | `boolean` |
| `Color` | `Color` | `Color` | `string` |
| `CollectionDataSource` | `CollectionDataSource?` | `CollectionDataSource?` | `any` |
| `Object` | `[String: Any]` | `Map<String, Any?>` | `Record<string, any>` |
| a callback: a closure type (`(() -> Void)?`, `((String) -> Void)?`), or `Callback` / `Action` / `Event` | that closure, optional (`(() -> Void)?` for the names) | `(() -> Unit)?` | `(...args: any[]) => void` |
| `T?` | `T?` | `T?` | as `T` (every React prop is optional) |
| `[T]` or `Array(T)` | `[T]` | `List<T>` — `List<Any?>` unless `T` is one of the first ten rows | `T[]` — `any[]` likewise |
| `Array` (a list of anything) | `[Any]` | `List<Any?>` | `any[]` |

`text`, `Integer`, `Number` (= `Double`), `Boolean`, `Hash` and
`Dictionary` are aliases; write the names in the table.

- A prop the layout leaves out takes the default its scaffold declares, never the spec's `default` (`g converter` reads neither `required` nor `default`). In Swift every `init` parameter of a new scaffold declares one: `""`, `0`, `0.0`, `false`, `.clear`, `[:]`, `[]`, and `nil` for an optional type. The Kotlin composable declares the same values (`Color.Unspecified` for a `Color`, `null` for an optional type). On web the prop is not passed, so it is `undefined` whatever its type. Type a prop `T?` when "not given" must read differently from that value, and have a web component handle `undefined`. A component scaffolded before 1.9.0 keeps its Swift `init`, which makes each `String`, `Int`, `Float` / `Double`, `Bool` and `Color` prop a required parameter: there a layout that leaves one out fails the iOS build (`missing argument for parameter …`, or `missing arguments for parameters …` for several).
- A literal the layout gives a prop is written only when it is of the
  prop's type: a string for `String` / `Color`, a whole number for `Int` /
  `Long`, a number for `Float` / `Double` / `CGFloat`, `true` / `false` for
  `Bool`, an object for `Object`, a JSON list of those for `[T]`. A
  callback, a `CollectionDataSource` and an app type take a binding
  (`@{…}`) — web alone writes an app type's JSON as it is. Any other value,
  and `null` for a type that is not optional, is not passed, and the build
  that converts the layout warns: `<Name>.<prop>: the layout's <value> is
  not a <type> literal this converter can write — …`. Only that build
  prints it — one that finds the layout cached does not — so read it again
  from `jui build --clean`. A converter scaffolded before
  1.9.0 keeps its own rules and names nothing.
- A callback's parameters reach Swift only: Kotlin gets `(() -> Unit)?` and
  TypeScript `(...args: any[]) => void`. Each `stateManagement.exposedEvents` entry is
  scaffolded as `Callback` unless `props.items[]` declares the same name.
- Any other type is an app type the app declares (`Row`, `[Row]`, `Date`).
  It is not refused: Swift gets `Row?` / `[Row]`, Kotlin `Any?` /
  `List<Any?>`, TypeScript `any` / `any[]`, and `sjui` (SwiftUI mode),
  `kjui` and `rjui` each print one line per such prop on every `g converter`
  run, and still exit 0: `Attribute '<name>': '<type>' is not in the
  attribute type vocabulary (…) — it is scaffolded as … Declare that type
  in the app, or use a vocabulary type.` (for a list: `Attribute '<name>':
  the element type of '<type>' is not …`; on a run that kept the scaffold:
  `… — the existing scaffold was kept (this run wrote none), so it declares
  whatever type it already did; a new scaffold would declare …`). Nothing else names it: `jsonui-doc validate component`
  does not check types, and a build names it only when a layout gives that
  prop a literal (the line above).
- Existing scaffolds are the project's code: `--skip-existing` keeps them
  byte for byte, and so does a run without a terminal (from
  1.9.0; before it, a closed stdin did): `--all` with neither
  flag asks per file only on a terminal. A scaffold made before 1.9.0 still compiles as it did
  but keeps that version's rules (its Swift `init`, its converter's
  literals, above): regenerate a component's scaffolds together with
  `--force` (hand edits are lost) when a layout leaves out such a prop or
  gives it literals. A new component, or `--force`, gets the table; deleting
  one scaffold file regenerates only that file, which then disagrees with
  the component's other scaffolds, so replace them together.

**A tap on a custom component.** A layout's `onClick` on a custom component
makes the tap, but JsonUI gives the component no screen-reader role — the
tap rule treats a type it does not declare as a control itself, on every
path, because it cannot see what the component holds. When the component is
operated as one control, give it the role in its own code: in the SwiftUI
view `.accessibilityAddTraits(.isButton)`, in the composable
`Modifier.semantics { role = Role.Button }`.

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
