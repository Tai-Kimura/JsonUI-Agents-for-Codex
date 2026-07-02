# JsonUI File Placement Rules

## Project Configuration

Every JsonUI project has a `jui.config.json` at the project root, created by `jui init`:

```json
{
  "project_name": "my-app",
  "spec_directory": "docs/screens/json",
  "layouts_directory": "docs/screens/layouts",
  "strings_file": "docs/screens/layouts/Resources/strings.json",
  "platforms": {
    "ios": {
      "root": "my-app-ios",
      "layoutsDir": "my-app/Layouts"
    },
    "android": {
      "root": "my-app-android",
      "layoutsDir": "app/src/main/assets/Layouts"
    },
    "web": {
      "root": "my-app-web",
      "layoutsDir": "src/Layouts"
    }
  }
}
```

## Shared Layouts Directory (Single Source of Truth)

Layout JSON files live in a **single shared directory** (`layouts_directory` in config, default: `docs/screens/layouts/`).

**This is the ONLY place to edit Layout JSON.** Each platform's `Layouts/` directory is a copy created by `jui build`.

```
project-root/
├── jui.config.json
├── docs/screens/
│   ├── json/                        # Specifications (*.spec.json)
│   │   ├── login.spec.json
│   │   ├── mypage.spec.json
│   │   ├── chat.spec.json           # screen_parent_spec
│   │   └── chat/                    # Sub-specs
│   │       ├── chat-core.spec.json
│   │       └── ...
│   ├── layouts/                     # Layout JSON (SINGLE SOURCE OF TRUTH)
│   │   ├── login.json
│   │   ├── mypage.json
│   │   ├── chat.json
│   │   ├── chat/
│   │   │   ├── message_cell.json
│   │   │   └── ...
│   │   ├── common/                  # Shared across screens
│   │   │   ├── header.json
│   │   │   └── footer.json
│   │   └── Resources/               # Under layouts/ — strings.json, colors.json
│   │       ├── strings.json
│   │       └── colors.json
│   └── styles/                      # Sibling to layouts/ — NOT under it
│       └── card_style.json
├── my-app-ios/                      # ← jui build copies here
├── my-app-android/                  # ← jui build copies here
└── my-app-web/                      # ← jui build copies here
```

### Cell Placement

**Cells belong under their parent screen directory** — Cells are typically NOT reused across screens, so place them under the screen that uses them (e.g., `home/item_cell.json`).

**Shared components go in `common/`** — Headers, footers, and other truly reusable partials go in `common/`.

## API Specifications + Data Model

### Source

Swagger / OpenAPI files live in `api_directory` (default: `docs/api/*.json`).

For multi-app projects sharing one swagger, set `api_directory` to a relative path above project_root:

```jsonc
{
  "api_directory": "../docs/api",          // shared swagger outside project_root
  "platforms": { /* ... */ }
}
```

### Generated outputs (per platform)

Each enabled platform writes per-schema files into its source tree on `jui build`:

| Platform | DTO (@generated, regenerated every build) | Domain (user-owned after first emit) |
|---|---|---|
| iOS | `<sources>/Model/Generated/{Name}Dto.swift` | `<sources>/Model/{Name}.swift` |
| Android | `<src_dir>/kotlin/<pkg_path>/model/generated/{Name}Dto.kt` | `<src_dir>/kotlin/<pkg_path>/model/{Name}.kt` |
| Web | `<src>/models/generated/{Name}Dto.ts` | `<src>/models/{Name}.ts` |

Standalone enums (`type: string \| integer` + `enum: [...]`) emit alongside DTOs:

| Platform | Enum file |
|---|---|
| iOS | `<sources>/Model/Generated/{EnumName}.swift` |
| Android | `<src_dir>/kotlin/<pkg_path>/model/generated/{EnumName}.kt` |
| Web | `<src>/models/generated/{EnumName}.ts` |

Path resolution per platform:

- **iOS**: `<sources>` = `<platforms.ios.root>/<sjui.config.json#source_directory>` (or the platform_root itself when sjui.config.json is missing)
- **Android**: `<src_dir>` = `<platforms.android.root>/<kjui.config.json#source_directory>` (default `app/src/main`); `<pkg_path>` is dot-to-slash conversion of `kjui.config.json#package_name` (default `com.example.app`). The `kotlin/` sub-source-set is appended automatically; `java/` is used as fallback when `kotlin/` doesn't exist.
- **Web**: `<src>` = `<platforms.web.root>/<rjui.config.json#source_directory>` or `<platforms.web.root>/src` by default

### Config — `api.platforms.*`

