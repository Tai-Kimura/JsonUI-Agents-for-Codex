---
name: jsonui-localize
description: Expert in localizing JsonUI screens. Extracts user-visible strings from JSON layouts and ViewModels, registers them in strings.json with multi-language values, and ensures proper string resolution (StringManager for iOS, R.string for Android).
tools: Read, Write, MultiEdit, Bash, Glob, Grep
---

# JsonUI Localize Skill

Localizes JSON layouts and ViewModels for multi-language support.

## Rule Reference

Read the following rule files first:
- `rules/file-locations.md` - File placement rules

## Input Parameters

Received from parent agent:
- `<tools_directory>`: Path to tools directory (e.g., `/path/to/project/sjui_tools`)
- `<specification>`: Path to screen specification JSON
- `<screen_name>`: Name of the screen being localized

## strings.json Format

Located at: `{layouts_directory}/Resources/strings.json`

### String values

```json
{
  "screen_name": {
    "key_name": "English only (used for all languages)",
    "another_key": {
      "en": "English text",
      "ja": "日本語テキスト"
    }
  }
}
```

- **String value**: Used as-is for all language files
- **Object value**: Language-specific values resolved per target file
  - Fallback order: target language → `en` → first available value → `""`

### Plural values (CLDR cardinal)

```json
"items_count": {
  "en": { "plural": { "one": "{count} item", "other": "{count} items" } },
  "ja": { "plural": { "other": "{count}件" } }
}
```

Rules (enforced by build validation — violations fail the build):

- Categories are CLDR cardinal: `zero` / `one` / `two` / `few` / `many` / `other`.
  `other` is **required** for every language.
- Only write categories the language's CLDR rules actually select — e.g. `zero`
  for `en` or `one` for `ja` is an **error** (the platform plural engines would
  never pick them and displays would diverge). en uses `one`/`other`; ja/zh/ko
  use `other` only.
- `{count}` is the **only** placeholder (a single number; it may appear more
  than once). printf-style specifiers (`%@`/`%s`/`%d`) are **not allowed**
  inside plural forms — they stay reserved for non-plural keys.
- A special wording for count=0 ("No items yet") is **not** a plural category —
  write it as a separate key and branch in the ViewModel.
- **Plural keys are VM-only (v1).** A layout string attribute (`text`, `hint`,
  …) referencing a plural key is a build error, because layout strings are
  inlined statically with no way to pass a count. Bind a computed ViewModel
  value instead (e.g. `"text": "@{itemsCountText}"`).
- The old idiom of separate singular/plural keys (`item_one` / `item_many`)
  is no longer needed for new keys; existing keys of that shape are harmless
  and need no migration.

### Key naming convention

- Keys are `snake_case`
- Grouped by file prefix (screen name): `"home": { "welcome_message": ... }`
- Full key in generated code: `{screen_name}_{key_name}` (e.g., `home_welcome_message`)

## Workflow

### Phase 1: Scan JSON Layouts

1. Read all JSON layout files for the screen (main layout + cell layouts + includes)
2. Identify all user-visible text strings:
   - `"text"` attributes with literal values (not bindings `@{...}`)
   - `"hint"` / `"placeholder"` attributes
   - `"alt"` attributes on Image/NetworkImage (web; screen-reader text — resolves
     strings.json keys like text/hint; decorative images should use `"alt": ""`).
     Never register Image `"src"` / `"srcName"` values — image sources are not
     user-visible text, and a src that collides with a strings key breaks the image
   - `"title"` attributes
   - Segment `"items"` arrays
   - ConfirmationDialog `"title"` values
   - Any other hardcoded user-facing strings
3. Skip:
   - Binding references (`@{propertyName}`)
   - Technical identifiers (`id`, `cellClasses`, etc.)
   - Color names, font names
   - Numeric values

### Phase 2: Scan ViewModel (the part no gate can do for you)

**This phase is the only check that exists for VM-side literals.** The layout
surface is machine-checked by `jui lint-strings`; `--usage` compares key sets.
A display string written directly into VM source references no key, so it is
invisible to both — every gate goes green and the untranslated text ships.
Skipping or skimming this phase is not "a lighter run", it is the whole check.

1. Read every VM/Repository/UseCase file the screen touches — **not just the
   file named after the screen**. Text is routinely assigned in a repository's
   error mapping.
2. Sweep mechanically rather than by eye:

   ```bash
   grep -nE '"[^"]*[^\x00-\x7F][^"]*"|"[A-Za-z][^"]{3,}"' <file>
   ```

3. Classify **every** hit. A literal is display text unless it is one of the
   closed list below; **when unsure, it is display text.** (A wrongly-localized
   internal string costs one redundant key; a wrongly-inlined display string
   ships untranslated with nothing reporting it.)

   **Allowed non-display literals** — dictionary/JSON keys and param names;
   API paths and URLs; enum raw values, state identifiers, screen ids; log and
   debug output that is never rendered; format specifiers and word-free
   separators (`"%.2f"`, `", "`); and key strings being passed *to* the
   resolver.

   **And one exception in the other direction:** text that is displayed but
   must NOT follow the active language — a language switcher whose options
   each render in their own language (`["日本語", "English"]`), proper nouns,
   brand names. **Localizing these is the bug.** Leave them, and add a comment
   saying why: "deliberately not localized" and "nobody noticed" look identical
   in source, and the next sweep has to tell them apart.

4. These are display text and are the ones actually missed, because they get
   written while thinking about something else:
   - **Error and validation messages**
   - **Empty-state and placeholder text**
   - **Alert/dialog titles, bodies, and button labels** — including `"OK"` / `"キャンセル"`
   - **Status and result labels assigned in code**
   - **Units and suffixes concatenated onto numbers** (`"\(count)件"`, `"円"`)
   - **Accessibility labels and hints**
   - **Words produced by a `switch`/`when` over a state**

