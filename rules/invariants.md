# Invariants — The 5 Core Rules + 4 API Model Rules

The first five invariants apply to **every** JsonUI task. A task is not complete until all five hold. Everything else in this project is a means to satisfy them.

Invariants 6–9 apply when the project uses swagger-driven Data Model codegen (any project with `docs/api/*.json` files).

---

## 1. `jui build` must pass with **zero warnings**

`jui build` detects Layout JSON mistakes: unknown attributes, invalid bindings, type mismatches, broken path resolution, missing files, `platform` / `responsive` structure errors.

- One or more warnings → the task is not done
- Fix the root cause (spec, Layout JSON, Styles, strings.json, VM impl) — **never suppress or ignore**
- Loop: edit → `jui build` → read warnings → fix → repeat until zero
- `jui build` exits 1 → not done either, whatever the count. When its last line is `[ERROR] exit 1: N stage(s) did not complete. …`, the `  - <stage>: <message>` lines above it name each stage a platform build did not complete; `ERROR: Build failed for: <platform>` means that platform's tool stopped — its own ERROR lines above it say why; `jui build`'s own checks name themselves (e.g. `ERROR [layout-ids]: …`). From jsonui-cli 1.9.0 an ERROR a platform build prints and carries on past is such a stage — a style a layout names that is missing or does not parse is one; a missing one still prints `Warning: Style file … not found`, but one that does not parse no longer does on iOS and web, so the count below can read 0 while the build fails. Never pass `--allow-partial` to get past it.
- A warning a platform tool prints while it converts a layout (from 1.9.0, e.g. a custom component's prop value it did not write) is printed only by the build that converts that layout; a build that finds it cached does not print it again. Count from `jui build --clean` before calling the build clean.

```bash
jui build 2>&1 | grep -iE 'warning \[|warning:|\[warn|⚠' | grep -vic 'warnings found'
# 0 ← required
```

The second filter drops the build's own summary line (`[WARN] Validation warnings found: N`), which is printed through the same logger and would otherwise count as one more finding than there are (measured on real build logs: 2/2/0/4 against 1/1/0/3 findings).

The filter is a heuristic and errs on the low side: a finding whose own text contains "warnings found" is dropped together with the summary, so read the number as a floor and, whenever it is not 0, read the lines themselves. Keep the `-c` at the end and only there — a `-c` earlier in the pipe turns every later stage into a count of one line, and the expression then reports 1 whether there are five findings or none (measured: 5 → 1, 0 → 1). The zero case is the dangerous one: it reports a finding that does not exist, and the reader goes looking for it. Other tools print their own summaries in other spellings (`jsonui-test validate` ends with `Warnings: 0`, which this expression does not match but a looser `warn` pattern does), so an expression borrowed for another command has to be checked against that command's output first.

**The build does not count for you.** `jui build` prints its warnings and exits 0 whether there are none or fifty — it keeps no warning tally, has no line that fails on one, and the "zero warnings" rule lives *here*, in this rulebook, not in the process's exit code. So the gate is you reading the output. Warnings arrive in four spellings, and a narrow pattern silently counts a different thing each time (measured on a consumer's logs, 2026-09-04):

| spelling | where it comes from | trap |
|---|---|---|
| `WARNING [origin]: …` | the Python build itself (`WARNING [lint-strings]:`, `WARNING [normalize]:`) — the most common | the colon follows the bracketed origin, so `warning:` never matches it; `\[WARN` matches `[WARN]` but not `[lint-strings]` |
| `WARNING: …` / `warning: …` | other Python and Ruby paths | case-sensitive `warning:` misses the upper-case form |
| `⚠` | attribute / design warnings | not matched by any `warn` pattern |
| `[WARN]` | Ruby logger, **with ANSI colour before it** (`\e[33m[WARN]\e[0m`) | `^\[WARN` anchored at column 0 is always 0 |

