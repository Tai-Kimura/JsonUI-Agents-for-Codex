#!/bin/bash

# JsonUI Agents Installer for Codex CLI
# This script installs JsonUI agents and skills to Codex CLI's directories
#
# The pack is fetched as a single tarball and its contents are enumerated
# from disk, so new files (agents, skills, examples, rules) ship without
# touching this script.
#
# Usage:
#   ./install.sh                    # Install from main branch
#   ./install.sh -b develop         # Install from specific branch
#   ./install.sh -c abc123          # Install from specific commit
#   ./install.sh -v 1.0.0           # Install from specific version tag
#
# Testing: set JSONUI_AGENTS_TARBALL_URL to any curl-able tarball URL
# (e.g. file:///tmp/pack.tar.gz built with `git archive --prefix=x/ HEAD`).

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

TARBALL_URL="${JSONUI_AGENTS_TARBALL_URL:-https://codeload.github.com/Tai-Kimura/JsonUI-Agents-for-Codex/tar.gz/$REF}"
CODEX_DIR=".codex"
AGENTS_DIR="agents"
SKILLS_DIR="skills"
RULES_DIR="rules"

echo "Installing JsonUI Agents for Codex CLI..."
echo "  Source: $REF_TYPE '$REF'"

# Fetch the pack once
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT
echo ""
echo "Fetching the pack tarball..."
if ! curl -sLf "$TARBALL_URL" -o "$TMP_DIR/pack.tar.gz"; then
    echo "Error: Failed to download the pack ($TARBALL_URL)." >&2
    echo "Please check if the $REF_TYPE '$REF' exists." >&2
    exit 1
fi
mkdir "$TMP_DIR/src"
if ! tar -xzf "$TMP_DIR/pack.tar.gz" -C "$TMP_DIR/src" --strip-components=1; then
    echo "Error: Failed to extract the pack tarball." >&2
    exit 1
fi
SRC="$TMP_DIR/src"

# Sanity-check the pack layout before writing anything
for d in "$SRC/agents" "$SRC/skills" "$SRC/rules"; do
    if [ ! -d "$d" ]; then
        echo "Error: unexpected pack layout — missing ${d#"$SRC"/}" >&2
        exit 1
    fi
done
for f in "$SRC/.codex/config.toml" "$SRC/AGENTS.md"; do
    if [ ! -f "$f" ]; then
        echo "Error: unexpected pack layout — missing ${f#"$SRC"/}" >&2
        exit 1
    fi
done

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
example_count=0
rule_count=0

# Install config.toml
echo ""
echo "Installing Codex configuration..."
echo "  - .codex/config.toml"
cp "$SRC/.codex/config.toml" "$CODEX_DIR/config.toml"

# Install agent config files (enumerated from the pack)
echo ""
echo "Installing agent configurations..."
for file in "$SRC"/agents/*.toml; do
    name=$(basename "$file")
    echo "  - agents/$name"
    cp "$file" "$AGENTS_DIR/$name"
    agent_count=$((agent_count + 1))
done

# Install skills (each skill directory ships wholesale — SKILL.md, examples/,
# and whatever the pack adds later)
echo ""
echo "Installing skills..."
for sdir in "$SRC"/skills/*/; do
    skill=$(basename "$sdir")
    echo "  - skills/$skill/"
    mkdir -p "$SKILLS_DIR/$skill"
    cp -R "${sdir}." "$SKILLS_DIR/$skill/"
    skill_count=$((skill_count + 1))
    if [ -d "${sdir}examples" ]; then
        n=$(find "${sdir}examples" -type f | wc -l | tr -d ' ')
        example_count=$((example_count + n))
    fi
done

# Install rule files (enumerated from the pack)
echo ""
echo "Installing rules..."
for file in "$SRC"/rules/*.md; do
    name=$(basename "$file")
    echo "  - rules/$name"
    cp "$file" "$RULES_DIR/$name"
    rule_count=$((rule_count + 1))
done

# Install AGENTS.md to project root
echo ""
echo "Installing AGENTS.md..."
cp "$SRC/AGENTS.md" "AGENTS.md"
echo "  - AGENTS.md (project root)"

echo ""
echo "Installation complete!"
echo ""
echo "Installed:"
echo "  Agent configs: $agent_count"
echo "  Skills: $skill_count (with $example_count example files)"
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
echo "========================================"
echo ""
echo "IMPORTANT: Please restart your Codex CLI session"
echo "to load the newly installed agents and skills."
echo ""
echo "========================================"
