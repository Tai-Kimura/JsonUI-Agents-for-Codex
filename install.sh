#!/bin/bash

# JsonUI Agents Installer for Codex CLI
# This script installs JsonUI agents and skills to Codex CLI's directories
#
# Usage:
#   ./install.sh                    # Install from main branch
#   ./install.sh -b develop         # Install from specific branch
#   ./install.sh -c abc123          # Install from specific commit
#   ./install.sh -v 1.0.0           # Install from specific version tag

set -e

# Default values
REF="main"
REF_TYPE="branch"

# Parse arguments
while getopts "b:c:v:h" opt; do
    case $opt in
        b)
            REF="$OPTARG"
            REF_TYPE="branch"
            ;;
        c)
            REF="$OPTARG"
            REF_TYPE="commit"
            ;;
        v)
            REF="$OPTARG"
            REF_TYPE="tag"
            ;;
        h)
            echo "Usage: $0 [-b branch] [-c commit] [-v version]"
            echo ""
            echo "Options:"
            echo "  -b BRANCH   Install from specific branch (default: main)"
            echo "  -c COMMIT   Install from specific commit hash"
            echo "  -v VERSION  Install from specific version tag"
            echo "  -h          Show this help message"
            exit 0
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

REPO_URL="https://raw.githubusercontent.com/Tai-Kimura/JsonUI-Agents-for-Codex/$REF"
CODEX_DIR=".codex"
AGENTS_DIR="$CODEX_DIR/agents"
SKILLS_DIR=".agents/skills"

# Agent config files (in agents/ directory)
AGENT_FILES="jsonui-orchestrator.toml jsonui-modify.toml jsonui-requirements.toml jsonui-screen-impl.toml jsonui-setup.toml jsonui-spec.toml jsonui-test.toml"

# Skill directories (each contains SKILL.md and optionally examples/)
SKILL_DIRS="jsonui-component-spec jsonui-converter jsonui-data jsonui-doc-rules jsonui-flow-test-implement jsonui-generator jsonui-layout jsonui-refactor jsonui-requirements-gather jsonui-screen-spec jsonui-screen-test-implement jsonui-spec-review jsonui-swagger jsonui-test-cli jsonui-test-document jsonui-test-setup-android jsonui-test-setup-ios jsonui-test-setup-web jsonui-viewmodel kotlinjsonui-compose-setup kotlinjsonui-xml-setup reactjsonui-setup swiftjsonui-swiftui-setup swiftjsonui-uikit-setup"

# Function to get examples for a skill (Bash 3.2 compatible - no associative arrays)
get_skill_examples() {
    case "$1" in
        jsonui-data)
            echo "binding-missing-data.json binding-with-data.json collection-data-definition.json collection-items.json collection-legacy.json data-section-basic.json data-with-callbacks.json platform-specific-type.json twoway-binding-correct.json twoway-binding-wrong.json"
            ;;
        jsonui-layout)
            echo "binding-correct.json binding-wrong.json collection-swiftui-basic.json collection-swiftui-full.json collection-uikit.json collection-wrong.json color-correct.json color-wrong.json id-naming-correct.json id-naming-wrong.json include-correct.json include-wrong.json screen-root-structure.json screen-root-wrong.json strings-json.json tabview.json tabview-wrong.json"
            ;;
        jsonui-refactor)
            echo "collection-swiftui.json collection-uikit.json include-header.json include-usage.json include-wrong.json padding-correct.json padding-wrong.json style-apply.json style-card.json style-primary-button.json tabview.json"
            ;;
        jsonui-requirements-gather)
            echo "screen-spec-template.json"
            ;;
        jsonui-screen-spec)
            echo "component.json data-flow.json layout.json state-management.json transitions.json user-actions.json validation.json"
            ;;
        jsonui-swagger)
            echo "db-extensions.json db-model-template.json property-types.json"
            ;;
        jsonui-viewmodel)
            echo "collection-kotlin.kt collection-swift.swift colormanager-kotlin.kt colormanager-swift.swift event-handler-kotlin.kt event-handler-swift.swift hardcode-correct.kt hardcode-correct.swift hardcode-wrong.kt hardcode-wrong.swift logger-correct.swift logger-wrong.swift repository-pattern.swift stringmanager-swift.swift strings-kotlin.kt viewmodel-kotlin.kt viewmodel-swift.swift"
            ;;
        *)
            echo ""
            ;;
    esac
}

