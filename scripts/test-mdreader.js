// Regression test for mdreader.html's link path resolver. Run: node scripts/test-mdreader.js
const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");

const html = fs.readFileSync(path.join(__dirname, "mdreader.html"), "utf8");
const m = html.match(/function resolvePath[\s\S]*?\n}/);
assert.ok(m, "resolvePath not found in mdreader.html");
const resolvePath = new Function(m[0] + ";return resolvePath")();

const cases = [
  ["a/b/c.md", "d.md",          "a/b/d.md"],
  ["a/b/c.md", "./d.md",        "a/b/d.md"],
  ["a/b/c.md", "../d.md",       "a/d.md"],
  ["a/b/c.md", "../../d.md",    "d.md"],
  ["a/b/c.md", "/x/d.md",       "x/d.md"],
  ["a/b/c.md", "../x/y/d.md",   "a/x/y/d.md"],
];
for (const [base, href, want] of cases)
  assert.strictEqual(resolvePath(base, href), want, `${base} + ${href}`);

console.log(`${cases.length}/${cases.length} resolvePath OK`);
