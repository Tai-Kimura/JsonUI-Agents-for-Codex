---
name: jsonui-dataflow
description: Authoring guide for the spec dataFlow section (viewModel, repositories, useCases, apiEndpoints) and its Mermaid linkage. Invoked by define / debug / implement when working with the architecture layer of a screen.
tools: Read
---

# jsonui-dataflow

Authoring guide for the `dataFlow` section of a screen spec. Use this when writing or reviewing any of:

- `dataFlow.viewModel` — public ViewModel contract (methods + vars)
- `dataFlow.repositories[]` — data access layer
- `dataFlow.useCases[]` — business logic layer (optional, for complex screens)
- `dataFlow.apiEndpoints[]` — API endpoints the screen uses
- `dataFlow.diagram` — (optional) hand-written Mermaid diagram. If omitted, `jsonui-doc generate spec` auto-generates one from the above.

---

## 🔴 `dataFlow` is REQUIRED for any interactive screen

Agents have been caught shipping specs with empty or missing `dataFlow` on screens that clearly need a ViewModel, Repository, or UseCase. That is a spec bug — the generated Protocol ends up empty and humans hand-patch the VM.

**You MUST fill the following when applicable:**

| Sub-section | When required | Trigger phrases in the requirements |
|---|---|---|
| `viewModel.methods` | Any user action that does work (tap, submit, fetch, navigate, validate, toggle VM-owned state). Every `stateManagement.eventHandlers` entry that reaches the VM needs a matching `viewModel.methods` entry. | "on tap", "when the user submits", "load", "save", "validate", "navigate to" |
| `viewModel.vars` | Any observable state (loading, fetched list, error message, form value VM owns, derived display string). | "loading indicator", "show results", "error message", "display the …" |
| `repositories[]` | Any access outside the VM — API, disk, keychain, cache, shared state, platform SDK (StoreKit, Firebase, CoreLocation). | "fetch from API", "save locally", "sign in with Apple", "get location" |
| `useCases[]` | Orchestration across multiple repos, multi-step validation, or business logic that belongs neither in VM nor Repo. | "check credentials then fetch user", "validate then submit", "login with fallback" |
| `apiEndpoints[]` | Every endpoint declared on `repositories[*].methods[*].endpoint` must have a matching `apiEndpoints[]` entry. | auto-derived from repository methods |

**Pure-static display is the one exception.** Even then, write `viewModel: { methods: [], vars: [] }` explicitly — don't omit `dataFlow`.

### `endpoint` is checked against the API document — spell it the canonical way

`repositories[*].methods[*].endpoint` is `"<VERB> <path>"`, and `doc_validate_spec`
compares it with the OpenAPI documents under `api_directory`. Copy the path from
the API document rather than typing what the route "should" be: the check warns on
a path that appears nowhere, on a verb the document does not declare for that path,
and on **parameter names that differ** (`/api/venues/{venueId}` against a document
that says `{venue_id}`). Warnings do not fail validation, but each one is a spec
that has drifted from the API it claims to call — and the same declaration is what
`test_generate_branch_tests` binds mock scenarios through, so a drifted spelling
becomes a hard error the moment anyone generates branch tests.

A non-HTTP verb (`WS`, a realtime-database read, a GraphQL operation) is legal here
and simply not checked — the OpenAPI documents do not describe those transports.

### `params: "@canonical"` — reference the API document instead of copying it

Once `endpoint` names an operation, the operation already says what the method
takes. Write the reference rather than the copy:

```jsonc
{ "name": "getBookmarks",
  "endpoint": "GET /api/user/bookmarks",
  "params": "@canonical",
  "returnType": "BookmarkListResponse" }
```

`doc_validate_spec` and `jui build` both expand it, from one implementation, to
the operation's `parameters` plus its JSON request-body properties. A parameter
the document marks `required` is emitted without `?`.

**Mix the mark with hand-written entries** when the method takes something the
API never declares — a progress callback, a cancellation token. The mark expands
where it sits, and a hand-written name wins over a canonical one of the same
name (including one that differs only in case):

```jsonc
"params": ["@canonical", { "name": "onProgress", "type": "((Int) -> Void)?" }]
```

**Rules that matter when you use it:**

- **Omitting `params` is not the mark.** An absent `params` means "no
  parameters" and always has. Only the written mark asks for resolution.
