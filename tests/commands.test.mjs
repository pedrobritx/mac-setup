import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  LAUNCH_COMMAND,
  homebrewCommands,
  oneLine,
} from "../docs/assets/commands.mjs";
import {
  profileSelection,
  toggleSelection,
} from "../docs/assets/selection.mjs";

const catalog = JSON.parse(
  readFileSync(new URL("../docs/assets/catalog.json", import.meta.url)),
);

test("the launch command is one line and matches the page and launcher", () => {
  assert.doesNotMatch(LAUNCH_COMMAND, /[\r\n]/);
  assert.equal(oneLine(LAUNCH_COMMAND), LAUNCH_COMMAND);
  const page = readFileSync(
    new URL("../docs/index.html", import.meta.url),
    "utf8",
  );
  const fallback = page.match(/<code id="launch-command"[^>]*>([^<]*)<\/code/);
  assert.ok(fallback, "launch command element missing");
  assert.equal(fallback[1], LAUNCH_COMMAND, "page fallback must be one line");
  const bootstrap = readFileSync(
    new URL("../bootstrap.sh", import.meta.url),
    "utf8",
  );
  assert.ok(bootstrap.includes('"--web"'), "bootstrap.sh must accept --web");
});

test("oneLine removes line breaks a wrapped command would carry", () => {
  assert.equal(
    oneLine("curl -fsSL\n      https://example.test/x.sh\n      | bash"),
    "curl -fsSL https://example.test/x.sh | bash",
  );
});

test("Essentials becomes formula, cask and App Store commands in Brewfile order", () => {
  const result = homebrewCommands(
    catalog,
    profileSelection(catalog, "essentials"),
  );
  assert.equal(
    result.command,
    "brew install --formula mas; brew install --cask google-chrome appcleaner 1password vlc",
  );
  assert.equal(result.appStoreCommand, "mas get 425424353");
  assert.deepEqual(result.notIncluded, []);
});

test("every catalogue package token is emitted as a safe single-line argument", () => {
  const everything = new Set(catalog.items.map((item) => item.id));
  const result = homebrewCommands(catalog, everything);
  const packages = catalog.items.filter((item) =>
    ["brew", "cask", "mas"].includes(item.type),
  );
  assert.equal(
    result.formulae.length + result.casks.length + result.appStore.length,
    packages.length,
  );
  for (const command of [result.command, result.appStoreCommand]) {
    assert.doesNotMatch(command, /[\r\n]/);
    assert.match(command, /^[a-z0-9 ;@+./_-]+$/);
  }
  assert.ok(result.command.includes("oven-sh/bun/bun"), "tap-qualified name");
  assert.deepEqual(
    [...new Set(result.notIncluded.map((item) => item.type))].sort(),
    ["manual", "mcp", "pref", "step", "web"],
  );
  assert.ok(!result.notIncluded.some((item) => item.locked));
});

test("non-Homebrew choices are listed instead of emitted", () => {
  const selection = new Set(["step:git", "mcp:figma", "pref:macos:finder"]);
  const result = homebrewCommands(catalog, selection);
  assert.equal(result.command, "");
  assert.equal(result.appStoreCommand, "");
  assert.deepEqual(
    result.notIncluded.map((item) => item.id),
    catalog.items
      .filter((item) => selection.has(item.id))
      .map((item) => item.id),
  );
});

test("an unexpected token is reported, never placed in a command", () => {
  const hostile = {
    items: [
      { id: "cask:ok", type: "cask", token: "ok", locked: false },
      { id: "cask:bad", type: "cask", token: "x; rm -rf ~", locked: false },
      { id: "mas:bad", type: "mas", token: "12 && echo", locked: false },
    ],
  };
  const result = homebrewCommands(
    hostile,
    new Set(hostile.items.map((item) => item.id)),
  );
  assert.equal(result.command, "brew install --cask ok");
  assert.equal(result.appStoreCommand, "");
  assert.deepEqual(
    result.notIncluded.map((item) => item.id),
    ["cask:bad", "mas:bad"],
  );
});

test("removing a choice removes it from the command", () => {
  const selection = toggleSelection(
    catalog,
    profileSelection(catalog, "essentials"),
    "cask:vlc",
    false,
  );
  assert.doesNotMatch(homebrewCommands(catalog, selection).command, /\bvlc\b/);
});
