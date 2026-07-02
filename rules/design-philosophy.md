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

## VM isolation across embedded screens (`Embed`)

Unlike `include` (static inline expansion, parent owns the VM) and `TabView` (tabs share the parent VM), an `Embed` view type creates a **VM boundary**: the embedded screen owns its own ViewModel, fully independent from the parent. This is the design contract — not a side-effect of any one platform's implementation:

- **Parent → child data**: only what is explicitly listed in `params` crosses the boundary. No implicit `data` sharing.
- **Child → parent events**: only what is explicitly declared in `events` (mapped to a parent VM method or eventHandler) crosses back. Embedded VMs emit via the lib `emit(name, payload)` helper.
- **Same screen embedded twice**: each instance gets its own VM, keyed by the Layout JSON `Embed.id`. On Android, `EmbedContainer` `remember(id)` a per-slot `ViewModelStoreOwner` to guarantee this — do not bypass.
- **Navigation**: v1 uses `navigationMode: "delegate"` — the embedded screen's `navigate()` drives the parent's NavController/Router. `pop` / `dismiss` / `navigateBack` are bounded at the embed and do not close it.

The embedded screen requires **no spec changes** to be embeddable. VMs that implement `applyInitParams(_:)` consume the params; others ignore them. This is the inverse of `include`'s ID-prefix scoping trick — instead of injecting parent identity into the child, `Embed` walls the child off and forces explicit channels.

See `specification-rules.md` (5) and `jsonui-cli/docs/plans/2026-05-11-embed-feature.md`.

## Data Model Layering — DTO vs Domain

Network I/O types (DTOs) and business / display logic live in **physically separate files** that have completely different ownership semantics:

- **DTO** (`Model/Generated/*Dto.swift` and Android/Web counterparts) is **wire-shape only** — generated from the swagger schema on every `jui build`, carries the `@generated` banner, contains only the fields the API actually sends/receives. Codegen owns this file; user never edits it.
- **Domain** (`Model/{Name}.swift` etc.) holds the type the rest of the codebase consumes. It wraps the DTO as `let dto: {Name}Dto` (struct/class member, not inheritance) and provides whatever proxies / computed properties / stored state the app needs. User owns this file from the first emit onwards — `jui build` skips it when it already exists.

Why split the two:

1. **Schema changes manifest as compile errors at the boundary**. When the swagger renames `displayName` to `name`, the DTO regenerates, every `dto.displayName` in the Domain wrapper fails to compile, the user fixes those lines and moves on. The break is localized to the Domain proxies — VM / Repository / View code that depends only on Domain getters is untouched.

2. **No drift between wire format and code**. The DTO is the literal `CodingKeys` / `@Json(name=...)` / wire field set. Reading the DTO file tells you exactly what bytes will be sent / accepted. Reading the Domain tells you what the rest of the app sees — including any String-to-Date / String-to-UUID / enum coercion the user wrote as Domain proxy.

3. **User extension freedom**. Domain is a plain struct/class/interface owned by the user — they can add `var localIsDirty: Bool` for UI state, override `Equatable`, etc. The wire shape isn't constrained by their additions.

User code (VM, Repository, View) **only ever sees Domain types**. The DTO is implementation detail of the network/decode layer, exposed via `domain.dto` only when explicitly needed (rare). Repository methods decode bytes into DTO, then wrap into Domain in a single call:

```swift
let dto = try JSONDecoder().decode(UserDto.self, from: data)
return User(dto: dto)
```

This pattern is mirrored on Android (Moshi/kotlinx) and Web (factory function `userFromDto`). See `invariants.md` (rules 5-8) for the editing contract and `file-locations.md` for the per-platform path layout.

## When in doubt

Refer to the spec. If the spec is silent, ask the user — do not invent behavior. See `specification-rules.md`.