- **An unresolvable mark is an ERROR, not an empty list.** If the endpoint
  names no operation, or names a non-HTTP transport, validation fails rather
  than generating a method with no arguments.
- **Naming follows `spec.canonical_param_case` in `jui.config.json`**
  (`asIs` — the document's own spelling — by default, or `camelCase` /
  `snake_case`). Set it before converting a project: without it, a canon
  written in `snake_case` produces `venue_id` where the spec said `venueId`,
  and those names are argument labels in generated code on three platforms.
- **パス変数も引数として展開されます。** `in` で絞っていないので
  `/api/venues/{venue_id}` の `venue_id` はシグネチャに入ります。**つまり正本側の
  パス変数の改名は、参照している全 spec の生成シグネチャを動かします** —
  route の照合は綴り差を正規化して吸収するので、**同じ改名が「解決には無影響・
  展開には影響」**という分かれ方をします。
- **`requestBody.required` が付いていないと、schema 側の `required: [...]` は
  生成に効きません**(両者の AND)。body ごと省略できる以上、中身を無条件必須には
  できないため正しい挙動ですが、理由が症状から遠いので**警告が出ます**。
- **`returnType` takes `@canonical.wire`, never `@canonical`.** A spec's return
  type is the domain type and the document's is the wire type, and they
  legitimately differ (`[ItemSummary]` against `ItemSearchResponse`). Only
  `@canonical.wire` — "the wire type is what I mean" — lifts it, and it fails
  when the operation describes its response body inline, because there is then
  no name to lift.

**When NOT to use it.** Write the value directly when the method deliberately
says something the document does not: an object argument standing in for a
group of flat fields, a client-side callback, a domain return type. The mark is
for the declarations that were copying the document, which is most of them but
not all — do not force the ones that were saying something.

### `canonicalDivergence` — 直書きが「どう違うか」を宣言する

直書きの `params` は「正本と意図的に違う」の表明そのものなので、**差を一律に警告すると
意図の表明手段が消えます**(実コーパスの直書き 115 宣言が一斉に赤になり、常時赤の検査は
読まれなくなる)。要るのは「差があるか」ではなく **「宣言された差と実際の差が一致しているか」**。

```jsonc
{ "name": "getVenue",
  "endpoint": "GET /api/venues/{venue_id}",
  "params": [{ "name": "venueUuid", "type": "String" }],
  "canonicalDivergence": {
    "renamed": { "venue_id": "venueUuid" },
    "reason": "正本は略記。spec・実装とも読みやすさのため揃えている(spec と実装は一致)"
  } }
```

- **宣言が検査のスイッチです。**書かなければ従来どおり何も起きません — プロジェクトは
  1 メソッドずつ採用できます
- **`reason` 必須。**説明できない差は、たいてい誰も直していない差です
- **stale 宣言はエラー**(これが本命)。正本が `venueUuid` に改名されたら差が消えるので、
  それを説明する注記は**「もう対処済み」が対象より長生きする**形になります
- **差し引きであって免除ではない。**`renamed` で説明しきれない差が残っていればエラー。
  事故の混入は「もともと違うと分かっているメソッド」に一番よく隠れます
- **`@canonical` を使うメソッドには書けません**(参照は定義上ずれない)

`contractViolations`(mock)と同型です。

### 語彙 — `renamed` 以外の 3 つ

`renamed` は「同じ引数が別名になっている」しか言えません。実測では手書き宣言 37 件のうち
**その形は 7 件だけ**で、残り 30 件(最長のものは正本 20〜33 フィールドを 1 オブジェクトに
まとめたもの)は**宣言できませんでした**。

| 句 | 何を言うか |
|---|---|
| `omitted` | **呼び手が決めない引数**。プラットフォーム文字列を Repository が定数で送る、など。検査を通すために引数にするのは検査より悪い |
| `wrapped` | **1 引数が複数をまとめている**。30 引数のメソッドは DTO より悪い契約で、しかも DTO は同じ正本から生成されるので**別経路で追随している** |
| `added` | **正本が宣言していない引数**。multipart は JSON 展開が空になるので全部これ |

```jsonc
"canonicalDivergence": {
  "wrapped": { "request": ["item_uuid", "note"] },
  "omitted": ["platform"],
  "added":   ["onProgress"],
  "reason":  "…"
}
```

