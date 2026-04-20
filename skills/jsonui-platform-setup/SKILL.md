---
name: jsonui-platform-setup
description: Unified platform setup skill. Handles iOS (SwiftUI / UIKit), Android (Compose / XML), Web (React / Next.js), and test runner setup (XCUITest / UIAutomator / Playwright) via mode argument. Invoked by the `ground` agent.
tools: Read, Write, Bash, Glob, Grep
---

# jsonui-platform-setup

Consolidated setup skill that replaces the 8 legacy skills:

- `swiftjsonui-swiftui-setup`
- `swiftjsonui-uikit-setup`
- `kotlinjsonui-compose-setup`
- `kotlinjsonui-xml-setup`
- `reactjsonui-setup`
- `jsonui-test-setup-ios`
- `jsonui-test-setup-android`
- `jsonui-test-setup-web`

Invoked by the `ground` agent. Operates on project scaffolding and test runner configuration — does not author specs, screens, or tests.

---

## Arguments

| Argument | Required | Values |
|---|---|---|
| `target` | ✅ | `app` (application scaffolding) or `test` (test runner setup) |
| `platform` | ✅ | `ios` / `android` / `web` |
| `mode` | (for `target: app`) | iOS: `swiftui` / `uikit`; Android: `compose` / `xml`; Web: `react` / `nextjs` |
| `project_directory` | ✅ | Project root path |
| `jsonui_cli_path` | | Default: `~/.jsonui-cli` |
| `app_config_path` | | Default: `docs/app-config/` |

Route at the top:

```
if target == "app":
    if platform == "ios":   → iOS section (sub-branch on mode)
    if platform == "android": → Android section
    if platform == "web":   → Web section
if target == "test":
    if platform == "ios":   → iOS test setup
    if platform == "android": → Android test setup
    if platform == "web":   → Web test setup
```

Run `jui init` if `jui.config.json` doesn't exist. Read `jui.config.json` to resolve platform paths.

---

## App setup — iOS

### Mode: `swiftui`

1. Ensure `sjui_tools/` is installed in the project:

   ```bash
   # Check
   ls {project_directory}/sjui_tools 2>/dev/null

   # Install if missing
   cd {project_directory}
   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/SwiftJsonUI/main/installer/bootstrap.sh | bash -s -- -d .
   ```

2. Bootstrap the iOS app shell:

   ```bash
   ./sjui_tools/bin/sjui init --mode swiftui
   ```

   This configures:
   - `{project}/Layouts/` (platform copy — `jui build` writes here)
   - `{project}/GeneratedViews/` (generated SwiftUI code, `@generated`)
   - `{project}/ViewModel/` (hand-authored VM impls)
   - `{project}/sjui.config.json` (iOS-specific settings)

3. From `app_config_path/ios.yaml` (or similar), extract:
   - App name, bundle identifier, team ID
   - Minimum iOS version
   - Third-party libraries (SPM / CocoaPods)
   - `Info.plist` keys

4. Apply extracted config to Xcode project (Sheldon-style editing of `project.pbxproj` may be needed for deep integration — defer to manual confirmation if uncertain).

5. Verify:

   ```bash
   cd {project_directory}
   jui build --ios-only
   ```

   Expect 0 warnings on empty project.

### Mode: `uikit`

Same as `swiftui` except:

- Step 2: `./sjui_tools/bin/sjui init --mode uikit`
- Generates Dynamic-mode UIKit view controllers (runtime-loaded JSON) instead of Generated SwiftUI

UIKit uses a different cell / view dispatch. Check for `UIViewController` + Storyboard references when auditing existing project structure.

---

## App setup — Android

### Mode: `compose`

1. Ensure `kjui_tools/` is installed:

   ```bash
   ls {project_directory}/kjui_tools 2>/dev/null
   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/KotlinJsonUI/main/installer/bootstrap.sh | bash -s -- -d .
   ```

2. Bootstrap:

   ```bash
   ./kjui_tools/bin/kjui init --mode compose
   ```

   Configures:
   - `{project}/app/src/main/assets/Layouts/` (platform Layout copy)
   - `{project}/app/src/main/java/.../generated/` (generated Composable code, `@generated`)
   - `{project}/app/src/main/java/.../viewmodel/` (hand-authored VM impls)
   - `{project}/kjui.config.json`

3. From `app_config_path/android.yaml`:
   - App name, `applicationId`
   - Minimum SDK, target SDK
   - Gradle plugin versions, dependencies

4. Apply to `build.gradle.kts` / `build.gradle`.

5. Verify:

   ```bash
   jui build --android-only
   ```

### Mode: `xml`

Same as `compose` except `--mode xml`. Generates Dynamic-mode Android Views with XML bindings instead of Compose.

---

## App setup — Web

### Mode: `react`

1. Ensure `rjui_tools/`:

   ```bash
   ls {project_directory}/rjui_tools 2>/dev/null
   curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/ReactJsonUI/main/installer/bootstrap.sh | bash -s -- -d .
   ```

2. Bootstrap:

   ```bash
   ./rjui_tools/bin/rjui init --framework react
   ```

   Configures:
   - `{project}/src/Layouts/` (platform Layout copy)
   - `{project}/src/generated/` (generated TS/TSX, `@generated`)
   - `{project}/src/viewmodels/` (hand-authored VM impls)
   - `{project}/rjui.config.json`

