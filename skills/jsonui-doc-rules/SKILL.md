---
name: jsonui-doc-rules
description: Manages custom validation rules for jsonui-doc. Initializes .jsonui-doc-rules.json config files and shows effective rules for spec/component validation.
---

You are an expert in managing custom validation rules for the `jsonui-doc` CLI tool.

## Your Role

Help users set up and manage `.jsonui-doc-rules.json` configuration files that customize spec/component validation rules per project. These custom rules are **additive** — they extend base rules without replacing them.

You do NOT directly validate spec files — use `jsonui-doc validate spec` / `jsonui-doc validate component` for that.

## Commands Overview

| Command | Alias | Description |
|---------|-------|-------------|
| `rules init` | `r init` | Create a template `.jsonui-doc-rules.json` config file |
| `rules init --flutter` | `r init --flutter` | Create a Flutter-preset config file |
| `rules show` | `r show` | Show current effective rules (base + custom) |

---

## 1. rules init - Create Config Template

Creates a `.jsonui-doc-rules.json` file in the current directory (or specified output directory).

```bash
# Create empty template in current directory
jsonui-doc rules init
jsonui-doc r init

# Create Flutter-preset template
jsonui-doc rules init --flutter
jsonui-doc r init --flutter

# Specify output directory
jsonui-doc rules init -o /path/to/project
jsonui-doc rules init --flutter -o /path/to/project
```

### Options

| Option | Description |
|--------|-------------|
| `--flutter` | Pre-populate with Flutter-specific rules (Scaffold, AppBar, initState, etc.) |
| `-o, --output` | Output directory (default: current directory) |

### Error: File already exists

If `.jsonui-doc-rules.json` already exists, the command exits with an error. To regenerate, delete the existing file first.

---

## 2. rules show - Display Effective Rules

Displays the combined base + custom rules. Custom additions are marked with `(custom)`.

```bash
# Show rules for current directory
jsonui-doc rules show
jsonui-doc r show

# Search from a specific directory
jsonui-doc rules show -d /path/to/project
```

### Options

| Option | Description |
|--------|-------------|
| `-d, --directory` | Directory to search for config file (default: current directory) |

### Output Example

```
Config file: /path/to/project/.jsonui-doc-rules.json

Effective Rules:
==================================================

Screen Component Types:
  - Button
  - Image
  - Scaffold (custom)
  - Text
  ...

File Types:
  - BottomSheet (custom)
  - Model
  - Provider (custom)
  - Screen (custom)
  - Service
  ...

Event Handler Naming:
  Base pattern: ^on[A-Z][a-zA-Z0-9]*$
  Allowed names: dispose, initState
  ...
```

---

## Config File Format: `.jsonui-doc-rules.json`

```json
{
  "description": "Custom validation rules for jsonui-doc. All rules are additive to base rules.",
  "version": "1.0",
  "rules": {
    "componentTypes": {
      "screen": ["Scaffold", "AppBar"],
      "component": ["Scaffold", "ListView"]
    },
    "componentCategories": [],
    "fileTypes": ["Screen", "State", "Provider", "Widget"],
    "eventHandlers": {
      "allowedNames": ["initState", "dispose", "didChangeDependencies"],
      "additionalPatterns": []
    },
    "variableNaming": {
      "additionalPatterns": ["^_?[a-z][a-zA-Z0-9]*$"]
    },
    "propNaming": {
      "additionalPatterns": []
    },
    "slotNaming": {
      "additionalPatterns": []
    },
    "internalStateNaming": {
      "additionalPatterns": []
    },
    "exposedEventNaming": {
      "allowedNames": [],
      "additionalPatterns": []
    }
  }
}
```

### Key Concepts

- **All rules are additive** — Custom rules extend base rules, never replace them
- **Auto-discovery** — Config file is found by walking parent directories from the spec file location (like `.eslintrc`)
- **`allowedNames`** — Exact-match whitelist that bypasses the base pattern (e.g., `initState` bypasses `^on[A-Z]...` check)
- **`additionalPatterns`** — Regex patterns checked in addition to the base pattern
- **Invalid regex patterns** are skipped with a warning on load

### Rules Reference

| Rule | Description | Base Rule |
|------|-------------|-----------|
| `componentTypes.screen` | Additional valid component types for screen specs | Button, Image, Label, Input, etc. |
| `componentTypes.component` | Additional valid component types for component specs | Button, Image, Label, Input, etc. |
| `componentCategories` | Additional categories for component specs | form, navigation, display, layout, etc. |
| `fileTypes` | Additional file types for relatedFiles | ViewModel, Service, Model, etc. |
| `eventHandlers.allowedNames` | Exact names that bypass `on+PascalCase` rule | — |
| `eventHandlers.additionalPatterns` | Extra regex patterns for event handler names | `^on[A-Z][a-zA-Z0-9]*$` |
| `variableNaming.additionalPatterns` | Extra regex patterns for variable names | `^[a-z][a-zA-Z0-9]*$` |
| `propNaming.additionalPatterns` | Extra regex patterns for prop names | `^[a-z][a-zA-Z0-9]*$` |
| `slotNaming.additionalPatterns` | Extra regex patterns for slot names | `^[a-z][a-zA-Z0-9]*$` |
| `internalStateNaming.additionalPatterns` | Extra regex patterns for internal state names | `^[a-z][a-zA-Z0-9]*$` |
| `exposedEventNaming.allowedNames` | Exact names that bypass naming rule | — |
| `exposedEventNaming.additionalPatterns` | Extra regex patterns for exposed event names | `^on[A-Z][a-zA-Z0-9]*$` |

---

## Common Workflows

### Set Up Flutter Project

```bash
# 1. Navigate to project root
cd /path/to/flutter_project

# 2. Generate Flutter-preset config
jsonui-doc rules init --flutter

# 3. Review/customize the generated config
cat .jsonui-doc-rules.json

# 4. Verify effective rules
jsonui-doc rules show

# 5. Validate spec files (custom rules auto-detected)
jsonui-doc validate spec docs/screens/json/login.spec.json
```

### Set Up Custom Project

```bash
# 1. Generate empty template
jsonui-doc rules init

# 2. Edit config to add project-specific rules
# (edit .jsonui-doc-rules.json)

# 3. Verify
jsonui-doc rules show
```

### Validate with Custom Rules

Custom rules are automatically discovered when running `validate spec` or `validate component`. If a `.jsonui-doc-rules.json` is found, its path is displayed:

```
Custom rules: /path/to/project/.jsonui-doc-rules.json
```

No special flags are needed — just place the config file at or above the spec files.

---

## Important Rules

- **Never manually edit validator.py** to add project-specific rules — use `.jsonui-doc-rules.json` instead
- **Config file placement** — Place at project root; it's discovered by walking parent directories from the spec file
- **Additive only** — You cannot remove or restrict base rules via config
- **Valid regex required** — Invalid regex patterns in `additionalPatterns` are silently skipped with a warning
- **One config per project tree** — The first `.jsonui-doc-rules.json` found walking upward is used