**どの句も `renamed` と同じく正本に照合されます** — 正本がもう宣言していないものを名指し
していればエラーなので、**注記が対象より長生きしません**。**差し引きであって免除ではない**
のも同じで、どの句でも説明されない差は報告されます。

### split tree では `extends` でスタブが正本 config を指す

spec と build config が別サブツリーにある構成では、**どの config が答えるかが実行ディレクトリ
依存**でした(`jui build` はアプリから、`jsonui-doc` はリポ直下から走る)。

**spec の系譜が face を決める**ようになり、系譜上のスタブ config が `extends` で所有者を
指します:

```jsonc
// docs/<face>/jui.config.json
{ "extends": "../../<face>/jui.config.json",
  "layouts_directory": "screens/layouts" }
```

**これが無いと、系譜上で最も近い config(たいていリポ直下)が答えます。**

**Declare `params` on a method whose arguments a contract will pin.** `arg.<name>`
in `branchContracts` binds to `methods[].params`, and nowhere else:
`stateManagement.eventHandlers` is View-layer by design and carries no signature,
so a handler-only method cannot take contracted arguments.

### 共有コンポーネントが呼ぶものは、使っている spec すべてに宣言する

共有ヘッダやパーシャルから呼ぶ Repository / UseCase メソッドは、**そのコンポーネントを
使っている画面 spec すべてに宣言**します。1 箇所にまとめたり「app レベルだから spec の外」
にしたりしません。**理由は生成ではなく追跡可能性で、spec を読んで「どこから呼ばれているか」
が分からない状態を作らないため**です。

コンポーネント spec には `dataFlow` がないので(`props` / `slots` / `structure` /
`stateManagement` / `usage` のみ)、**コンポーネント自身がメソッドを宣言する手段はありません**。
使う側が言うしかない、というのがこの規則の構造的な理由でもあります。

**同じメソッドが複数 spec に出ることは正常です。**異常なのは**宣言が食い違うこと**で、
実装は 1 つなのでどれか 1 つとしか一致し得ません。`jsonui-doc validate spec <dir>`
(ディレクトリ指定のバッチ実行)が突き合わせて ERROR にします —— **1 ファイルの検証では
原理的に見えない**ので、ディレクトリで回してください。`platforms` が違う宣言は
別物として扱われます(`UIImage` / `Bitmap` のような正当な差)。

**Do not guess method / var / repo names from the screen description alone.** They become part of the generated Protocol that every platform must implement, and renaming is a breaking change. If the user didn't volunteer the detail, ASK with the template in `rules/specification-rules.md` → "How to ask the user when they didn't volunteer this info".

---

## When to use which layer

| Screen complexity | Pattern |
|---|---|
| Simple (1 API call) | ViewModel → Repository → API |
| Complex (multiple APIs, validation, orchestration) | ViewModel → UseCase → Repository → API |
| View-local state only (pure UI toggle) | `stateManagement.eventHandlers` (NOT `dataFlow.viewModel.methods`) |

Do not use UseCase unless there's genuine orchestration. A 1-API screen should not go through a UseCase just for symmetry — it adds a layer that returns no value.

---

## `dataFlow.viewModel`

The public contract. Every method and var declared here becomes a Protocol/Interface/ViewModelBase member, auto-generated by `jui build`.

### Methods

```jsonc
"methods": [
  // minimal
  { "name": "onLogin" },

  // with params + return + async
  {
    "name": "fetchProducts",
    "params": [{ "name": "category", "type": "String" }],
    "returnType": "Array(Product)",
    "isAsync": true,
    "description": "Fetch items filtered by category"
  },

  // platform-limited
  {
    "name": "onCameraTap",
    "platforms": ["ios", "android"]
  }
]
```

| Field | Required | Default | Notes |
|---|---|---|---|
| `name` | ✅ | — | camelCase method name |
| `params` | | `[]` | structured list or legacy `"id: String, x: Int"` string |
| `returnType` | | (none) | passes through TypeMapper — e.g. `Array(Product)` → Swift `[Product]`, Kotlin `List<Product>`, TS `Product[]` |
| `isAsync` | | `false` | ViewModel methods are synchronous by default |
| `platforms` | | all platforms | `["ios"]`, `["ios", "android"]` — empty `[]` is valid but triggers WARNING |
| `description` | | — | |

