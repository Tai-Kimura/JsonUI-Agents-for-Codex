# JsonUI Design Philosophy

## Core Principle

**The specification is the single source of truth for intent and contract. The Layout JSON is the single source of truth for UI structure.**

Each serves a different role:

- **Spec (`docs/screens/json/*.spec.json`)** — describes the screen's purpose, state, data flow, and the public ViewModel contract. Drives code generation for Layout JSON skeletons, Protocol/Interface, and VM/Repository/UseCase stubs.
- **Layout JSON (`docs/screens/layouts/*.json`)** — the shared, cross-platform UI definition. Distributed to each platform by `jui build`. Once generated, it lives on its own and is edited directly as the UI source of truth.

Generated artifacts — Protocol / Interface / ViewModelBase / method & var signatures — are **never hand-edited**. To change them, edit the spec and rebuild. See `invariants.md`.

```
Specification (intent + contract)
    │
    ├── jui g project → Layout JSON (SSoT for UI, hand-edited from here)
    │       │
    │       └── jui build → each platform's Layouts/ (copies, not sources)
    │
    ├── jui g project → ViewModel / Repository / UseCase stubs
    │       │
    │       └── method/Repo bodies are hand-written; signatures stay in sync with spec
    │
    ├── jui build → Protocol / Interface / ViewModelBase (regenerated, do not edit)
    │
    ├── jsonui-doc → HTML / Mermaid diagrams
    │
    └── Tests
```

## What is hand-written vs generated

| Hand-written | Generated (`@generated`) |
|---|---|
| Spec (`*.spec.json`) | Protocol / Interface / ViewModelBase |
| Layout JSON | VM method / var signatures |
| Styles (`Styles/*.json`) | Repository / UseCase signatures |
| `strings.json` | Inheritance list completion, Kotlin `override` insertion |
| VM method bodies | SVG → PDF / VectorDrawable / SVG |
| Repository / UseCase method bodies | HTML docs |
| Navigation code (platform-native) | |
| `// @jui:protocol` marker (rare) | |
| Tests | |

## Platform-Specific vs Runtime Attributes

Layout JSON supports two attribute override mechanisms — do not confuse them:

| Key | Resolution | Purpose |
|-----|-----------|---------|
| `platform` (dict) | `jui build` time (static) | iOS/Android/Web differences (e.g. height, maxWidth) |
| `responsive` | App runtime (dynamic) | Screen size class switching (compact / regular / landscape) |

Both can coexist on the same node. `platform` is stripped at build time; `responsive` is left for the framework to resolve at runtime.

There is also a `platforms` (plural) key at the root of a Layout JSON file that whitelists which platforms to distribute to. Different mechanism, different purpose — see `jui_tools_README.md`.

## SSoT rules

- **Never** edit Layout JSON inside a platform directory (`my-app-ios/my-app/Layouts/`, `my-app-android/app/src/main/assets/Layouts/`, `my-app-web/src/Layouts/`). `jui build` overwrites them.
- **Always** edit in `docs/screens/layouts/` and run `jui build`.
- **Never** edit `@generated` files. Edit the spec and let `jui build` regenerate.
- **Never** add features not described in the spec. If a feature is needed, update the spec first.

## When in doubt

Refer to the spec. If the spec is silent, ask the user — do not invent behavior. See `specification-rules.md`.
