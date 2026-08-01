#!/usr/bin/env python3
"""contract_check.py — Codex-side contract checks for the agent pack.

Mirror of the Claude repo's scripts/contract_check.sh, adapted to the TOML
packaging (keep the two in sync when changing check logic):

  1. agents/*.toml: allowed_tools is a superset of every mcp__jui-tools__*
     tool referenced in developer_instructions.
  2. `/agent <name>` references resolve to agents/<name>.toml (family stems
     like `navigation` are accepted when agents/navigation-*.toml exist),
     and unadapted Claude-form agent names (jsonui-define, ...) do not
     appear in adapted files (agents/, rules/, AGENTS.md). Skills are
     verbatim mirrors governed by the Claude-side check, so they are only
     covered by check 3.
  3. skills/*/SKILL.md example references exist on disk.
  4. The per-agent inventory table in rules/mcp-policy.md matches the
     agents' allowed_tools (the table is generated — allowed_tools is
     canonical).

Usage:
  scripts/contract_check.py          # verify (CI mode)
  scripts/contract_check.py --fix    # also regenerate the inventory table
"""
import re
import sys
import tomllib
from pathlib import Path

args = [a for a in sys.argv[1:]]
FIX = "--fix" in args
roots = [a for a in args if a != "--fix"]
ROOT = Path(roots[0]).resolve() if roots else Path(__file__).resolve().parent.parent

fail = False


def err(msg):
    global fail
    fail = True
    print(f"FAIL {msg}", file=sys.stderr)


agent_files = sorted((ROOT / "agents").glob("*.toml"))
agents = {}
for p in agent_files:
    with open(p, "rb") as f:
        agents[p] = tomllib.load(f)
names = {p.stem for p in agent_files}

# ---- 1. allowed_tools superset of body-referenced MCP tools --------------
for p, data in agents.items():
    body = data.get("developer_instructions", "")
    allowed = set(data.get("allowed_tools", []))
    for tool in sorted(set(re.findall(r"mcp__jui-tools__[a-z_]+", body))):
        if tool not in allowed:
            err(f"agents/{p.name}: body uses {tool} but allowed_tools lacks it")

# ---- 2. agent references resolve + no unadapted Claude forms -------------
CLAUDE_FORMS = {f"jsonui-{n}" for n in names} | {
    "jsonui-navigation",
    "jsonui-screen-impl",
    "jsonui-modify",
    "jsonui-setup",
    "jsonui-spec",
}
CLAUDE_FORMS.discard("jsonui-test")  # jsonui-test is the CLI name, legit everywhere

scan = {p: agents[p].get("developer_instructions", "") for p in agent_files}
for p in sorted((ROOT / "rules").glob("*.md")) + [ROOT / "AGENTS.md"]:
    scan[p] = p.read_text(encoding="utf-8")

for p, text in scan.items():
    rel = p.name if p.suffix == ".toml" else p.relative_to(ROOT)
    for m in sorted(set(re.findall(r"/agent ([a-z]+(?:-[a-z]+)*)", text))):
        if m in names or any(n.startswith(m + "-") for n in names):
            continue
        err(f"{rel}: `/agent {m}` resolves to no agents/*.toml")
    for tok in sorted(set(re.findall(r"(?<![a-z])jsonui-[a-z]+(?:-[a-z]+)*", text))):
        if any(tok == c or tok.startswith(c + "-") for c in CLAUDE_FORMS):
            err(f"{rel}: unadapted Claude-form agent reference `{tok}` (use /agent form)")

# ---- 3. SKILL.md example references exist on disk ------------------------
for s in sorted(ROOT.glob("skills/*/SKILL.md")):
    text = s.read_text(encoding="utf-8")
    for ref in sorted(set(re.findall(r"skills/[a-z-]+/examples/[A-Za-z0-9._-]*[A-Za-z0-9_-]", text))):
        if not (ROOT / ref).is_file():
            err(f"{s.relative_to(ROOT)}: references {ref} — not on disk")
    for ref in sorted(set(re.findall(r"(?<![/a-z])examples/[A-Za-z0-9._-]*[A-Za-z0-9_-]", text))):
        if not (s.parent / ref).is_file():
            err(f"{s.relative_to(ROOT)}: references {ref} — missing in {s.parent.name}/")

# ---- 4. per-agent inventory table in rules/mcp-policy.md -----------------
POLICY = ROOT / "rules" / "mcp-policy.md"
BEGIN = "<!-- inventory:begin — generated from agent allowed_tools; edit the agent .toml, then run scripts/contract_check.py --fix -->"
END = "<!-- inventory:end -->"


def gen_inventory():
    lines = [BEGIN, "| Agent | MCP tools |", "|---|---|"]
    for p in agent_files:
        tools = sorted(
            t.removeprefix("mcp__jui-tools__")
            for t in agents[p].get("allowed_tools", [])
            if t.startswith("mcp__jui-tools__")
        )
        cell = ", ".join(f"`{t}`" for t in tools) if tools else "—"
        lines.append(f"| `{p.stem}` | {cell} |")
    lines.append(END)
    return "\n".join(lines)


policy_text = POLICY.read_text(encoding="utf-8")
m = re.search(r"<!-- inventory:begin.*?<!-- inventory:end -->", policy_text, re.DOTALL)
if not m:
    err(f"rules/mcp-policy.md: inventory markers missing (<!-- inventory:begin/end -->)")
else:
    expected = gen_inventory()
    if m.group(0) != expected:
        if FIX:
            POLICY.write_text(policy_text[: m.start()] + expected + policy_text[m.end():], encoding="utf-8")
            print("regenerated: rules/mcp-policy.md inventory table")
        else:
            err("rules/mcp-policy.md: inventory table does not match allowed_tools — run scripts/contract_check.py --fix")

if fail:
    print("contract check: FAILED", file=sys.stderr)
    sys.exit(1)
print("contract check: OK")