Count with the unanchored, case-insensitive expression above — it matches all four shapes and none of the prose lines the build also prints ("no warnings", "Warnings: 0"). The first version of this rule shipped `'warning:|\[WARN|⚠'`, which misses the most common shape; it lasted one hour before a lane measured it against the actual print sites. Accepted warnings (a consumer's baseline of 14 `⚠` it has chosen to live with) are not "zero" — write the number and the reason, never "0 warnings".

**The accepted warning most projects will meet is `WARNING [toolchain]:`.** It says this project's vendored platform tools were synced from an older version than the CLI now running, so the project builds with one toolchain and is validated by another. It reaches the expression above through `warning \[`, so it counts. The library's own docstring used to promise the opposite — that the line was "not counted toward the zero-warnings gate" — and was corrected on 2026-09-09: there is no tally in the process to be outside of, so the rulebook's expression is the only thing counting, and it matches. Record the count with its cause and your decision, next to the build result:

```
warnings 3 — toolchain split, `jui sync_tool` pending, accepted
```

The count is per vendored platform, not per project, so a project vendoring three platforms contributes three lines and one vendoring web alone contributes one. Which kind of split you have is already written in the line you are reading — `synced from 1.8.57, but this CLI is 1.8.60` — so compare the two versions rather than running anything. `bootstrap` replaces the shared CLI for every face at once while `sync_tool` is per-face, so lagging the immediately preceding release is the ordinary state *between those two events*; lagging by more than one release is a project that was left behind and never caught up. A one-release gap is consistent with both and settles nothing on its own; a larger gap settles it. `jui sync_tool` clears the line in either case, so whether it clears is not the discriminator — the two versions in the message are. Never write "0 warnings" on the grounds that the split was expected, and never narrow the expression to exclude the line: an exclusion silences the left-behind case too, and that case has no other symptom.

**The libraries move with the CLI.** Code generated by jsonui-cli 1.9.0 can use API first shipped in SwiftJsonUI 10.29.0 and KotlinJsonUI 2.42.0 — `CollectionContentFit`, `jsonuiInteractionStopped` / `LocalInteractionStopped` (a node that `userInteractionEnabled` stops and that holds a Collection, an Embed or a TabView tab), `linksEnabled` (a linked Label inside such a node), among others — and on an older library the app's own build fails in a generated file. The fix is the app's library version (its Swift package / Gradle dependency), never the generated code; some generated lines name the version they need as `// Requires SwiftJsonUI >= …` / `// Requires KotlinJsonUI >= …`, others do not.

**What `jui build` does in order** (relevant for diagnosing failures):
1. Distributes shared `layouts/` / `styles/` / `resources/` / `images/` to each platform.
2. Syncs ViewModel Protocol/Base files from spec + Impl markers (hard-errors on drift).
3. Runs `sjui build` / `kjui build` / `rjui build` per active platform.

**`jui build` does NOT scaffold converters.** If a custom component's `type` appears in a Layout JSON but no converter exists for it, the build emits warnings / errors per platform. Run `jui g converter --from <name>.component.json` (or `--all`) explicitly to scaffold before building.

---

## 2. `jui verify --fail-on-diff` must pass with **no drift**

`jui verify` compares the Layout JSON that `jui generate project` *would* produce from the current spec against what's actually on disk. A diff means spec and Layout have drifted apart.

- Diff found → decide which side is correct:
  - Spec is wrong → fix spec (`define` agent)
  - Layout is wrong → fix Layout JSON (`implement` agent)
- Do not silence the check or accept drift

```bash
jui verify --fail-on-diff
# Exit 0 ← required
```

### ⚠️ Exit 0 is not the whole result — read the denominator

`jui verify` only compares screens whose Layout JSON it could have generated. A screen whose spec points at a hand-authored layout is **skipped**, and skipped screens do not affect the exit code. So a face where every screen is authored externally passes this invariant while comparing nothing.

This is not a corner case. Across six projects measured together, the count of screens
actually compared was zero in every one — 47, 30, 19, 18, 11 and 2 screens respectively,
all of them skipped with the reason `layout authored externally`.

**Satisfying this invariant is therefore not by itself evidence that spec and Layout agree.** Read the line `jui verify` prints (1.8.5 and later name the denominator: `verified N of M screen(s) — K skipped (reason)`), and treat `verified 0` as *this check did not run*, not as *this check passed*. `--json PATH` writes the same numbers as `verified` / `skipped` / `total` / `skippedByReason` for a gate to assert on.

When `verified` is 0, spec–Layout agreement has to come from somewhere else — review of the authored Layout against the spec, or a test that exercises the screen. Do not report the screen as verified.

---

## 3. `@generated` files are **never edited by hand**

The following files carry `@generated` markers and are regenerated by `jui build`:

- iOS: `*ViewModelProtocol.swift`, Repository/UseCase protocols
- Android: `*ViewModelProtocol.kt`, Repository/UseCase interfaces
- Web: `*ViewModelBase.ts`, Repository/UseCase bases
- Method / var signatures come from `dataFlow.viewModel` and `dataFlow.{repositories,useCases}[].methods`
- Impl inheritance list completion, Kotlin `override` insertion

**To change any of these, edit the spec.** Then `jui build` regenerates.

`jui lint-generated` detects hand-edits of generated files. CI should run it.

```bash
jui lint-generated
# Exit 0 ← required for CI
```

---

## 4. Localization — the layout half is machine-checked, **the VM half is not**

`jui lint-strings` scans the Layout JSON (style-merged, alias-canonicalized) for user-visible string attributes whose value is a raw literal that does not resolve through `strings.json`. Exit 0 is the gate; the `jsonui-localize` skill is the **repair tool** you run when the lint reports findings.

```bash
jui lint-strings
# Exit 0 ← required. 2 = raw literals / stale allowlist entries
```

- Every screen completion must end with a clean `jui lint-strings` (and a `jsonui-localize` pass for the VM-side strings the layout scan cannot see)
- Intentional non-localized literals (brand names, format scaffolding) go in `.jui-strings-allowlist.json` — one entry per (layout, path, value), **reason required**. The ledger fails in both directions: an unlisted raw literal, and a stale entry whose literal is gone
- `jui build --lint-strings` (or `"lint": {"strings": true}` in jui.config.json) runs the same check inside the build, where findings are **printed** as build warnings — the build's exit code does not change (it has no warning tally), so they gate only through invariant 1, i.e. through you counting them. The hard gate that actually fails is `jui lint-strings` run on its own (exit 2)
- VM-side strings (error messages, alert titles) are still the `jsonui-localize` skill's territory — the lint covers the layout surface

### ⛔ The VM half has no gate at all — the sweep is the gate

`jui lint-strings` proves **layout** literals resolve. `--usage` compares the
**key sets** between `strings.json` and code that references keys. A display
string written straight into VM source **references no key**, so neither sees
it: build clean, verify no drift, lint exit 0, and the untranslated text ships.
This is the one invariant whose violation produces **no red anywhere**.

So the VM side is a **procedure**, not a check, and it must be executed rather
than intended:

- **Every string literal in VM/Repository/UseCase source is display text
  unless** it is a dictionary/JSON key or param name, an API path or URL, an
  enum raw value / state id / screen id, log output that is never rendered, or
  a word-free format specifier (`"%.2f"`, `", "`). **When unsure, it is display
  text** — a redundant key costs one entry; an inlined display string ships
  untranslated and nothing reports it.
- Do not decide "is this user-visible?" literal by literal while writing logic.
  That is where it leaks: an error message does not feel like UI text while you
  are writing error handling. **Sweep mechanically and account for every hit.**
- **Report the denominator**: "swept N literals across these files, localized
  M". A bare "0 strings found" from reading the wrong file is indistinguishable
  from a screen that was already clean — and so are all five green gates.

Most-missed, all display text: error/validation messages, empty-state text,
alert titles/bodies/buttons (`"OK"`, `"キャンセル"`), status labels assigned in
code, units concatenated onto numbers (`"\(count)件"`), accessibility labels,
and words produced by a `switch`/`when` over a state.

---

## 5. Conditional logic and hand-written code are **declared and tested**

A contract exists to make a test exist. `branchContracts` and `unitContracts` are how behaviour that a human wrote gets asserted; they are not a filing requirement.

⛔ **Do not add a contract that produces no test worth running.** A pass-through getter, a one-line setter, a method with no branches and nothing to assert — no entry. A `note` saying "no branches" is not a contract: it raises the declared count and asserts nothing. If the entry would not cause a real test to exist, leave it out.

**Where a contract IS required:**

- `branchContracts` — a `dataFlow.viewModel.methods` method whose behaviour **depends on a condition**: branches on state, validation, error paths, a `switch`/`when` over a state. Each branch is a case someone can fail
- `unitContracts` — hand-written classes and logic that no generator produces:

```json
{ "target": "<Class>", "cases": [ { "name": "...", "intent": "...", "platforms": ["ios", "android", "web"] } ] }
```

`platforms` omitted means every platform; the block is an object or an array of them. `doc_validate_spec` lints the shape.

- `unitContracts` in the **`app_contracts_spec`** — the app-wide effects of the network layer: signing out on a terminal 401, the force-update overlay on 426, refresh, which paths are excluded from them, opt-out flags a call can pass. These happen at the app root, outside every screen's branch harness, so no screen's `branchContracts` can assert them. A screen's rows answer only what its ViewModel does when the status reaches it — and it does reach it: the handler runs, then the error is thrown to the caller

```bash
jsonui-test generate branch-tests --check   # per platform, with the -p / --package / --module you generate with (no -p = web)
jsonui-test generate unit-stubs   --check
# Exit 0 ← required: every declared case is implemented
# (unit-stubs, from 1.9.0: and no `unattributed` on a platform line)
```

- ⚠️ **These checks measure agreement, not coverage.** They compare the DECLARED set against implemented test names. `N = 0 case(s) declared` exits 0 exactly like a fully implemented project. So the exit code is a floor, never the answer — quote `N case(s) declared across M spec file(s)`, never "check passed"
  - From jsonui-cli 1.9.0 each platform line of `unit-stubs --check` counts (target, case) pairs — `<p>: declared P, implemented I, missing M, undeclared U[, unattributed A] ((target, case) pairs, over K case name(s); F file(s) read)` — so its `declared` can rise at the upgrade with no spec change; quote N from the first line, which is unchanged. `unattributed A` on that line does not by itself fail the check, but those pairs were not checked: tests of a case name several targets declare that no target's class, describe or file places. Move each into its target's place until the field is gone — exit 0 with it is not every declared case implemented
- **Coverage is reported by `jsonui-test validate` from 1.8.119 and gates it from 1.9.0.** Until 1.9.0, validate prints a coverage section (or one line saying why it did not run) and a gate line, and its exit code does not change; "coverage not applicable" and "coverage skipped" are the only line. The gate line validate prints is the authority: "validate gates on contracts coverage (from …)" means it is on; the notice ("from jsonui-cli …, validate fails on …") means announced for that release; a line that starts "coverage gate" (withdrawn, version not declared, version unreadable, cannot be read) means it does not gate. In 1.9.0 and 1.9.1 the first of these reads "validate gates on contracts coverage (from jsonui-cli 1.8.121)": 1.8.121 is the name 1.8.120 announced for the release that shipped as 1.9.0. No 1.8.121 was released — the line means the gate is on, not that another jsonui-cli is installed. "coverage not applicable", "coverage not run" and "coverage skipped" mean the gate did not read coverage — none of them is a coverage pass. From 1.9.0 it fails on every coverage entry that is not in the app's baseline (`contracts_coverage_baseline.json` in the spec directory; with no baseline file, every entry), on every baseline entry that is already closed (stale), on every baseline entry whose unit left the run (vanished: the screen left the platform, the platform left `jui.config.json`, or the spec file, method, operation or status is gone — a rename too), and on what can never be baselined: a declaration error, a row or screen that could not be evaluated, a platform whose HTTP endpoints had nothing evaluated at all, and a coverage that cannot start. `--no-coverage-check` skips the section and says so; agents never pass it to get a green. Quote `baselined N (matched · new · stale[ · unmeasured now][ · vanished])` with every result — a pass with `baselined` above 0 means the debt is recorded, not that the outcomes are answered. `unmeasured now` counts baselined entries whose operation (for no scenario, whose status) cannot be measured in this run: kept, neither matched nor closed. `vanished` entries are kept as well, and keep the gate red until the user removes or re-keys them by hand. When the same platform also reports `not evaluated` or `screens not evaluated`, fix those first and measure again; only what is still vanished then is the user's.
  - `jsonui-test contracts baseline` (1.8.119+, run from the app's root) records the current entries once — only with `--initial` — and afterwards only removes the closed ones — entries the run measured and a decision answers (for an unmeasured entry: its operation or status measured again) — keeping what is only unmeasured now and what vanished; it never adds. **Recording the first baseline accepts all of today's debt: that is the user's decision, made once. Agents never pass `--initial`, and never create, delete, regenerate or hand-edit the file — they only shrink an existing one.** When it prints `new K not added (close them, or add by hand)`, the K go to Task 6 of the define agent; adding by hand is the user's option, not an agent's. `nothing written — the gate fails on these …` names what cannot be baselined — fix those first; `nothing written — recording the first baseline …` means there is no file — stop and tell the user. `(V vanished — not closed, kept; remove or re-key them by hand)` is the user's to resolve: tell them. When validate says `the coverage baseline cannot be read`, or the command says `cannot start` (a merge conflict, for example), stop and report it: repairing the file is the user's, like the first recording
  - `jsonui-test contracts coverage` (1.8.116+) lists the API outcomes the OpenAPI declares that no branch row answers, per method × operation × platform. Agents run it as `test_contracts_coverage` (jsonui-mcp-server 2.13.0+), whose `exit` is the CLI's verdict: 0 pass or empty, 1 uncovered or a declaration error, 2 cannot start, 3 something could not be evaluated. `exit: null` (`no_report`) means no report came back that the tool could trust — nothing was measured. Read `units` and `statuses required` on the same line as the result — `units 0` means nothing was measured, not that everything is covered. Close an `uncovered` status in this order:
  1. a row whose `when` serves that status
  2. `alsoStatuses` on an existing row, when the ViewModel treats that status exactly like the row's own (the generator copies the row and checks it)
  3. `excludedOutcomes` with `by` (`unit` / `unreachable` / `unexpressible`) and a `reason` — the last resort, because it asserts nothing
  4. `unreachedOps` for an operation no contracted method calls
  - An endpoint declared only in `dataFlow.apiEndpoints`, with no `repositories` / `useCases` method whose `endpoint` is that route, is reported `n/a(unbound endpoint)` and exits 3: no generated test can see its calls (they reach the runtime as undeclared). Bind it to the method that calls it — do not answer it with rows or exclusions
- ⚠️ **Since 1.8.116 a generated branch test fails when the method calls a declared endpoint that none of its rows reaches.** The failure names the operation. If the method really makes that call (a refetch after a save, a follow-up load), add `"api.<op>": "called"` to the row whose act makes it; do not delete the endpoint from `dataFlow` to make the red go away — that turns the declaration into a lie. That row's `called` permits the operation in every row of the method that does not mention it: the bound is per method, not per branch. The sibling rows that were green before the edit do not make the call; each one that must not make it says `"api.<op>": "not-called"`, or nothing asserts it any more. A note that says so is not an assertion. From jsonui-cli 1.9.0 the bound and `"not-called"` hold over a stated window — the act, then until no request has been in flight for 400 ms — and their failures say so; after the upgrade a row that was green can go red because the window now sees a call the earlier fixed drain missed — usually the method's (an earlier row's view model can make it too where the runtime cannot keep it out: a subscription on web, or any such call where web rows cannot be told apart; a process-wide base URL on Android; on iOS a view model kept alive — every earlier one below 26, a leaked one from 26)
- ⚠️ **Declare in the sub-spec, never in a parent spec.** `screen_parent_spec` merging discards these blocks; since 1.8.46 `--check` reports PROBLEM and exits non-zero instead of losing them silently
- Implementation is detected **by name**: iOS `func test_<name>(` in a class declared `: XCTestCase` (one that inherits it through another base class is not read), Android `@Test fun <name>(`, web `it("<name>")` / `test("<name>")`. A renamed test is an unimplemented case. From jsonui-cli 1.9.0 `unit-stubs --check` also asks **which target** a test is for: its class `<target>ContractTests` (iOS) or `<target>ContractTest` (Android — the nearest `class` above the test), or its outermost `describe('<target>')` (web) — failing that, its file `<target>ContractTests.swift` / `<target>ContractTest.kt` / `<target>.contract.test.ts`. These are the names `generate unit-stubs` writes, and `<target>` is the entry's `target`. A case name only one target declares is still met by a test in any class, describe or file that names no other target; a name several targets declare needs one test per target, each in that target's class, describe or file — one test in a shared helper meets none of them. A test placed in another target's class or file is UNDECLARED there, and the target that declares the case is MISSING it — so a project that passed before the upgrade can fail after it with no spec or test change. Keeping each target's tests where `generate` puts them is right on every version
- `unit-stubs` writes the stub in each platform's convention; the body is yours. It needs `platforms.<p>.unitTestsDir` in `jui.config.json`
- Neither check has an MCP tool — both run through Bash (see `mcp-policy.md`)

**Why this is not double bookkeeping.** `branchContracts` is the canonical statement of conditional behaviour, so prose in `displayLogic` and friends stays thin and points at it. It is also what lets the cross-platform consistency warning (v1.6.23) compare faces at all — that needs one declared shape, not three descriptions of it.

---

## 6. DTO files are **regenerated** every build — never edit

Files under the per-platform DTO directory carry `@generated` markers and are rewritten on every `jui build` from the swagger source:

- iOS: `Model/Generated/*Dto.swift` (and `Model/Generated/{EnumName}.swift` for standalone enums)
- Android: `<source_directory>/kotlin/<package_path>/<model_subpackage>/generated/*Dto.kt`
- Web: `<source_directory>/models/generated/*Dto.ts`

To change a DTO field shape, edit the swagger schema (`docs/api/*.json`). The DTO regenerates on the next build.

---

## 7. Domain scaffolds are **user-owned after first emit**

Files at the Domain level — `Model/{Name}.swift` / `<package>/model/{Name}.kt` / `models/{Name}.ts` — are scaffolded **once** by `jui build` (containing just `let dto: {Name}Dto` + init/factory) and then **never touched** by codegen.

- Add proxy properties, computed properties, stored properties, and methods directly to the Domain file
- To regenerate a Domain scaffold from scratch (rare), delete the file and rerun `jui build`
- `jui verify --fail-on-diff` does NOT check Domain drift — user editing is expected

---

## 8. `jui verify --fail-on-diff` checks **DTO drift only**

`jui verify` regenerates the DTO bytes in memory and compares against the on-disk DTO files. A diff means swagger changed but `jui build` wasn't re-run, or someone hand-edited a DTO (violation of invariant 5).

- Drift detected → run `jui build` (or `jui g api --dry-run --json` to see what would change without writing)
- The drift check is independent of `jui build`; it runs even when the build pipeline hasn't been executed

---

## 9. Filter changes can **delete DTOs** via orphan prune

`api.schemas.include_paths` / `exclude_paths` / `include_schemas` / `exclude_schemas` modifications change the kept schema set. DTOs that fall out of the kept set are **deleted on the next `jui build`** (orphan prune).

- Domain scaffolds for those schemas are NOT auto-deleted (user code may still reference them)
- `jui lint-generated --fail-on-orphan` (Phase 4 deliverable) flags orphan Domain scaffolds for cleanup
- Filter changes are reversible — restore the previous filter and `jui build` regenerates the DTOs

---

## Gate summary (CI triad + process gate + API model)

| # | Gate | Check | Enforced by |
|---|------|-------|-------------|
| 1 | Layout correctness | `jui build` 0 warnings | build toolchain |
| 2 | Spec ↔ Layout alignment | `jui verify --fail-on-diff` | verify |
| 3 | Generated file integrity | `jui lint-generated` | lint |
| 4 | Localization complete | `jui lint-strings` exit 0 (layout) + **VM literal sweep, accounted for** (VM strings — **no gate**) | lint + **procedure only** |
| 5 | Conditional / hand-written logic tested | `jsonui-test generate branch-tests --check` + `unit-stubs --check` exit 0 — **declared-vs-implemented agreement only**. Coverage of the declared API outcomes: reported by `jsonui-test validate` from 1.8.119, **a gate from 1.9.0** (nothing outside the app's baseline, nothing stale or vanished in it, nothing that cannot be baselined) | jsonui-test |
| 6 | DTO files unmodified by hand | `jui lint-generated` | lint |
| 7 | Domain scaffold preservation | `jui build` skips existing | build toolchain |
| 8 | DTO drift detection | `jui verify --fail-on-diff` | verify |

A screen is "done" only when invariants 1-5 hold (and 6-8 hold whenever the project uses swagger-driven Data Models).