3. From `app_config_path/web.yaml`:
   - App name, Node version
   - Dependencies (package.json)
   - Vite / CRA / bundler config

4. Apply via `npm install` and config edits.

5. Verify:

   ```bash
   jui build --web-only
   ```

### Mode: `nextjs`

Same as `react` except `--framework nextjs`. Bootstraps a Next.js App Router project (`src/app/`), configures `next.config.js`, and generates page-level components that embed the Dynamic loader.

---

## Test setup — all platforms

Prerequisites: `target: app` setup has already run for the platform.

1. Install the `jsonui-test` CLI (once per machine):

   ```bash
   which jsonui-test || \
     curl -fsSL https://raw.githubusercontent.com/Tai-Kimura/jsonui-test-runner/main/test_tools/installer/bootstrap.sh | bash
   ```

   Requires Python 3.10+.

2. Create the test directory structure (once per project):

   ```bash
   mkdir -p {project_directory}/tests/screens
   mkdir -p {project_directory}/tests/flows
   mkdir -p {project_directory}/tests/descriptions
   ```

### iOS test setup

Wire the JsonUITestRunner XCUITest driver into the iOS project:

1. Locate the iOS Xcode project root (from `jui.config.json:platforms.ios.root`).
2. Add a UI test target if not present (`AppUITests`).
3. Add `JsonUITestRunner` as a Swift Package dependency:

   ```swift
   // Package.swift or via Xcode → File → Add Packages
   .package(url: "https://github.com/Tai-Kimura/jsonui-test-runner-ios", from: "1.0.0")
   ```

4. Link `JsonUITestRunner` to the UI test target.
5. Smoke test:

   ```swift
   // AppUITests/SmokeTest.swift
   import XCTest
   import JsonUITestRunner

   class SmokeTest: XCTestCase {
       func testRunnerLoads() {
           let runner = JsonUITestRunner(app: XCUIApplication())
           XCTAssertNotNil(runner)
       }
   }
   ```

6. Run `xcodebuild test` or in Xcode to verify.

### Android test setup

Wire UIAutomator-based driver:

1. Add to `app/build.gradle.kts`:

   ```kotlin
   androidTestImplementation("com.tai-kimura:jsonui-test-runner:1.0.0")
   ```

2. Create `app/src/androidTest/java/.../SmokeTest.kt`:

   ```kotlin
   @RunWith(AndroidJUnit4::class)
   class SmokeTest {
       @Test fun runnerLoads() {
           val runner = JsonUITestRunner()
           assertNotNull(runner)
       }
   }
   ```

3. Verify: `./gradlew connectedAndroidTest`

### Web test setup

Wire Playwright:

1. Install Playwright:

   ```bash
   cd {project_directory}
   npm init playwright@latest -- --yes --quiet
   ```

2. Add the JsonUI test runner package:

   ```bash
   npm install --save-dev @tai-kimura/jsonui-test-runner-web
   ```

3. Create `tests/playwright/smoke.spec.ts`:

   ```ts
   import { test, expect } from '@playwright/test';
   import { JsonUITestRunner } from '@tai-kimura/jsonui-test-runner-web';

   test('runner loads', async ({ page }) => {
     const runner = new JsonUITestRunner(page);
     expect(runner).toBeDefined();
   });
   ```

4. Verify: `npx playwright test`

---

## Completion output

Structured so `ground` can include it in its report:

```yaml
target: app | test
platform: ios | android | web
mode: <mode>
status: ok | partial | failed
files_created:
  - path1
  - path2
files_modified:
  - path1
verify_command: "jui build --{platform}-only"
verify_result: "0 warnings"
notes:
  - "Third-party X already present — skipped reinstall"
  - "Manual step: update bundle identifier in Xcode"
```

---

## Common pitfalls

1. **Running `jui init` twice** — second run merges, but review the diff. Don't blindly overwrite `jui.config.json` if the user has customized platform paths.
2. **Missing `docs/app-config/`** — the skill falls back to sensible defaults (app name = directory name, min version = current LTS). Flag the missing config in the completion report so the user knows to add it later if they want precise control.
3. **Editing inside tools directories** — `sjui_tools/` / `kjui_tools/` / `rjui_tools/` are framework code. Never edit them manually; if they need a fix, report to the user.
4. **Forgetting `.gitignore`** — platform `Layouts/` directories (`my-app-ios/my-app/Layouts/` etc.) should be ignored; they're regenerated by `jui build`. Add these automatically if `.gitignore` exists.
5. **Assuming test runner is already installed** — always `which jsonui-test` first. Mobile CI often runs without it preinstalled.

---

## Migration note

The 8 legacy skills this replaces are kept during Phase 4 for backward compatibility. They will be removed in Phase 6. New work should invoke this skill with appropriate `target` + `platform` + `mode` arguments.

## References

- `jui_tools_README.md` — CLI reference (`jui init`, `jui build`)
- Platform-specific docs in `sjui_tools/` / `kjui_tools/` / `rjui_tools/`
- `jsonui-test-runner` README (per-platform)
