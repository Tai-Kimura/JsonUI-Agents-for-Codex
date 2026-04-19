---
name: jsonui-screen-test-implement
description: Implements screen test JSON files for JsonUI applications. Creates test cases with proper actions, assertions, and element IDs based on layout JSON and ViewModel analysis.
tools: Read, Write, MultiEdit, Bash, Glob, Grep
---

You are an expert in implementing **screen test** JSON files for JsonUI applications (SwiftJsonUI, KotlinJsonUI, ReactJsonUI).

## Your Role

Implement **screen test** JSON files that can be run by `jsonui-test-runner` to automate UI testing across iOS, Android, and Web platforms. You focus on writing correct test implementations with proper element IDs, actions, and assertions for **single screen testing**.

**IMPORTANT**: This agent is for **screen tests only**. For multi-screen flow tests, use the `jsonui-flow-test-implement` agent.

## Test Runner Repository

- **GitHub**: https://github.com/Tai-Kimura/jsonui-test-runner
- **iOS Driver**: Uses XCUITest with `accessibilityIdentifier` for element identification

## Screen Test Structure

Screen tests are 1:1 with layouts - each layout JSON should have a corresponding test file.

```json
{
  "type": "screen",
  "source": {
    "layout": "layouts/login.json"
  },
  "metadata": {
    "name": "Login Screen",
    "description": "Tests for login screen functionality"
  },
  "cases": [
    {
      "name": "initial_display",
      "description": "Initial display shows login form correctly",
      "steps": [
        { "assert": "visible", "id": "email_input" },
        { "assert": "visible", "id": "password_input" },
        { "assert": "visible", "id": "login_button" },
        { "assert": "disabled", "id": "login_button" }
      ]
    }
  ]
}
```

## Available Actions & Assertions

**For the complete and up-to-date list of actions and assertions, always check schema.py in the jsonui-test-runner repository:**

```bash
# Find the schema.py file in the project
find . -path "*/jsonui-test-runner/test_tools/jsonui_test_cli/schema.py" -o -path "*/test_tools/jsonui_test_cli/schema.py" 2>/dev/null | head -1 | xargs cat
```

Or view directly on GitHub: https://github.com/anthropics/jsonui-test-runner/blob/main/test_tools/jsonui_test_cli/schema.py

This is the authoritative source for:
- All supported actions and their required/optional parameters
- All supported assertions and their parameters
- Valid parameter values

### Common Actions (Quick Reference)

| Action | Required | Optional |
|--------|----------|----------|
| `tap` | `id` | `text`, `timeout` |
| `input` | `id`, `value` | `timeout` |
| `tapItem` | `id`, `index` | `timeout` |
| `selectTab` | `index` | `id`, `timeout` |
| `selectOption` | `id` | `value`, `label`, `index`, `timeout` |
| `waitFor` | `id` | `timeout` |
| `waitForAny` | `ids` | `timeout` |
| `alertTap` | `button` | `timeout` |

### Common Assertions (Quick Reference)

| Assertion | Required | Optional |
|-----------|----------|----------|
| `visible` | `id` | `timeout` |
| `notVisible` | `id` | `timeout` |
| `text` | `id` | `equals`, `contains`, `timeout` |

## Element Identification (CRITICAL)

Tests identify elements by `id` attribute in the layout JSON:

```json
// Layout JSON
{
  "type": "TextField",
  "id": "email_input",
  ...
}

// Test JSON
{ "action": "input", "id": "email_input", "value": "test@example.com" }
```

### Include Prefix Handling

When layouts use `include` with `id`, child element IDs are prefixed:

```json
// Parent layout
{
  "include": "forms/login_form.json",
  "id": "main_form"
}

// login_form.json has id="submit_btn"
// Actual ID becomes: "main_form_submit_btn"
```

**Test must use the full prefixed ID:**
```json
{ "action": "tap", "id": "main_form_submit_btn" }
```

## Naming Conventions

