// Pure selection rules. Executable package arguments remain in the Brewfile.
export function requiredSelection(catalog) {
  return new Set(
    catalog.items.filter((item) => item.locked).map((item) => item.id),
  );
}

export function withDependencies(catalog, selection) {
  const next = new Set([...requiredSelection(catalog), ...selection]);
  const items = new Map(catalog.items.map((item) => [item.id, item]));
  for (const id of next) {
    const item = items.get(id);
    if (!item)
      throw new Error(
        "This plan contains an item outside the current catalogue.",
      );
    for (const dependency of item.dependencies) next.add(dependency);
  }
  return next;
}

export function profileSelection(catalog, profile) {
  return withDependencies(
    catalog,
    catalog.items
      .filter((item) => item.profiles.includes(profile))
      .map((item) => item.id),
  );
}

export function toggleSelection(catalog, selection, id, enabled) {
  if (enabled) return withDependencies(catalog, [...selection, id]);
  const item = catalog.items.find((entry) => entry.id === id);
  if (!item || item.locked) return new Set(selection);
  const next = new Set(selection);
  next.delete(id);
  let changed = true;
  while (changed) {
    changed = false;
    for (const entry of catalog.items) {
      if (
        next.has(entry.id) &&
        entry.dependencies.some((dependency) => !next.has(dependency))
      ) {
        next.delete(entry.id);
        changed = true;
      }
    }
  }
  return next;
}

// Category actions select the entire category, independent of display filters.
export function selectCategory(catalog, selection, category) {
  if (!catalog.categories.some((entry) => entry.id === category))
    throw new Error("Choose a category from the current catalogue.");
  return withDependencies(catalog, [
    ...selection,
    ...catalog.items
      .filter((item) => item.category === category)
      .map((item) => item.id),
  ]);
}

export function createPlan(catalog, profile, selection) {
  return {
    schema: 1,
    catalogVersion: catalog.version,
    profile,
    selected: catalog.items
      .filter((item) => selection.has(item.id))
      .map((item) => item.id),
  };
}

export function importPlan(catalog, plan) {
  if (
    !plan ||
    plan.schema !== 1 ||
    !Array.isArray(plan.selected) ||
    plan.selected.some((id) => typeof id !== "string") ||
    !catalog.profiles.some((profile) => profile.id === plan.profile)
  ) {
    throw new Error(
      "Choose a mac-setup JSON plan exported from this catalogue.",
    );
  }
  const keys = new Set(catalog.items.map((item) => item.id));
  const removed = plan.selected.filter((id) => !keys.has(id));
  return {
    profile: plan.profile,
    selected: withDependencies(
      catalog,
      plan.selected.filter((id) => keys.has(id)),
    ),
    changed: plan.catalogVersion !== catalog.version || removed.length > 0,
  };
}

export function selectionCounts(catalog, selection) {
  const items = catalog.items.filter((item) => selection.has(item.id));
  const preferences = items.filter(
    (item) =>
      (item.type === "pref" && item.id !== "pref:xcode:full_xcode") ||
      item.id === "step:directories",
  ).length;
  const connections = items.filter((item) => item.type === "mcp").length;
  return {
    apps: items.length - preferences - connections,
    preferences,
    connections,
    total: items.length,
  };
}
