# JsonUI Agents for Claude Code

A collection of specialized agents and skills for Claude Code to support JsonUI framework development across iOS (SwiftUI/UIKit), Android (Compose/XML), and Web (React/Next.js).

## Installation

### Quick Install (Recommended)

```bash
# Install from main branch (default)
curl -H "Cache-Control: no-cache" -sL "https://raw.githubusercontent.com/Tai-Kimura/JsonUI-Agents-for-claude/main/install.sh?$(date +%s)" | bash

# Install from specific branch
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -b develop

# Install from specific commit
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -c abc123

# Install from specific version tag
curl -H "Cache-Control: no-cache" -sL "...install.sh?$(date +%s)" | bash -s -- -v 1.0.0
```

### After Installation

Run this command to start:

```
Read CLAUDE.md
```

You will be asked to choose a workflow:

1. **Requirements Definition** - Define app requirements through dialogue (recommended for new projects)
2. **Implementation** - Start implementation (requirements already defined)

#### Option 1: Requirements Definition

For new projects or when requirements are not yet defined:
- Select target platform(s) (iOS / Android / Web)
- Describe your app idea
- Define screens through guided questions
- Output: `docs/screens/json/*.spec.json` files

After requirements are complete, **start a new Claude Code session** and run `Read CLAUDE.md` again, then select Option 2.

#### Option 2: Implementation

When requirements are already defined, this launches the `jsonui-orchestrator` agent which guides you through the implementation flow.

## Directory Structure

```
.claude/
├── agents/           # Orchestration agents
├── skills/           # Implementation skills
└── rules/            # Shared rules and guidelines
```

## Agents

Agents orchestrate workflows and coordinate skills.

| Agent | Description |
|-------|-------------|
| `jsonui-requirements` | Requirements gathering for non-engineers - creates screen specifications through dialogue |
| `jsonui-orchestrator` | Main entry point - coordinates full implementation flow |
| `jsonui-spec` | Creates specification documents (API, DB, Screen) |
| `jsonui-setup` | Project initialization and configuration |
| `jsonui-screen-impl` | Screen implementation - coordinates layout/data/viewmodel skills |
| `jsonui-test` | Test orchestration - coordinates test skills |
| `jsonui-responsive` | Adds responsive support to existing screens (tablet/landscape) |
| `jsonui-investigate` | Read-only codebase analysis and investigation |

## Skills

Skills execute specific tasks. Agents invoke skills as needed.

### Implementation Skills

| Skill | Description |
|-------|-------------|
| `jsonui-generator` | Code generation for Views, Collections, Converters |
| `jsonui-layout` | JSON layout creation and implementation |
| `jsonui-refactor` | Layout review, style extraction, include separation |
| `jsonui-data` | Data section type definitions and bindings |
| `jsonui-viewmodel` | ViewModel and business logic implementation |
| `jsonui-converter` | Custom converter implementation |

### Specification Skills

| Skill | Description |
|-------|-------------|
| `jsonui-requirements-gather` | Gathers screen definitions through dialogue to create spec.json files |
| `jsonui-screen-spec` | Screen specification document creation |
| `jsonui-component-spec` | Reusable component specification creation |
| `jsonui-swagger` | API/DB specification (OpenAPI/Swagger) |
| `jsonui-spec-review` | Specification review and validation |

### Test Skills

| Skill | Description |
|-------|-------------|
| `jsonui-test-cli` | Test CLI commands (validate, generate) |
| `jsonui-screen-test-implement` | Screen test implementation |
| `jsonui-flow-test-implement` | Flow test implementation |
| `jsonui-test-document` | Test documentation generation |
| `jsonui-test-setup-ios` | iOS test runner setup |
| `jsonui-test-setup-android` | Android test runner setup |
| `jsonui-test-setup-web` | Web test runner setup |

### Platform Setup Skills

| Skill | Platform |
|-------|----------|
| `swiftjsonui-swiftui-setup` | iOS (SwiftUI) |
| `swiftjsonui-uikit-setup` | iOS (UIKit) |
| `kotlinjsonui-compose-setup` | Android (Jetpack Compose) |
| `kotlinjsonui-xml-setup` | Android (XML Views) |
| `reactjsonui-setup` | Web (React/Next.js) |

## Workflow

### Recommended Workflow (From Scratch)