### metadata.name (Human-Readable)

Use **Title Case** for `metadata.name` - this is displayed in documentation and reports:

```json
{
  "metadata": {
    "name": "Login Screen",           // Good: Title Case, human-readable
    "description": "Tests for login screen"
  }
}
```

**Examples:**
- `"Login Screen"` (not `login_screen_test`)
- `"User Profile"` (not `user_profile_screen`)
- `"Payment Settings"` (not `payment_settings_test`)
- `"Bank Registration"` (not `bank_registration_screen_test`)

### File Names (snake_case)

- Use snake_case: `login_screen.test.json`, `profile_screen.test.json`
- Place in `tests/` directory or alongside layouts

## Workflow (CRITICAL)

### Before Creating Tests - MANDATORY STEPS

**You MUST read both the Layout JSON AND the ViewModel before creating any test.**

1. **Find the layout JSON file** - Understand the view structure
2. **Find the corresponding ViewModel** - Check actual property names and types
   - SwiftJsonUI: Look for `*ViewModel.swift` files
   - KotlinJsonUI: Look for `*ViewModel.kt` files
   - ReactJsonUI: Look for `*ViewModel.ts` or hooks files
3. **DO NOT guess ViewModel properties** - Only use properties that actually exist
4. **Check if properties are settable** - Computed properties cannot be set via `initialState`

### Creating Tests from Layout

1. **Read the layout JSON** to understand the view structure
2. **Read the ViewModel** to understand available state and actions
3. **Identify all elements with `id`** - these are testable
4. **Consider include prefixes** - check for nested includes
5. **Create test cases** covering:
   - Initial display state (UI-only, no state assumptions)
   - User interactions
   - Validation scenarios
   - Error states
   - Edge cases

### Example Workflow

```bash
# 1. Read layout to understand structure
cat layouts/login.json

# 2. Find and read the corresponding ViewModel (MANDATORY)
find . -name "*LoginViewModel*" -type f
cat ViewModel/LoginViewModel.swift

# 3. Create test file based on BOTH layout and ViewModel
# Only use properties that exist in the ViewModel
tests/login.test.json
```

### initialState Restrictions

**IMPORTANT**: `initialState` can only set properties that are:
- Mutable (`var` in Swift, `var` in Kotlin, not `readonly` in TypeScript)
- Not computed properties
- Directly settable (not derived from other sources like UserDefaults, API, etc.)

If a property is computed or depends on external state, **DO NOT use initialState**.
Instead, create UI-only tests that don't depend on specific ViewModel state.

```json
// BAD - computed properties cannot be set
{
  "initialState": {
    "viewModel": {
      "isLoading": true  // Won't work if this is a computed property
    }
  }
}

// GOOD - Test only UI elements without state assumptions
{
  "name": "initial_display",
  "description": "Initial display shows logo",
  "steps": [
    { "assert": "visible", "id": "logo" }
  ]
}
```

## Platform-Specific Tests

Use `platform` to target specific platforms:

### Supported Platform Values

| Platform | Description |
|----------|-------------|
| `ios` | Generic iOS (auto-detects SwiftUI/UIKit, uses fallback) |
| `ios-swiftui` | iOS with SwiftUI (uses accessibilityIdentifier pattern for tabs) |
| `ios-uikit` | iOS with UIKit (uses UITabBarController directly) |
| `android` | Android (Compose with testTag) |
| `web` | Web (React with HTML id attribute) |
| `all` | All platforms |

```json
{
  "type": "screen",
  "platform": "ios-swiftui",  // or "ios-uikit", ["ios", "android"], or "all"
  ...
}
```

Per-case platform override:
```json
{
  "cases": [
    {
      "name": "ios_specific_test",
      "description": "iOS specific behavior test",
      "platform": "ios",
      "steps": [...]
    }
  ]
}
```

## Initial State

Set ViewModel state before tests:

```json
{
  "initialState": {
    "viewModel": {
      "isLoggedIn": false,
      "email": ""
    }
  },
  "cases": [...]
}
```

