import test from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import {
  profileSelection,
  toggleSelection,
  selectCategory,
  createPlan,
  importPlan,
  requiredSelection,
} from "../docs/assets/selection.mjs";
const catalog = JSON.parse(
  readFileSync(new URL("../docs/assets/catalog.json", import.meta.url)),
);

test("every starting profile includes required tools and all declared prerequisites", () => {
  for (const profile of catalog.profiles) {
    const selected = profileSelection(catalog, profile.id);
    for (const id of requiredSelection(catalog)) assert.ok(selected.has(id));
    for (const item of catalog.items.filter((item) => selected.has(item.id))) {
      for (const dependency of item.dependencies)
        assert.ok(selected.has(dependency), `${profile.name}: ${item.name}`);
    }
  }
});
test("Essentials stays light and excludes paid apps, MCP permissions and personal Git setup", () => {
  const selected = profileSelection(catalog, "essentials");
  assert.ok(selected.size < 15);
  assert.ok(!selected.has("step:git"));
  assert.ok(
    !catalog.items.some(
      (item) => selected.has(item.id) && (item.paid || item.type === "mcp"),
    ),
  );
});
test("BRITX Choice includes the requested personal stack and optional Apple creative apps", () => {
  const selected = profileSelection(catalog, "britx");
  for (const id of [
    "cask:1password",
    "cask:claude-code",
    "pref:terminal:ohmyzsh",
    "mas:571213070",
    "mas:634148309",
    "mas:434290957",
    "mas:1444636541",
    "mcp:vercel",
    "mcp:supabase",
    "mcp:railway",
    "mcp:stripe",
  ])
    assert.ok(selected.has(id), id);
});
test("adding Python selects its runtime managers; removing uv removes Python setup", () => {
  const selected = toggleSelection(
    catalog,
    requiredSelection(catalog),
    "step:python",
    true,
  );
  assert.ok(selected.has("brew:uv"));
  assert.ok(selected.has("brew:pipx"));
  const removed = toggleSelection(catalog, selected, "brew:uv", false);
  assert.ok(!removed.has("step:python"));
  assert.ok(!removed.has("brew:uv"));
});
test("required tools cannot be removed", () => {
  const selected = requiredSelection(catalog);
  assert.deepEqual(
    toggleSelection(catalog, selected, "step:brew", false),
    selected,
  );
});
test("App Store selections pull in mas and remain one source per app", () => {
  const selected = toggleSelection(
    catalog,
    requiredSelection(catalog),
    "mas:803453959",
    true,
  );
  assert.ok(selected.has("brew:mas"));
  assert.ok(!catalog.items.some((item) => item.id === "cask:slack"));
  assert.ok(!catalog.items.some((item) => item.id === "cask:onedrive"));
});
test("export and import preserve exact custom selections and contain no identity or commands", () => {
  const selected = toggleSelection(
    catalog,
    profileSelection(catalog, "developer"),
    "cask:docker-desktop",
    false,
  );
  const plan = createPlan(catalog, "developer", selected);
  assert.deepEqual(Object.keys(plan), [
    "schema",
    "catalogVersion",
    "profile",
    "selected",
  ]);
  assert.deepEqual(importPlan(catalog, plan).selected, selected);
});
test("older plans carry only available choices and require another review", () => {
  const result = importPlan(catalog, {
    schema: 1,
    catalogVersion: "old",
    profile: "creative",
    selected: ["cask:blender", "unknown:item"],
  });
  assert.equal(result.changed, true);
  assert.ok(result.selected.has("cask:blender"));
  assert.ok(!result.selected.has("unknown:item"));
});
test("malformed imported plans are rejected", () => {
  for (const value of [
    null,
    {},
    { schema: 1, profile: "essentials", selected: [{}] },
    { schema: 1, profile: "invalid", selected: [] },
  ])
    assert.throws(() => importPlan(catalog, value));
});

test("selecting a whole category preserves other choices and closes all prerequisites", () => {
  const before = profileSelection(catalog, "essentials");
  const selected = selectCategory(catalog, before, "development");
  for (const id of before) assert.ok(selected.has(id));
  for (const item of catalog.items.filter(
    (item) => item.category === "development",
  ))
    assert.ok(selected.has(item.id), item.name);
  for (const item of catalog.items.filter((item) => selected.has(item.id)))
    for (const dependency of item.dependencies)
      assert.ok(selected.has(dependency), item.name);
  assert.equal(before.size, profileSelection(catalog, "essentials").size);
  assert.deepEqual(selectCategory(catalog, selected, "development"), selected);
  assert.throws(() => selectCategory(catalog, before, "unknown"));
});