### Vars

```jsonc
"vars": [
  { "name": "isLoading", "type": "Bool" },
  { "name": "items", "type": "Array(Product)" },
  { "name": "onDismiss", "type": "() -> Void", "optional": true },
  { "name": "staticLabel", "type": "String", "readOnly": true, "observable": false }
]
```

| Field | Required | Default | Notes |
|---|---|---|---|
| `name` | ✅ | — | camelCase |
| `type` | ✅ | — | TypeMapper applies; closure types `() -> Void` / `(T) -> Void` pass through |
| `optional` | | `false` | adds `?` (closures get parens added automatically) |
| `observable` | | `true` | iOS `@Published`, Android `StateFlow`, Web `<Name>Data` |
| `readOnly` | | `false` | getter only / `val` / `readonly` |
| `platforms` | | all platforms | same rules as methods |

### What generated signatures look like

Method example:

```
spec: { "name": "fetch", "params": [{"name":"id","type":"String"}], "returnType": "Bool", "isAsync": true }
  iOS:     func fetch(id: String) async throws -> Bool
  Android: suspend fun fetch(id: String): Boolean
  Web:     fetch(id: string): Promise<boolean>
```

Var example:

```
spec: { "name": "onDismiss", "type": "() -> Void", "optional": true }
  iOS Protocol:     var onDismiss: (() -> Void)? { get set }
  iOS Impl:         @Published var onDismiss: (() -> Void)? = nil
  Android Protocol: var onDismiss: (() -> Unit)?
  Web Base:         public onDismiss?: () => void;   (only when observable: false)
```

### `// @jui:protocol` marker (escape hatch)

For signatures that don't fit the spec schema — async throws, generics, `@MainActor`, `inout`, Swift labelled tuples — declare inline with a marker above the Impl method:

```swift
// @jui:protocol func fetchUser() async throws -> User
func fetchUser() async throws -> User { ... }
```

Multi-line signatures use consecutive marker lines:

```swift
// @jui:protocol @MainActor
// @jui:protocol @discardableResult
// @jui:protocol func update<Model>(
// @jui:protocol     _ id: String,
// @jui:protocol     transform: (inout Model) -> Void
// @jui:protocol ) async throws -> Model where Model: Identifiable
```

`jui build` extracts these into the Protocol. Kotlin's `override` is auto-stripped from Protocol. Use markers sparingly; prefer declaring in spec when possible.

---

## `dataFlow.repositories`

```jsonc
"repositories": [
  {
    "name": "ProductRepository",
    "description": "API access for item data",
    "methods": [
      {
        "name": "fetchProducts",
        "params": [{ "name": "category", "type": "String" }],
        "returnType": "Array(Product)",
        "isAsync": true,
        "endpoint": "GET /api/items"
      },
      {
        "name": "loginAndFetch",
        "params": [...],
        "returnType": "(AuthResponse, User)",
        "isAsync": true,
        "endpoints": ["POST /api/auth/login", "GET /api/user/me"]
      }
    ]
  }
]
```

| Method field | Purpose |
|---|---|
| `endpoint` | single API endpoint the method calls; format `"METHOD /path"` |
| `endpoints` | array of endpoints (if one method calls multiple); same format |
| `params` | list of `{name, type}`, or `"@canonical"` / `["@canonical", …]` to take them from the operation `endpoint` names |
| `returnType` | the domain type, or `"@canonical.wire"` for the schema the operation's success response names |

Both are optional, but declaring them lets the auto-Mermaid diagram draw explicit edges instead of fan-out guesses. See `get_dataflow_linkage_rules` (MCP, Phase 4 future) for rules, or `jui_tools_README.md`.

Endpoint path/method must match a corresponding entry in `dataFlow.apiEndpoints` exactly (case-insensitive method, literal path).

---

## `dataFlow.useCases`

```jsonc
"useCases": [
  {
    "name": "LoginUseCase",
    "description": "Coordinate the login flow",
    "repositories": ["AuthRepository", "UserRepository"],
    "methods": [
      {
        "name": "emailLogin",
        "params": [{ "name": "email", "type": "String" }, { "name": "password", "type": "String" }],
        "returnType": "AuthResponse",
        "isAsync": true,
        "calls": ["AuthRepository.emailLogin", "UserRepository.fetchCurrent"]
      }
    ]
  }
]
```