```jsonc
{
  "api": {
    "platforms": {
      "ios": {
        "model_dir": "Model",           // under <sources>
        "dto_subdir": "Generated"        // under model_dir
      },
      "android": {
        "model_package": "model",        // bare → prepended with kjui's package_name
        // (or "com.example.myapp.model" — full FQN if dot is present)
        "dto_subpackage": "generated",   // under model_package
        "serializer": "moshi"            // "moshi" | "kotlinx" | "none"
      },
      "web": {
        "model_dir": "models",
        "dto_subdir": "generated",
        "case_convention": "snake_case"  // "snake_case" | "camelCase"
      }
    }
  }
}
```

### Filter — `api.schemas.*`

For multi-app shared swaggers, scope each app's codegen to the endpoints it actually consumes:

```jsonc
{
  "api": {
    "schemas": {
      "include_paths": ["/api/auth/*", "/api/user/*"],     // glob; * matches /
      "exclude_paths": ["/api/admin/*"],
      "include_schemas": ["ErrorResponse"],                 // shared types not reached by include_paths
      "exclude_schemas": ["ItemLegacy*"],                   // glob; subtract after include
      "skip_domain": ["LoginRequest"]                       // glob; DTO emit but no Domain scaffold
    }
  }
}
```

See `docs/plans/2026-05-27-swagger-codegen-path-filter.md` v2 for filter semantics + transitive `$ref` resolution rules.

### ⛔ NEVER edit DTO files (or Domain DTO content)

DTOs carry the `@generated` banner and are rewritten on every `jui build`. Hand edits are lost.

To change a DTO field shape: edit the swagger schema. To add a computed / proxy property: edit the **Domain** file (it's user-owned after first emit).

## ⛔ NEVER Edit Platform Copies Directly

Each platform's `Layouts/` directory is overwritten by `jui build`. Any direct edits there will be lost.

```bash
# ❌ WRONG - Editing platform copy
vim my-app-ios/my-app/Layouts/login.json

# ✅ CORRECT - Edit shared source, then distribute
vim docs/screens/layouts/login.json
jui build
```

## ⛔ NEVER Move CLI-Generated Files

**Files generated by CLI commands MUST stay in their original location.**

- **NEVER** move files after `g view`, `g collection`, `g partial` commands
- If you want a file in a specific subdirectory, **specify it in the CLI argument**:

```bash
# ✅ CORRECT - CLI automatically places cell under screen directory
./sjui_tools/bin/sjui g collection home/ItemCell
# → Generates: Layouts/home/item_cell.json
```

## Style Files

Place under the `styles_directory` config value (default: `docs/screens/styles/`,
**sibling to `layouts/`, NOT under it**). `jui build` reads from
`config_mgr.styles_directory` and distributes each file to every platform's
`Styles/` folder (placed alongside the platform's `Layouts/` at the same level).

```
{styles_directory}/
├── card_style.json
├── primary_button_style.json
└── section_header_style.json
```

> **Common mistake:** Putting style files under `{layouts_directory}/Styles/`
> is a legacy placement that current build flow does not read from. Place them
> at `{styles_directory}/` (sibling to layouts) instead.

## Resource Files

Place in `Resources/` directory **within `layouts_directory`**:
- `strings.json` — String resources
- `colors.json` — Color definitions

```
{layouts_directory}/Resources/
├── strings.json
└── colors.json
```

> Resources are the one concession: they live *under* layouts (unlike styles).
> `_distribute_resources` in `jui build` reads from
> `config_mgr.layouts_directory / "Resources"` and copies to each platform's
> `Layouts/Resources/`.

## Generated Files (Do Not Edit)

Files carrying the `@generated` marker are regenerated by `jui build` / `jui generate project`. Hand-edits are detected by `jui lint-generated` and cause build failures.

**Layout generation outputs** (regenerated by `jui generate project`):
- `*GeneratedView.swift` / `*GeneratedView.kt`
- `*Data.swift` / `*Data.kt`
- `*Binding.swift` / `*Binding.kt`

**ViewModel Protocol sync** (regenerated by `jui build`):
- iOS: `*ViewModelProtocol.swift`, Repository protocols, UseCase protocols
- Android: `*ViewModelProtocol.kt`, Repository interfaces, UseCase interfaces
- Web: `*ViewModelBase.ts`, Repository bases, UseCase bases

**In-place patches** (applied by `jui build` to ViewModel Impl files):
- Inheritance list additions (adds `*ViewModelProtocol` if missing)
- Kotlin `override` modifier insertion on methods/vars declared in the Protocol

To change any generated signature or protocol member, edit the spec's `dataFlow.viewModel.methods` / `vars` (or the Repository/UseCase `methods[]`) — do not edit the Protocol or Impl inheritance by hand. Exceptional additions (async/throws/generic signatures) use the `// @jui:protocol` marker in Impl. See `jui_tools_README.md`.

## Tools Directories (Do Not Edit)

The following are framework tools and must not be edited:
- `sjui_tools/`
- `kjui_tools/`
- `rjui_tools/`
- `jui_tools/` (jui CLI)