```
[Session 1: Requirements]
jsonui-requirements
└── /jsonui-requirements-gather
    ├── Platform selection (iOS/Android/Web)
    ├── App concept
    ├── Screen definitions (one by one)
    └── Output: docs/screens/json/*.spec.json

↓ Start new Claude Code session ↓

[Session 2: Implementation]
Read CLAUDE.md → jsonui-orchestrator
├── Step 1: jsonui-spec (review/refine specs)
├── Step 2: jsonui-setup (project configuration)
├── Step 3: jsonui-screen-impl (implementation)
└── Step 4: jsonui-test (testing)
```

### Full Implementation Flow

```
jsonui-orchestrator
├── Step 1: jsonui-spec (create specification - JSON)
│   ├── /jsonui-swagger (API/DB design)
│   └── /jsonui-screen-spec (screen design)
├── Step 2: jsonui-setup (project configuration)
├── Step 3: jsonui-screen-impl (implementation)
│   ├── /jsonui-generator
│   ├── /jsonui-layout
│   ├── /jsonui-refactor
│   ├── /jsonui-data
│   └── /jsonui-viewmodel
└── Step 4: jsonui-test (testing)
    ├── /jsonui-test-cli
    ├── /jsonui-screen-test-implement
    └── /jsonui-test-document
```

### Screen Implementation Flow

```
jsonui-generator → jsonui-layout → jsonui-refactor → jsonui-data → jsonui-viewmodel
```

1. **jsonui-generator**: Generate scaffolding with `sjui g view` / `kjui g view`
2. **jsonui-layout**: Create JSON layout structure with `@{}` bindings
3. **jsonui-refactor**: Review and organize (styles, includes, cleanup)
4. **jsonui-data**: Define types in the `data` section
5. **jsonui-viewmodel**: Implement business logic in ViewModel

## Usage

```
# Starting from scratch (no requirements yet)
"Use the jsonui-requirements agent"

# After requirements are ready (new session)
"Read CLAUDE.md"

# Create specification only
"Use the jsonui-spec agent to design the login screen"

# Set up a new project
"Use the jsonui-setup agent to set up an iOS project"

# Implement a screen (after spec is ready)
"Use the jsonui-screen-impl agent to implement the login screen"

# Run tests
"Use the jsonui-test agent to create tests for the login screen"
```

## Philosophy: Constrain AI to Reduce Output Variance

### The Problem with AI in Product Development

AI excels at vibe coding (one-off prototypes), but struggles with product development:

```
Normal AI Development:
Quality = Spec Quality × Prompt Skill × Context Management
              (unstable)    (unstable)     (unstable)
```

Every variable is unstable, causing output to vary wildly.

### The Solution: Constrain What AI Can Do

JsonUI takes a different approach - **don't let AI do everything**:

1. **Code Constraints**: Rules are embedded in tools, not prompts
   - Wrong format? Automatic error
   - No need to explain rules every time

2. **Specialized Agents**: Separate responsibilities
   - Layout agent only knows layout
   - ViewModel agent only knows logic
   - Each agent has minimal context

```
JsonUI Approach:
Quality = Spec Quality × Code Constraints × Specialized Agents
              (unstable)     (stable)           (stable)
```

Only "Spec Quality" remains as a variable - everything else is stabilized by architecture.

### Result

- **Specification is the single source of truth**
- AI output becomes predictable and consistent
- Quality depends on spec quality, not prompt engineering skill

## Related Repositories

### Core Frameworks

- [SwiftJsonUI](https://github.com/Tai-Kimura/SwiftJsonUI) - JsonUI framework for iOS (SwiftUI / UIKit)
- [KotlinJsonUI](https://github.com/Tai-Kimura/KotlinJsonUI) - JsonUI framework for Android (Jetpack Compose / XML Views)
- [ReactJsonUI](https://github.com/Tai-Kimura/ReactJsonUI) - JsonUI framework for Web (React / Tailwind CSS)

### CLI Tools

- [jsonui-cli](https://github.com/Tai-Kimura/jsonui-cli) - CLI tools for all platforms (sjui_tools, kjui_tools, rjui_tools, test_tools, document_tools)

### Test Runners

- [jsonui-test-runner](https://github.com/Tai-Kimura/jsonui-test-runner) - Test CLI and documentation generator
- [jsonui-test-runner-ios](https://github.com/Tai-Kimura/jsonui-test-runner-ios) - iOS test driver (XCUITest)
- [jsonui-test-runner-android](https://github.com/Tai-Kimura/jsonui-test-runner-android) - Android test driver (UIAutomator)
- [jsonui-test-runner-web](https://github.com/Tai-Kimura/jsonui-test-runner-web) - Web test driver (Playwright)

### Developer Tools

- [swiftjsonui-helper](https://github.com/Tai-Kimura/swiftjsonui-helper) - VSCode extension for SwiftJsonUI

## License

MIT License