UC → Repo linkage — either or both:

- `useCase.repositories` (array of repo names) — declare at UC level. `useCase.dependencies` is accepted as an alias for backward compat.
- `useCase.methods[].calls` — `["Repo.method", ...]` per method. Finer granularity.

If you provide both, they merge. If neither is present, the UC appears in the diagram but has no edge to any Repo (explicitly — not fan-out).

---

## `dataFlow.apiEndpoints`

```jsonc
"apiEndpoints": [
  {
    "method": "POST",
    "path": "/api/auth/login",
    "description": "Log in with email + password",
    "requestSchema": "LoginRequest",
    "responseSchema": "AuthResponse"
  },
  {
    "method": "GET",
    "path": "/api/items",
    "description": "Fetch item list"
  }
]
```

The `requestSchema` / `responseSchema` reference OpenAPI schemas in `docs/api/*.json` (authored via `jsonui-swagger` skill). Keep the `apiEndpoints` list tight — only include endpoints this screen uses.

---

## `dataFlow.diagram` (optional hand-written Mermaid)

If you want a custom diagram, set `dataFlow.diagram` to Mermaid source. Auto-generation is skipped when this is present.

```jsonc
"dataFlow": {
  "diagram": "flowchart LR\n  View --> VM\n  VM --> Repo\n  Repo --> API",
  "viewModel": { ... }
}
```

For almost all cases, leave it empty and let `jsonui-doc generate spec` draw from the structured fields — it handles View / VM / UC / Repo / API layers, UC→Repo linkage, Repo→Endpoint linkage, and graceful simplification when too many endpoints exist.

---

## Architecture diagram simplification rules

When the auto-generator produces the Mermaid:

- **≤ 4 endpoints + no explicit Repo→Endpoint links** → all endpoints drawn as nodes
- **> 4 endpoints + no explicit links** → collapse into `API (N endpoints)` single node
- **Any explicit links** → draw only declared edges; orphan endpoints become `Other endpoints (N)` node if > 4
- **No UseCase + no Repository** → View → ViewModel only
- **Repository but no UseCase** → ViewModel → Repository direct edge
- **Multiple platforms** → method signature shows union of platforms (per-platform filtering applies at `jui build`)

---

## Common authoring mistakes

1. **Putting `isAsync: true` on everything** — ViewModel methods are synchronous by default. Only button taps that do async work (fetch, network, disk) need it.
2. **Declaring `eventHandlers` items in `dataFlow.viewModel.methods`** — event handlers for pure UI toggles go in `stateManagement.eventHandlers`. Things that reach the VM (tap → fetch → update state) go in `dataFlow.viewModel.methods`.
3. **Closure type in a `var` without `optional: true`** — non-optional closures need initialization; usually you want the optional form.
4. **Forgetting `platforms` on iOS-only methods** — Apple Sign-In, StoreKit, WebKit-specific things should be `platforms: ["ios"]`. Otherwise the Android / Web builds will fail protocol sync.
5. **Mismatched endpoint path** — `"GET /api/items"` in Repository must match `{ "method": "GET", "path": "/api/items" }` in apiEndpoints. Mermaid linkage breaks silently if they don't.
6. **UseCase with a single method calling a single Repo method** — consider whether the UseCase adds value. Often not.

---

## When editing (not creating from scratch)

Any edit to `dataFlow.viewModel.methods` or `vars` changes the Protocol on the next `jui build`. The existing VM Impl must gain / keep / lose the corresponding declaration to stay in sync — otherwise `jui build` fails with `[protocol-sync]` error telling you exactly what's missing.

Coordinate with `implement` when making these edits:

1. `define`: edit spec dataFlow
2. `define`: run `doc_validate_spec`, then `jui_verify` (will drift if Impl hasn't caught up yet — expected)
3. Hand off to `implement`: add / remove the corresponding method body, then `jui_build` to confirm clean protocol sync

---

## References

- `jui_tools_README.md` — canonical spec: "Repository / UseCase pattern", "ViewModel Protocol auto-sync", "Auto-generated Mermaid diagram from dataFlow"
- `rules/invariants.md` — why protocol sync matters (invariants 2 and 3)
- `rules/design-philosophy.md` — hand-written vs generated split