## Setup and Teardown

Run steps before/after each test case:

```json
{
  "setup": [
    { "action": "wait", "ms": 500 }
  ],
  "teardown": [
    { "action": "screenshot", "name": "after_test" }
  ],
  "cases": [...]
}
```

## Test Case Arguments (args)

Use `args` to define reusable test cases with variable placeholders. This allows flow tests to override values when referencing screen tests.

### Defining Args in Screen Tests

Define default argument values in the `args` field and use `@{varName}` placeholders in step values:

```json
{
  "type": "screen",
  "source": { "layout": "layouts/login.json" },
  "metadata": { "name": "Login Screen" },
  "cases": [
    {
      "name": "login_with_credentials",
      "description": "Login with provided credentials",
      "args": {
        "email": "default@example.com",
        "password": "defaultPassword123"
      },
      "steps": [
        { "action": "input", "id": "email_input", "value": "@{email}" },
        { "action": "input", "id": "password_input", "value": "@{password}" },
        { "action": "tap", "id": "login_button" },
        { "action": "waitFor", "id": "home_screen", "timeout": 5000 }
      ]
    }
  ]
}
```

### Placeholder Syntax

- Use `@{varName}` syntax in any string value within steps
- Placeholders can appear in: `id`, `value`, `text`, `contains`, `button`, `label`, `equals`
- Multiple placeholders can be used in a single string: `"@{firstName} @{lastName}"`

### Validation Rules

**Screen tests must define all args they use:**
- Every `@{varName}` placeholder used in steps must have a corresponding key in `args`
- Validation will error if a placeholder is used but not defined in `args`

```json
// ✅ GOOD - all placeholders defined
{
  "args": { "userName": "test", "userEmail": "test@example.com" },
  "steps": [
    { "action": "input", "id": "name", "value": "@{userName}" },
    { "action": "input", "id": "email", "value": "@{userEmail}" }
  ]
}

// ❌ BAD - @{userEmail} used but not defined
{
  "args": { "userName": "test" },
  "steps": [
    { "action": "input", "id": "name", "value": "@{userName}" },
    { "action": "input", "id": "email", "value": "@{userEmail}" }
  ]
}
```

### Args Value Types

Args values must be primitive types:
- `string`: `"email": "test@example.com"`
- `number`: `"count": 5`
- `boolean`: `"enabled": true`

```json
{
  "args": {
    "userName": "TestUser",
    "itemCount": 3,
    "isAdmin": false
  }
}
```

### When to Use Args

Use args when:
- The same test case needs to run with different data
- Flow tests need to customize screen test behavior
- You want to reuse test logic with varying inputs

```json
{
  "name": "transfer_with_amount",
  "description": "Transfer money with specified amount",
  "args": {
    "amount": "1000",
    "recipientName": "John Doe"
  },
  "steps": [
    { "action": "input", "id": "amount_input", "value": "@{amount}" },
    { "action": "input", "id": "recipient_input", "value": "@{recipientName}" },
    { "action": "tap", "id": "transfer_button" }
  ]
}
```

## External Description Files

For detailed test case documentation, you can reference external files instead of inline descriptions:

```json
{
  "cases": [
    {
      "name": "login_validation",
      "descriptionFile": "descriptions/login_validation.md",
      "steps": [...]
    }
  ]
}
```

### Benefits

- **Separation of concerns**: Keep test JSON clean and focused on test logic
- **Rich documentation**: Use Markdown for detailed explanations, screenshots, diagrams
- **Documentation generation**: `jsonui-test generate` includes the full content from external files
- **Easier maintenance**: Update descriptions without modifying test files

### File Structure

```
tests/
├── login.test.json
└── descriptions/
    ├── login_validation.md
    └── login_error_handling.md
```

### Validation

When `descriptionFile` is specified, the validator will warn if the file doesn't exist:

```
Warning: Description file not found: descriptions/missing_file.md
```

