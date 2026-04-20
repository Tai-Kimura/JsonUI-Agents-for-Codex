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
AGENTS_DIR="agents"
SKILLS_DIR="skills"
RULES_DIR="rules"

# Agent config files (9-agent layout)
AGENT_FILES="conductor.toml debug.toml define.toml ground.toml implement.toml navigation-android.toml navigation-ios.toml navigation-web.toml test.toml"

# Skill directories (11 skills; each contains SKILL.md and optionally examples/)
SKILL_DIRS="jsonui-component-spec jsonui-dataflow jsonui-flow-test jsonui-layout jsonui-localize jsonui-platform-setup jsonui-screen-spec jsonui-screen-test jsonui-swagger jsonui-test-doc jsonui-viewmodel-impl"

# Rule files (5 invariants / policy / philosophy / placement / spec authoring)
RULE_FILES="invariants.md mcp-policy.md design-philosophy.md file-locations.md specification-rules.md"

# Function to get examples for a skill (Bash 3.2 compatible - no associative arrays)
get_skill_examples() {
    case "$1" in
        jsonui-layout)
            echo "binding-correct.json binding-wrong.json collection-swiftui-basic.json collection-swiftui-full.json collection-uikit.json collection-wrong.json color-correct.json color-wrong.json id-naming-correct.json id-naming-wrong.json include-correct.json include-wrong.json screen-root-structure.json screen-root-wrong.json strings-json.json tabview.json tabview-wrong.json"
            ;;
        jsonui-screen-spec)
            echo "component.json data-flow.json layout.json state-management.json transitions.json user-actions.json validation.json"
            ;;
        jsonui-swagger)
            echo "db-extensions.json db-model-template.json property-types.json"
            ;;
        jsonui-viewmodel-impl)
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
for dir in "$CODEX_DIR" "$AGENTS_DIR" "$SKILLS_DIR" "$RULES_DIR"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    fi
done

# Count items
agent_count=0
skill_count=0
rule_count=0

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

# Download rule files (Phase 5)
echo ""
echo "Downloading rules..."
for file in $RULE_FILES; do
    echo "  - rules/$file"
    if ! curl -sLf "$REPO_URL/rules/$file" -o "$RULES_DIR/$file"; then
        echo "Error: Failed to download rules/$file" >&2
        echo "Please check if the $REF_TYPE '$REF' exists." >&2
        exit 1
    fi
    rule_count=$((rule_count + 1))
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
echo "  Rules: $rule_count"
echo ""
echo "Files installed to:"
echo "  - $CODEX_DIR/config.toml"
echo "  - $AGENTS_DIR/"
echo "  - $SKILLS_DIR/"
echo "  - $RULES_DIR/"
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
echo "Standard flow (all workflows route through /agent conductor):"
echo "---------------------------------------------------------------"
echo ""
echo "  > Read AGENTS.md"
echo ""
echo "AGENTS.md will ask which workflow you want (1: new work,"
echo "2: modify existing, 3: investigate, 4: backend). The first"
echo "three all route to /agent conductor, which inspects the repo"
echo "via MCP and tells you which specialized agent to switch to"
echo "(define / ground / implement / navigation-* / test / debug)."
echo ""
echo "Legacy /agent jsonui-orchestrator is still available during"
echo "the transition period but deprecated. Prefer /agent conductor."
echo ""
echo "========================================"
echo ""
echo "IMPORTANT: Please restart your Codex CLI session"
echo "to load the newly installed agents and skills."
echo ""
echo "========================================"