echo "Installing JsonUI Agents for Codex CLI..."
echo "  Source: $REF_TYPE '$REF'"

# Create directories
for dir in "$CODEX_DIR" "$AGENTS_DIR" "$SKILLS_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Count items
agent_count=0
skill_count=0

# Download config.toml
echo ""
echo "Downloading Codex configuration..."
echo "  - .codex/config.toml"
if ! curl -sLf "$REPO_URL/.codex/config.toml" -o "$CODEX_DIR/config.toml"; then
    echo "Error: Failed to download .codex/config.toml" >&2
    echo "Please check if the $REF_TYPE '$REF' exists." >&2
    exit 1
fi

# Download agent config files
echo ""
echo "Downloading agent configurations..."
for file in $AGENT_FILES; do
    echo "  - agents/$file"
    if ! curl -sLf "$REPO_URL/agents/$file" -o "$AGENTS_DIR/$file"; then
        echo "Error: Failed to download agents/$file" >&2
        echo "Please check if the $REF_TYPE '$REF' exists." >&2
        exit 1
    fi
    agent_count=$((agent_count + 1))
done

# Download skill files
echo ""
echo "Downloading skills..."
for skill in $SKILL_DIRS; do
    echo "  - skills/$skill/SKILL.md"
    mkdir -p "$SKILLS_DIR/$skill"
    if ! curl -sLf "$REPO_URL/skills/$skill/SKILL.md" -o "$SKILLS_DIR/$skill/SKILL.md"; then
        echo "Error: Failed to download skills/$skill/SKILL.md" >&2
        echo "Please check if the $REF_TYPE '$REF' exists." >&2
        exit 1
    fi
    skill_count=$((skill_count + 1))

    # Download examples if they exist for this skill
    examples=$(get_skill_examples "$skill")
    if [ -n "$examples" ]; then
        mkdir -p "$SKILLS_DIR/$skill/examples"
        for example in $examples; do
            echo "    - examples/$example"
            if ! curl -sLf "$REPO_URL/skills/$skill/examples/$example" -o "$SKILLS_DIR/$skill/examples/$example" 2>/dev/null; then
                echo "    (skipped - not found)"
            fi
        done
    fi
done

# Download AGENTS.md to project root
echo ""
echo "Downloading AGENTS.md..."
if ! curl -sLf "$REPO_URL/AGENTS.md" -o "AGENTS.md"; then
    echo "Warning: Failed to download AGENTS.md (optional)" >&2
else
    echo "  - AGENTS.md (project root)"
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installed:"
echo "  Agent configs: $agent_count"
echo "  Skills: $skill_count"
echo ""
echo "Files installed to:"
echo "  - $CODEX_DIR/config.toml"
echo "  - $AGENTS_DIR/"
echo "  - $SKILLS_DIR/"
echo ""
echo "========================================"
echo "          HOW TO GET STARTED"
echo "========================================"
echo ""
echo "1. Enable multi-agent feature (if not enabled):"
echo "   In Codex CLI, type: /experimental"
echo "   Then toggle 'Multi-agents' ON"
echo ""
echo "   Or add to ~/.codex/config.toml:"
echo "   [features]"
echo "   multi_agent = true"
echo ""
echo "Option A: Requirements Already Defined"
echo "---------------------------------------"
echo "If you already have clear requirements documented:"
echo ""
echo "  > Read AGENTS.md"
echo ""
echo "This launches the orchestrator for implementation."
echo ""
echo "Option B: Requirements Not Yet Defined (Recommended)"
echo "-----------------------------------------------------"
echo "If starting from scratch or need help defining what to build:"
echo ""
echo "  > Switch to the jsonui-requirements agent"
echo ""
echo "This agent helps define app requirements through dialogue:"
echo "  1. Select platform(s) (iOS / Android / Web)"
echo "  2. Describe your app idea"
echo "  3. Define screens through guided questions"
echo "  4. Output: docs/screens/json/*.spec.json"
echo ""
echo "After requirements are complete, START A NEW SESSION and run:"
echo ""
echo "  > Read AGENTS.md"
echo ""
echo "========================================"
echo ""
echo "IMPORTANT: Please restart your Codex CLI session"
echo "to load the newly installed agents and skills."
echo ""
echo "========================================"