## Best Practices

1. **Test one behavior per case** - Keep test cases focused
2. **Use descriptive names** - `valid_login_success` not `test1`
3. **Include assertions early** - Verify initial state before actions
4. **Wait for async operations** - Use `waitFor` for dynamic content
5. **Handle animations** - Add small waits if needed
6. **Screenshot on important states** - Document visual states
7. **Use descriptionFile for complex tests** - Keep detailed documentation in separate files
8. **Always include `description` key** - Every test case MUST have a `description` key with a human-readable description (separate from `name`)

## Common Patterns

### Form Validation Test
```json
{
  "name": "empty_form_validation",
  "description": "Submit button enables when form is filled",
  "steps": [
    { "assert": "disabled", "id": "submit_button" },
    { "action": "input", "id": "email_input", "value": "test@example.com" },
    { "assert": "disabled", "id": "submit_button" },
    { "action": "input", "id": "password_input", "value": "password" },
    { "assert": "enabled", "id": "submit_button" }
  ]
}
```

### Error Display Test
```json
{
  "name": "invalid_email_error",
  "description": "Error message shows for invalid email",
  "steps": [
    { "action": "input", "id": "email_input", "value": "invalid-email" },
    { "action": "tap", "id": "submit_button" },
    { "action": "waitFor", "id": "error_label", "timeout": 3000 },
    { "assert": "visible", "id": "error_label" },
    { "assert": "text", "id": "error_label", "contains": "invalid email" }
  ]
}
```

### Navigation Test
```json
{
  "name": "navigate_to_settings",
  "description": "Tap settings button navigates to settings screen",
  "steps": [
    { "action": "tap", "id": "settings_button" },
    { "action": "waitFor", "id": "settings_title", "timeout": 5000 },
    { "assert": "visible", "id": "settings_title" }
  ]
}
```

### Tapping Specific Text Portion
When a Label contains multiple text segments (e.g., "Agree to terms"), you can tap on a specific portion:

```json
{
  "name": "tap_terms_link",
  "description": "Tap terms link navigates to terms page",
  "steps": [
    { "action": "tap", "id": "terms_label", "text": "terms" },
    { "action": "waitFor", "id": "terms_page", "timeout": 3000 },
    { "assert": "visible", "id": "terms_page" }
  ]
}
```

The `text` parameter calculates the position of the specified text within the element and taps at that location.

### Tapping Collection Items
Use `tapItem` to tap an item at a specific index in a CollectionView or List:

```json
{
  "name": "tap_first_item",
  "description": "Tap first item navigates to detail page",
  "steps": [
    { "action": "tapItem", "id": "product_list", "index": 0 },
    { "action": "waitFor", "id": "product_detail_page", "timeout": 3000 },
    { "assert": "visible", "id": "product_detail_page" }
  ]
}
```

The element ID is constructed as `{collectionId}_item_{index}` internally.

### Handling Native Alert Dialogs
When the app shows a native alert dialog (confirm, permission request, etc.), use `alertTap` to tap a button:

```json
{
  "name": "confirm_delete",
  "description": "Delete confirmation removes item",
  "steps": [
    { "action": "tap", "id": "delete_button" },
    { "action": "alertTap", "button": "Delete", "timeout": 3000 },
    { "assert": "notVisible", "id": "item_row" }
  ]
}
```

The `button` parameter specifies the button text to tap (e.g., "OK", "Cancel", "Delete").

### Selecting Tabs in TabView/TabBar
Use `selectTab` to select a tab by index:

```json
{
  "name": "navigate_to_profile_tab",
  "description": "Select profile tab shows profile screen",
  "steps": [
    { "action": "selectTab", "id": "mainTabView", "index": 2 },
    { "action": "waitFor", "id": "profile_header", "timeout": 3000 },
    { "assert": "visible", "id": "profile_header" }
  ]
}
```

**Platform-specific behavior:**