5. Report the count of literals you swept and the count you localized. "0
   found" is a measurement — say how many you looked at, so a scan that read
   the wrong file is distinguishable from a screen that was already clean.

### Phase 3: Register in strings.json

1. Read existing `strings.json`
2. For each identified string:
   - Generate a descriptive `snake_case` key
   - Check if already registered (don't duplicate)
   - Add with multi-language object format if translations are known:
     ```json
     "welcome_title": {
       "en": "Welcome!",
       "ja": "ようこそ！"
     }
     ```
   - If translation is not known, add as string value and add a TODO comment in the commit
3. Write updated `strings.json`

### Phase 4: Update JSON Layouts

For strings registered in Phase 3, the JSON layout text values are already used by the build tool to generate localized code:
- **sjui build**: Generates `StringManager.ScreenName.keyName()` calls
- **kjui build**: Generates `stringResource(R.string.screen_name_key_name)` calls

No manual layout changes needed — the build tool handles the mapping from text values to localized string references.

### Phase 5: Update ViewModel

For strings identified in ViewModel (Phase 2):

**iOS (Swift)**:
```swift
// Before
data.errorMessage = "Network error occurred"

// After
data.errorMessage = StringManager.ScreenName.networkError()
```

**Android (Kotlin)**:
```kotlin
// Before
viewModel.updateData(mapOf("errorMessage" to "Network error occurred"))

// After - use context.getString()
viewModel.updateData(mapOf("errorMessage" to context.getString(R.string.screen_name_network_error)))
```

### Phase 6: Verify

1. Run build: `{tools_directory}/bin/{cli} build`
2. Verify no warnings about missing strings
3. Verify all string references resolve correctly
4. **The completion gate is `jui lint-strings` — exit 0 required.** It
   machine-checks the layout surface (raw literals that don't resolve via
   `strings.json`); this skill is the repair tool for its findings.
   Intentional non-localized literals go in `.jui-strings-allowlist.json`
   with a reason (see `rules/invariants.md` invariant 4).
5. **`jui lint-strings --usage` additionally checks the VM surface**, and is
   worth running on any screen this skill touched. It reads references on
   every declared platform — web `StringManager` props, iOS
   `StringManager` accessors / `"key".localized()` / `NSLocalizedString` /
   `String(localized:)`, Android `R.string` — plus a spec's
   `branchContracts` `@key` expectations, and reports three directions:

   | Finding | Meaning |
   |---|---|
   | `missing-key` | a reference resolving in neither `strings.json` nor the platform's own catalogs (`Localizable.strings` / `.xcstrings` / `.stringsdict`) — **the raw key reaches the screen** |
   | `unused-key` | a table entry no face references |
   | `dynamic-ref` | a lookup whose key is not a literal and whose statement names no `*_STRING_KEYS` map — the closure that makes the other two trustworthy |

   It is opt-in per run (or per project via `lint.stringsUsage`). What it
   does **not** see is a literal that was never routed through the table at
   all — a hardcoded display string in VM source is still this skill's
   territory to find by reading.

## Platform-Specific String Resolution

| Platform | JSON text value | Generated code |
|----------|----------------|----------------|
| iOS (sjui) | `"Sign In"` | `StringManager.Login.signIn()` |
| Android (kjui) | `"Sign In"` | `stringResource(R.string.login_sign_in)` |
| React (rjui) | `"Sign In"` | `t('login.signIn')` |

### Plural key resolution (VM code only)

| Platform | Mechanism | ViewModel usage |
|----------|-----------|-----------------|
| iOS (sjui) | auto-generated `Localizable.stringsdict` | `StringManager.Home.itemsCount(count: n)` |
| Android (kjui) | `<plurals>` in `values*/strings.xml` (R.plurals) | `context.resources.getQuantityString(R.plurals.home_items_count, n, n)` / Compose: `pluralStringResource(R.plurals.home_items_count, n, n)` |
| React (rjui) | generated plural tables + `Intl.PluralRules` | `StringManager.plural('home_items_count', n)` (`getDefaultPlural` for SSR-safe seed code) |

Notes:

- iOS `.stringsdict` files are **fully auto-generated** by `sjui build` from
  strings.json. Never edit them, and never re-register keys that already exist
  there — they are already covered by strings.json plural entries.
- rjui: count-less access to a plural key (`$s.homeItemsCount`,
  `getString('home_items_count')`) throws at runtime by design — always pass
  the count through `plural()`.

## Special Cases

### Segment items
```json
"items": ["Tab A", "Tab B"]
```
Each item is extracted and localized individually. The build tool generates localized item arrays.

### Newlines in strings
Use `\n` in strings.json values:
```json
"multi_line": {
  "en": "Line 1\nLine 2",
  "ja": "1行目\n2行目"
}
```

### Strings with parameters
Use `%@` (iOS) / `%s` (Android) format specifiers:
```json
"result_message": {
  "en": "%d items found",
  "ja": "%d件見つかりました"
}
```

If the wording must change with the number (singular/plural), do NOT use a
format-specifier string — register a plural entry instead (see "Plural values"
above) and resolve it from the ViewModel with a count.

## Variant files

Responsive variant layouts (`home@regular.json`) are scanned like any
layout, but their strings register under the BASE screen's namespace
(`home`) — the variant is the same screen, so shared wording dedupes
into one key. When you localize a screen, scan its variant files too;
variant-only strings still need entries.

## Output

Report back to parent agent:
- Number of strings extracted from layout
- Number of strings extracted from ViewModel
- Number of new entries added to strings.json
- Number of entries needing translation (TODO)
- Any ViewModel modifications made
