#!/usr/bin/env node
// Regenerates the action/assertion tables in the two test skills from the
// canonical step inventory — jsonui-test-runner's schemas/actions.schema.json,
// consumed through that repo's own `gen-action-tables.mjs --json` dump so the
// extraction rules (x-doc required, COMMON attrs excluded, defaults resolved)
// live in exactly one place. The tables used to be maintained by hand here and
// drifted (22 documented vs 28 defined actions); after this script, a step
// exists in the skills iff it exists in the schema at the pin below.
//
//   node scripts/gen-skill-action-tables.mjs           check (exit 1 on drift)
//   node scripts/gen-skill-action-tables.mjs --fix     rewrite the blocks
//
// (check-by-default matches scripts/contract_check.sh; the test-runner's own
// generator rewrites by default — don't confuse the two.)
//
// PIN BUMP PROCEDURE: pick the new jsonui-test-runner main SHA, replace PIN,
// run `--fix`, and review the table diff — the pin bump IS the review point
// for step-inventory updates. The pin is stamped into each generated block so
// a reader of SKILL.md can see which inventory version they are looking at.
//
// Input resolution:
//   1. env JSONUI_TEST_RUNNER_PATH — a local jsonui-test-runner checkout;
//      runs its scripts/gen-action-tables.mjs --json directly (dev preview of
//      an unpushed schema; the stamp then records the checkout's HEAD).
//   2. default — fetch schemas/actions.schema.json + scripts/gen-action-tables.mjs
//      from raw.githubusercontent.com at PIN into a temp mirror and run that.
//
// This file is mirrored verbatim into JsonUI-Agents-for-Codex/scripts/ — the
// skills live at the same relative path there, so keep everything repo-root
// relative and free of Claude-specific paths.

import { execFileSync } from "node:child_process";
import { mkdtempSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const PIN = "v1.10.0"; // jsonui-test-runner release tag (drivers web 1.8.2 / android 1.8.3 / ios 1.9.2), 28 actions + 10 assertions
const REPO = "Tai-Kimura/jsonui-test-runner";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const TARGETS = [
  join(ROOT, "skills", "jsonui-screen-test", "SKILL.md"),
  join(ROOT, "skills", "jsonui-flow-test", "SKILL.md"),
];

async function loadInventory() {
  const local = process.env.JSONUI_TEST_RUNNER_PATH;
  if (local) {
    const out = execFileSync(
      "node", [join(local, "scripts", "gen-action-tables.mjs"), "--json"],
      { encoding: "utf8" },
    );
    let ref = "local-checkout";
    try {
      ref = execFileSync("git", ["-C", local, "rev-parse", "HEAD"], { encoding: "utf8" }).trim();
    } catch { /* not a git checkout — keep the placeholder ref */ }
    return { data: JSON.parse(out), ref };
  }

  const tmp = mkdtempSync(join(tmpdir(), "jsonui-action-tables-"));
  try {
    mkdirSync(join(tmp, "scripts"));
    mkdirSync(join(tmp, "schemas"));
    for (const rel of ["scripts/gen-action-tables.mjs", "schemas/actions.schema.json"]) {
      const url = `https://raw.githubusercontent.com/${REPO}/${PIN}/${rel}`;
      const res = await fetch(url);
      if (!res.ok) throw new Error(`fetch failed (${res.status}): ${url}`);
      writeFileSync(join(tmp, rel), await res.text());
    }
    const out = execFileSync(
      "node", [join(tmp, "scripts", "gen-action-tables.mjs"), "--json"],
      { encoding: "utf8" },
    );
    return { data: JSON.parse(out), ref: PIN };
  } finally {
    rmSync(tmp, { recursive: true, force: true });
  }
}

function paramList(params, required) {
  const cell = params
    .filter((p) => p.required === required)
    .map((p) => `\`${p.name}${p.default !== undefined ? `=${p.default}` : ""}\``)
    .join(", ");
  return cell || "-";
}

function table(discriminator, rows) {
  const lines = [
    `| ${discriminator} | 説明 | Required | Optional | Platform notes |`,
    "|---|---|---|---|---|",
  ];
  for (const s of rows) {
    lines.push(
      `| \`${s.name}\` | ${s.ja} | ${paramList(s.params, true)} | ${paramList(s.params, false)} | ${s.platforms ?? "-"} |`,
    );
  }
  return lines.join("\n");
}

function stamp(ref, counts) {
  const short = ref.slice(0, 7);
  return (
    `_Generated from [\`schemas/actions.schema.json\`](https://github.com/${REPO}/blob/${ref}/schemas/actions.schema.json) ` +
    `@ jsonui-test-runner \`${short}\` (${counts}). Do not edit by hand — ` +
    `\`node scripts/gen-skill-action-tables.mjs --fix\` regenerates; the pin lives in that script._`
  );
}

const { data, ref } = await loadInventory();
const blocks = {
  actions: `${stamp(ref, `${data.actions.length} actions`)}\n\n${table("Action", data.actions)}`,
  assertions: `${stamp(ref, `${data.assertions.length} assertions`)}\n\n${table("Assertion", data.assertions)}`,
};

const fix = process.argv.includes("--fix");
const stale = [];
for (const path of TARGETS) {
  const before = readFileSync(path, "utf8");
  let after = before;
  for (const [kind, body] of Object.entries(blocks)) {
    const re = new RegExp(`(<!-- generated:${kind} -->\\n)[\\s\\S]*?(<!-- /generated:${kind} -->)`);
    if (!re.test(after)) throw new Error(`${path}: marker pair for "${kind}" not found`);
    // function replacer — body may contain `$`, which string replacements
    // would interpret as substitution patterns
    after = after.replace(re, (_m, open, close) => `${open}${body}\n${close}`);
  }
  if (after !== before) {
    if (fix) {
      writeFileSync(path, after);
      console.log(`updated ${path}`);
    } else {
      stale.push(path);
    }
  }
}

if (stale.length > 0) {
  console.error(
    `stale generated skill tables (run \`node scripts/gen-skill-action-tables.mjs --fix\`):\n  ${stale.join("\n  ")}`,
  );
  process.exit(1);
}
console.log(
  `skill action tables ${fix ? "written" : "up to date"} ` +
  `(${data.actions.length} actions, ${data.assertions.length} assertions @ ${ref.slice(0, 7)})`,
);