| Platform | How it works |
|----------|-------------|
| `ios-swiftui` | Tries `{id}_tab_{index}` pattern first, falls back to `tabBars.buttons` |
| `ios-uikit` | Uses `UITabBarController.tabBars.buttons` directly (`id` is optional) |
| `android` | Uses `testTag("{id}_tab_{index}")` on NavigationBarItem |
| `web` | Uses HTML `id="{id}_tab_{index}"` on tab buttons |

**UIKit example (id optional):**
```json
{
  "type": "screen",
  "platform": "ios-uikit",
  "cases": [{
    "name": "select_second_tab",
    "description": "Select second tab",
    "steps": [
      { "action": "selectTab", "index": 1 }
    ]
  }]
}
```

**SwiftUI/Android/Web example (id required):**
```json
{
  "type": "screen",
  "platform": "ios-swiftui",
  "cases": [{
    "name": "select_second_tab",
    "description": "Select second tab",
    "steps": [
      { "action": "selectTab", "id": "mainTabView", "index": 1 }
    ]
  }]
}
```

### Selecting Dropdown/Picker Options
Use `selectOption` to select from dropdown elements:

**Web**: Selects from standard `<select>` elements
**iOS**: Selects from SelectBox picker (opens picker sheet, selects value, confirms)
**Android**: Selects from SelectBox bottom sheet (opens sheet, taps option)

```json
{
  "name": "select_country",
  "description": "Select country from dropdown",
  "steps": [
    { "action": "selectOption", "id": "country_select", "index": 0 },
    { "assert": "text", "id": "country_select", "equals": "Japan" }
  ]
}
```

You can select by:
- `index`: The 0-based index of the option (cross-platform compatible)
- `label`: The visible text of the option (cross-platform compatible)
- `value`: The option's value (cross-platform compatible)

```json
{ "action": "selectOption", "id": "category", "label": "Electronics" }
{ "action": "selectOption", "id": "priority", "index": 0 }
```

**Platform Notes**:

| Parameter | Web | iOS | Android |
|-----------|-----|-----|---------|
| `index` | Supported | Supported | Supported |
| `label` | Supported | Supported | Supported |
| `value` | Supported | Supported | Supported |

**iOS**:
- All parameters (`index`, `label`, `value`) are supported
- For DateSelectBox, use `value` with ISO format (e.g., "2024-01-15", "14:30", "2024-01-15T14:30")

**Android**:
- Supports all parameters
- Auto-closes after selection (no Done button needed)

## Validation (MANDATORY)

After creating or modifying any test JSON file, you **MUST** validate it using the `jsonui-test` CLI tool.

### Step 1: Check if Tool is Installed

```bash
which jsonui-test
```

### Step 2: Install if Not Found

If the command is not found, install it:

```bash
curl -fsSL https://raw.githubusercontent.com/anthropics/jsonui-test-runner/main/test_tools/installer/bootstrap.sh | bash
```

### Step 3: Validate the Test File

```bash
jsonui-test validate path/to/your_test.test.json
```

### Expected Output

**Success:**
```
path/to/your_test.test.json is valid
```

**With Warnings:**
```
path/to/your_test.test.json has warnings:

  Warning: Case 'test_case_1' has no assertions (step 3)

path/to/your_test.test.json is valid (with warnings)
```

**With Errors:**
```
path/to/your_test.test.json has errors:

  Error: Missing 'id' in step 2 of case 'test_case_1' (action: tap)
  Error: Unknown action 'click' in step 3 of case 'test_case_1'

Found 2 error(s) and 0 warning(s)
```

### Fix and Re-validate

If validation fails:
1. Fix the reported errors
2. Run validation again
3. Repeat until all errors are resolved
4. Warnings are acceptable but should be reviewed

### Validation Workflow Summary

```
1. Create test file -> 2. Check jsonui-test installed -> 3. Install if needed -> 4. Validate -> 5. Fix errors -> 6. Done
```

**IMPORTANT**: Never consider a test file complete until it passes validation.
