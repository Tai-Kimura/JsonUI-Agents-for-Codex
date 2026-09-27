---
name: jsonui-layout
description: Expert in implementing JSON layouts for JsonUI frameworks. Creates correct view structures, validates attributes, and ensures proper binding syntax across SwiftJsonUI, KotlinJsonUI, and ReactJsonUI.
tools: Read, Write, MultiEdit, Bash, Glob, Grep
---

# JsonUI Layout Agent

Specialized in correct JSON layout implementation. Styles extraction and DRY cleanup are done inline — there is no separate refactor skill.

## `role` — declaring what a layout IS

A layout root may declare `"role": "screen" | "cell" | "partial"`. It decides
whether the layout is a navigation destination (and so carries a screen marker
and may appear as a test's `screen`) or a fragment that renders inside a host.

When it is absent the role is DERIVED: a layout referenced by another via
`cell` / `header` / `footer` / `cellClasses` / `include` is a fragment,
`"partial": true` is a fragment, and anything left over is a screen. The
derivation is deliberately imperfect — a fragment that nothing references yet
derives to "screen". `jui build` reports this, and the fix is to declare the
role explicitly, never to rename the file.

Declare `"role"` explicitly whenever a layout's purpose is not obvious from how
it is referenced.

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
- `stateManagement.displayLogic` - Visibility rules (may include explicit `variableName`). A node that an `element` or a state's `visibleElements` names takes that id exactly as the spec writes it — except inside an include that has an id, where the spec names the resolved id (`hero` + `type_badge` → `heroTypeBadge`) and the node in the included layout keeps its own (`type_badge`). When the node already exists under another spelling, the spec is what gets corrected — do not rename the node.

## Creating new sub-files

A new sub-file (partial, collection cell) referenced from a Layout JSON is a Layout JSON you write by hand in the shared layouts directory, at the path the reference names: jui has no command that generates one (`jui g partial` / `jui g collection` do not exist). A layout that nothing references yet reads as a screen with no spec in `jui verify` — add the reference in the same change, or put `"partial": true` on its root.

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
  "items": "@{productItems}",
  "sections": [{ "cell": "item_cell" }]
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

## Embed (Cross-Screen Embedding)

Use `Embed` when a screen hosts another screen as a region of its layout (tablet master/detail, dashboard panels). **The embedded screen owns its own ViewModel** — completely independent from the parent VM. This is the core design contract; it is what separates `Embed` from `include` (which shares the parent VM) and `TabView` (which also shares).

### When to use Embed

- iPad master/detail: master list on the left, embed `OrderDetail` on the right
- Dashboards: a dashboard screen hosting `RecentActivity`, `Calendar`, etc.
- Same screen reused: phone shows it standalone, tablet embeds it inside a parent

### Layout JSON shape

```json
{
  "type": "View",
  "id": "rootContainer",
  "orientation": "horizontal",
  "child": [
    {
      "type": "View",
      "id": "masterPane",
      "width": 320,
      "child": [ /* master list */ ]
    },
    {
      "type": "Embed",
      "id": "detailPane",
      "screen": "order_detail",
      "params": { "orderId": "@{selectedOrderId}" },
      "navigationMode": "delegate",
      "weight": 1
    }
  ]
}
```

### Attribute conventions

| Attribute | Convention | Notes |
|---|---|---|
| `id` | **camelCase**, unique within the parent layout | Doubles as the Android `ViewModelStoreOwner` key — must be unique even when the same screen is embedded twice. |
| `screen` | **snake_case layout JSON filename** (no extension) | E.g. `order_detail` loads `docs/screens/layouts/order_detail.json`. Codegen converts to PascalCase View class name. |
| `params` | keys camelCase | Values: literal or `@{varName}` binding against the parent VM. Embedded VMs that implement `applyInitParams(_:)` consume them; others ignore. |
| `navigationMode` | `"delegate"` (default) or `"isolated"` | delegate forwards `navigate()` to the parent's NavController/Router; isolated gives the embed a private stack, and `jui build` refuses it when the embedded screen's spec declares a present-type transition. |

### Rules

- **Same screen multi-embed** is supported. Each Layout JSON `Embed.id` keys a separate VM instance. ID uniqueness is critical on Android.
- **Embedded screen needs no changes** — its spec and layout stay as-is. The parent declares the embedding.
- **Navigation bounded at the embed**: `pop` / `dismiss` / `navigateBack` from inside the embedded screen do NOT close the embed itself (runtime enforces this in delegate mode).
- **No localize on the Embed node** — the node has no user-visible strings. The embedded screen is localized as part of its own implementation.
- **Spec contract**: when adding an Embed to a Layout JSON, the parent spec must also declare `structure.embeds[]` with a matching `regionId` (camelCase same as the layout `id`), or `jui verify` will flag drift.

→ Examples: `examples/embed.json` (parent layout), `examples/embed-spec-fragment.json` (spec side).

See also `rules/specification-rules.md` (5) Section and `rules/design-philosophy.md` "VM isolation across embedded screens".

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
- **Never prefix with `data.`** — bindings reference variables by bare name regardless of where they're declared (`data: [...]` at the root of a cell Layout, `stateManagement.uiVariables` in the spec, `dataFlow.viewModel.vars` — all resolve the same way at the binding site)

**Wrong:** `"@{data.titleKey}"`, `"@{data.onNavigate}"`
**Right:** `"@{titleKey}"`, `"@{onNavigate}"`

The `data: [...]` block in a Collection cell Layout only DECLARES the variable names + types; it is not a namespace. Downstream generators (sjui / kjui / rjui) emit direct property access from the bare names — a `data.` prefix becomes a broken path at runtime.

### This Skill Does Not Define the Data Section

Only write `@{bindingName}`. Type definitions live in the spec's `stateManagement.uiVariables` and `dataFlow.viewModel.vars` — see the `jsonui-dataflow` skill.

### Canonical Expression Forms (SwiftJsonUI ≥ 10.6.0 / KotlinJsonUI ≥ 2.13.0)

The resolution semantics are SSoT-declared (`shared/core/binding_semantics.json`;
`get_binding_rules` returns them under `semantics`). Canonical forms:

- **Dot path / bracket index** (read-only value + text contexts, all platforms):
  `@{profile.name}`, `@{items[0].title}`
- **Default**: `@{title ?? "Untitled"}` or `?? 'Untitled'` — ONE `??` max;
  string defaults in single or double quotes, `true`/`false`/number bare.
  A resolved value (even `false`/`0`/`""`) always wins over the default.
- **Negation**: `@{!isHidden}` — **boolean value attributes only**
  (`hidden`, `enabled`, ...). Anywhere else it is a validator error.
- **Two-way bindings** (TextField text, Switch isOn, ...) must be a single
  flat identifier — no dots, brackets, `??`, or `!`.
- **A control's value written without a binding** (`"isOn": true`,
  `"selectedIndex": 1`, a Slider's `"value": 0.3`) is where the control
  starts: the user changes it, and the view model does not hold it. Bind it
  (`"isOn": "@{notifyOn}"`) when the view model must read or set it; add
  `enabled: false` when the user must not change it. In the SwiftUI, Compose and web code `jui build` generates this
  holds from jsonui-cli 1.9.0 — before, on Android a static Switch, CheckBox,
  Radio, Segment, Slider or SelectBox did not move when tapped, and on web a
  Radio's static `selectedValue`, a Segment, a TabView and a date SelectBox
  did not. A Slider with no `value` starts at its minimum; on web, one with no
  `step` (a web-only attribute) moves continuously — before 1.9.0 the web slider moved in whole steps, so
  over the default range 0 … 1 it had two positions: one with no `value`
  started at 1, and a `"value": 0.3` was drawn at 0.
- Unresolved keys: text renders empty, typed values fall back to the
  attribute default, Embed params drop the key (child defaults apply).

### No Logic in Bindings (Critical)

**Prohibited patterns:**
- `@{selectedTab == 0 ? #D4A574 : #B8A894}` - Ternary operators
- `@{items.count > 0}` - Comparisons
- `@{price * quantity}` - Calculations

**Allowed:**
- `@{searchTabColor}` - ViewModel computed property
- `@{onButtonTap}` - ViewModel function
- `@{!isHidden}` - Negation, on boolean value attributes only

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

### Images: `alt` is what screen readers say (1.9.0+)

`alt` on Image, CircleImage and NetworkImage is the text VoiceOver, TalkBack
and the web read for the image, in SwiftUI, Compose and web layouts (UIKit
and Android Views layouts do not read it):

- `"alt": "photo_label"` — a strings.json key (or text), localized like `text`
- `"alt": "@{photoTitle}"` — a binding; `""` at runtime makes the image decorative
- `"alt": ""` — decorative, on purpose

With no `alt` an image is decorative (screen readers skip it), unless it
operates something: a tap of its own (*Tappables are announced as buttons*,
below, says what is one) or an `onLongPress` that names a method (not with `enabled: false`, and not
inside `userInteractionEnabled: false`), or it is the only thing naming the nearest element around
it that operates something, long press included (no text, no other image
with an `alt`).
Such an image keeps reading what it read before (its id or asset name, a
fixed word, or nothing — an Android Image with no id, and any web image),
and the iOS and Android builds name it (web does not):
`[info] <layout>.json: <Type> '<id>' operates a control and has no alt, …`.
Give it an `alt` that says what the control does.

Nothing can tell a meaningful image from decoration, so decide for each one: a
logo, a product or profile photo, and an icon that is a button's only content
(close, send, menu) need an `alt`; an icon beside text that already says it, a
divider and a background do not.

Write `alt`: `accessibilityLabel` and `contentDescription` are read as aliases,
and `jui build` rewrites them to `alt` in the layouts it distributes (your
layout file keeps its spelling). The SwiftUI / Compose Dynamic mode (hot
reload) reads all three spellings from SwiftJsonUI 10.29.0
/ KotlinJsonUI 2.42.0. Before jsonui-cli 1.9.0, `alt` was
read on web only; iOS and Android read an internal name (the asset name, the
id, or a fixed English word) or, for an Android Image with no id, nothing,
except that Android read a `contentDescription` the layout wrote.

### Tappables are announced as buttons (1.9.0+)

In SwiftUI and Compose layouts (UIKit and Android Views layouts are outside
this), an element whose `onClick` or `onclick` names a method, and that is
not a control itself, is announced as a button on iOS, and on Android when it
has no children, unless it holds something a user can operate on its own —
how depends on what it holds:

- with no children (an Image, a Label), it is the button, on iOS and Android;
- with children, none of which a user can operate on its own, on iOS it
  becomes one button whose name is its content — so it needs a text, or an
  image with an `alt` (above), inside it. When nothing else inside names it,
  an image with no `alt` keeps reading what it read before (its id or asset
  name, a fixed word, or nothing), and the iOS and Android builds name it
  (INFO). On Android
  the container gets the button role, but Compose reports the Button class
  only for a node without children, so it keeps the class of a plain view;
- when it holds something a user can operate on its own, it is left as it
  was and is not announced as a button. That is: a type declared
  `interactive: true` in component_metadata.json (TextField, Switch,
  Collection, ScrollView, Web, …), a type the declaration does not know (a
  custom component), a descendant that is a tap itself or has an
  `onLongPress` that names a method (not with `enabled: false`), or a Label
  with links (`linkable`, or a
  `partialAttributes` range with `onClick` / `onclick`). A screen-reader
  user can still reach what is inside, but is not told the container is a
  button.

A project's own component counts as a control itself, so a custom
component with `onClick` is never announced as a button, with or without
children. JsonUI does not know what a project's component holds, and a button or a
combined element could hide a control inside it from screen readers — so
the component gives itself its role, in its own code: in its SwiftUI view
`.accessibilityAddTraits(.isButton)`, in its composable
`Modifier.semantics { role = Role.Button }`.

What is not a tap:

- A handler that names no method — `""`, spaces only, `"@{}"`, `[]`,
  `[""]`. Nothing is generated for it, and `jui build` warns `Attribute
  '<path>' in '<Type>' names no handler (…) — no tap is generated for it.
  Name the method, or remove the attribute`; a blank element of an
  `onclick` array is skipped with `… has a blank handler at [<i>] — it names
  no method and is not called`. Earlier releases generated code for most of
  these that did not compile (`[]` gave a tap that called nothing). Name the
  method, or leave the attribute out until the method exists.
- A tap written shut: `enabled: false`, `canTap: false`, or
  `userInteractionEnabled: false` on it or on a node around it — inside such
  a node nothing counts as operated, a long press included. `canTap` is a
  gate, not a handler — `false` (or a binding that resolves false) turns
  `onClick` / `onclick` off, and with no `canTap` the handler alone makes
  the tap, so never add `canTap: true` to make one. A container whose only
  handler is `onLongPress`, or that has `canTap` and no handler, is not a
  tap either. (In UIKit layouts `canTap` sets only the pressed state.)
  A Button is a control, not a tap: under `enabled: false` it is a dimmed
  button, and under `canTap: false` a button whose action does nothing. So
  is an IconLabel with a handler on iOS, where it is drawn as a native
  button.
- An `onClick` / `onclick` on a text field (TextField, TextView, EditText or
  Input). A text field's
  tap focuses it; from jsonui-cli 1.9.0 `jui build`
  warns `onClick on a TextField is not called: a text field's tap focuses
  it` (`… on a TextView …`) once for each such node. Remove the handler — bind `text` to read what the user types;
  `onTextChange` is called on each change.

A control's own `onClick` — on a Switch, Toggle, CheckBox, Radio, Segment,
Slider or SelectBox — is called once, after the control's own change (a Slider's when the drag
ends), in the SwiftUI, Compose and web code `jui build` generates from
jsonui-cli 1.9.0: `canTap: false` stops the call and not the change, and
`enabled: false` stops both. Dynamic mode (hot reload) ships with
SwiftJsonUI and KotlinJsonUI, not with jsonui-cli. To act on a control's change,
bind its value (the view model's var then changes with it) rather than
reading it in `onClick`.

A tap whose `enabled` is bound stays a button, and reads as disabled while
the value is false, on iOS and Android. A bound `canTap` or `userInteractionEnabled` also stops the tap while it is false, and the element is not announced as a button then (a
Button, and an IconLabel on iOS, stay a button that does nothing), but
nothing marks it disabled — so to switch a tap off at run time and have it
read as disabled, bind `enabled`.

Each id inside a tappable is found once, by its own id, on iOS and Android,
so a test finds a Label inside a tappable by its own id. A tappable with an
id carries it too, so a test finds the container by its id; one with no id
cannot be found as a whole (on iOS its button's identifier is empty) —
reach it through an id inside it, and give a tappable with nothing inside
(an Image, a Label) an id of its own. This holds for a project's own
container components too, once their converter is scaffolded by
1.9.0 or later (on iOS, regenerate an older one as it was
made, with `--force` added — `jui g converter --from <spec> --force` — which
discards hand edits). The SwiftUI / Compose Dynamic mode (hot reload) does
the same from SwiftJsonUI 10.29.0 / KotlinJsonUI
2.42.0, except that on iOS, while a bound `canTap` is
false, a container is not combined into one element.

On web, from jsonui-cli 1.9.0, the same rule gives a tap it makes a button —
or one element — `role="button"`, a tab stop (`tabIndex={0}`) and Enter /
Space that click it; a bound `canTap` or `enabled` gates all three, and a
control, a project's own component, a tap holding a control and a tap inside
a stop are left as they are. What `userInteractionEnabled: false` (or a
binding while it is false) stops is `inert` there: out of reach of the
pointer, the keyboard and screen readers, and drawn the same. Before
1.9.0, a web Label or View with `onClick` was reached by neither Tab nor a
screen reader's list of buttons, and `userInteractionEnabled: false` stopped
the pointer alone.

On web, from jsonui-cli 1.9.1, a tap inside another tap in the same
layout file stops the click there, as on iOS / Android; to let a click
through, declare the handler `(Event)` in the layout's data and decide in
the view model.

---

## String Resources

### strings.json Format

Structure: `{ "file_prefix": { "key": "value" } }`

→ Example: `examples/strings-json.json`

- `file_prefix`: Matches JSON layout filename (`login.json` → `"login"`)
- Reuse existing keys when available

### Text Extraction Rules

Extracted attributes: `text`, `hint`, `placeholder`, `label`, `prompt`, and `alt` from jsonui-cli 1.9.0

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

### `tintColor` is an accent, not a text colour

`tintColor` colours what is operated — a control's accent, a link, a text field's cursor (SwiftUI's `.tint`, CSS `accent-color`). Give text its colour with `fontColor`. In the Compose code kjui generates, text and icons that set no colour of their own inside a node with `tintColor` took the tint before jsonui-cli 1.9.0, and do not from 1.9.0 (KotlinJsonUI Dynamic never passed it on): where a layout relied on that, give them `fontColor`.

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
1. Scaffold it from its component spec: `jui g converter --from <name>.component.json` (the specification rules, *Custom Components — spec first*). Its prop types are the spec's `props.items[].type` (*Prop types* there); `lookup_attribute` describes the standard components, not these props
2. When a layout uses it, a prop it leaves out takes the scaffold's default, never the spec's `default`: the type's value on iOS and Android (`""`, 0, false, `[]` …; `nil` for `T?`), `undefined` on web — with a component scaffolded before jsonui-cli 1.9.0, a non-optional scalar left out fails the iOS build. A literal must be of the prop's spec type; a callback, a `CollectionDataSource` or an app type takes a binding (`@{…}`). Any other value is not passed, and the build that converts the layout warns `<Name>.<prop>: the layout's <value> is not a <type> literal this converter can write — …` — not again while the layout is cached, so read it from `jui build --clean` (the specification rules, *Prop types*).
3. Do not pass `--attributes` or `--container` by hand: `--from` / `--all` read the props and slots from the spec. The one thing declared by hand is a leaf, once, with `jui g converter <Name> --no-container`. Do not add it to a `--from` run, which does not read it (the specification rules, *Leaf components*). `--skip-existing` / `--force` only choose what happens to scaffold files that already exist
4. Give a custom component children only when its component spec lists
   slots (`slots.items` is non-empty). From jsonui-cli 1.9.0 a
   component declared a leaf (`--no-container`) fails the build when a
   layout gives it children, and a component in the default mode draws them
   without a word — see the specification rules, *Leaf components*
5. A layout's `onClick` on a custom component gives it no screen-reader role
   (*Tappables are announced as buttons*, above): the component gives itself
   its role in its own code (the specification rules, *A tap on a custom
   component*)

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
- For completely different structures, use variant files (`screen@regular.json`) — see below

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

## Variant Files (whole-tree replacement per size class)

When a size class needs a **structurally different** layout (not just
attribute tweaks), ship a sibling variant file:

```
Layouts/home.json            ← base (REQUIRED, canonical)
Layouts/home@regular.json    ← full replacement for the regular tier
```

**Vocabulary (v1):** `@compact` / `@medium` / `@regular` only.
Landscape and combined forms stay in the inline `responsive` attribute.
`@tablet` is not a size class — use `@regular`.

**Resolution:** tier X renders `<base>@X.json` when it exists, otherwise
the base. No cross-tier promotion (a medium window with only `@regular`
shipped renders the base). Tier detection matches inline `responsive`:
iOS horizontal size class (no medium on iOS — `@medium` folds into the
compact tier, `@compact` wins when both exist), Android 600/840dp, web
768/1024px.

**Contract (enforced as `jui build` errors):**
- The variant is a FULL replacement — no partial merge (share structure
  via `include`/styles instead)
- Variants must NOT declare a `data` section — the data contract is
  base-canonical; every `@{binding}` in a variant must be declared in
  the base's `data` section
- Variants must NOT declare `platforms` (inherited from the base)
- Screen-root layouts only: no variants of `partial: true` layouts or
  Collection cell layouts
- A real layout named `<base>_<class>_variant.json` collides with the
  generated variant view name

**State contract:** a size-class change swaps the whole tree — VM-owned
state (bindings) survives (one VM instance spans the swap); view-local
state (scroll position, unbound input, focus) is lost by design. Any
input that must survive a Split View / foldable transition belongs in a
VM binding.

**Generated code:** the base screen's GeneratedView gains a size-class
dispatch and each variant gets its own `<Base><Class>VariantGeneratedView`
sharing the base's Data/ViewModel. Variants never generate their own
VM/Data/spec. Old dynamic runtimes ignore variant files and render the
base (graceful degradation).

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
