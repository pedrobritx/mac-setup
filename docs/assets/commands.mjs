// Copy-ready Terminal commands. Everything returned here reaches the clipboard
// verbatim, so each command is exactly one line: a newline pasted into Terminal
// runs a partial command and breaks the rest.

export const LAUNCH_COMMAND =
  "curl -fsSL https://raw.githubusercontent.com/pedrobritx/mac-setup/main/bootstrap.sh | bash -s -- --web";

// Homebrew names: lower-case tokens, optionally tap-qualified (user/repo/name).
const PACKAGE = /^[a-z0-9][a-z0-9+@._-]*(?:\/[a-z0-9][a-z0-9+@._-]*){0,2}$/;
const APP_STORE_ID = /^[0-9]+$/;

/** Collapse any whitespace, including line breaks, into single spaces. */
export function oneLine(text) {
  return String(text).replace(/\s+/g, " ").trim();
}

/**
 * Plain Homebrew commands for the selected catalogue items, in Brewfile order.
 * Only allowlisted catalogue tokens are emitted; anything else is reported as
 * not covered, so the guided setup remains the path for preferences, setup
 * steps, connections and manual installs.
 */
export function homebrewCommands(catalog, selection) {
  const chosen = catalog.items.filter((item) => selection.has(item.id));
  const formulae = [];
  const casks = [];
  const appStore = [];
  const notIncluded = [];
  for (const item of chosen) {
    if (item.locked) continue; // Command Line Tools and Homebrew: prerequisites.
    const list =
      item.type === "brew" && PACKAGE.test(item.token)
        ? formulae
        : item.type === "cask" && PACKAGE.test(item.token)
          ? casks
          : item.type === "mas" && APP_STORE_ID.test(item.token)
            ? appStore
            : null;
    if (!list) notIncluded.push(item);
    else if (!list.some((entry) => entry.token === item.token)) list.push(item);
  }
  const names = (items) => items.map((item) => item.token).join(" ");
  // `;` keeps the groups independent: a formula failure must not skip the apps.
  const command = [
    formulae.length ? `brew install --formula ${names(formulae)}` : "",
    casks.length ? `brew install --cask ${names(casks)}` : "",
  ]
    .filter(Boolean)
    .join("; ");
  return {
    formulae,
    casks,
    appStore,
    notIncluded,
    command,
    appStoreCommand: appStore.length ? `mas get ${names(appStore)}` : "",
  };
}
