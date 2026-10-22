import {
  requiredSelection,
  profileSelection,
  toggleSelection,
  selectCategory,
  createPlan,
  importPlan,
  selectionCounts,
} from "./selection.mjs";
import { setupSiteChrome } from "./site.mjs";
import { icon } from "./icons.mjs";
import { createSourcePicker } from "./source-picker.mjs";
import { requestTranslation, translate } from "./i18n.mjs";
import { APP_ICONS } from "./app-icons.mjs";

const $ = (id) => document.getElementById(id);
const STORAGE_KEY = "mac-setup.plan.v1";
const MODULE_NAMES = {
  xcode: "Command Line Tools & Apple tooling",
  brew: "Homebrew & packages",
  directories: "Workspace folders",
  apps: "Application checks",
  mas: "Mac App Store",
  ssh: "SSH key",
  git: "Git configuration",
  terminal: "Terminal & shell",
  node: "Node.js",
  python: "Python",
  swift: "Swift extras",
  vscode: "VS Code configuration",
  macos: "Mac preferences",
  security: "Security preferences",
  verification: "Verification",
};
const MODULE_DETAILS = {
  xcode: ["terminal", "Prepare Apple’s developer tools"],
  brew: ["layers", "Install Homebrew and selected packages"],
  directories: ["layers", "Prepare your workspace folders"],
  apps: ["laptop", "Check the selected applications"],
  mas: ["laptop", "Install selected App Store apps"],
  ssh: ["shield", "Preserve existing keys; create only if needed"],
  git: ["code", "Apply your Git configuration"],
  terminal: ["terminal", "Configure your shell and selected helpers"],
  node: ["code", "Prepare the selected Node.js toolchain"],
  python: ["code", "Prepare managed Python and CLI tools"],
  swift: ["code", "Check selected Swift tools"],
  vscode: ["code", "Apply editor settings and extensions"],
  macos: ["settings", "Apply your selected Mac preferences"],
  security: ["shield", "Apply your selected security preferences"],
  verification: ["shield", "Check the setup and finish your report"],
};
const PRIORITY = [
  "cask:visual-studio-code",
  "cask:github",
  "cask:docker-desktop",
  "cask:postman",
  "step:node",
  "step:python",
  "cask:chatgpt",
  "cask:claude-code",
  "cask:figma",
  "cask:blender",
  "cask:inkscape",
  "cask:antigravity",
  "cask:google-chrome",
  "cask:notion",
];
let catalog;
let selected = new Set();
let profile = "essentials";
let category = "all";
let selectedOnly = false;
let session = null;
let token = "";
let pollTimer;
let followupSignature = "";
let lastRunStatus = "";
let starting = false;
let liquid;
let sourcePicker;

function element(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text !== undefined) node.textContent = text;
  return node;
}
function logo(item) {
  const node = element("span", "app-logo");
  node.setAttribute("aria-hidden", "true");
  const fallback = () => {
    node.classList.remove("has-brand-icon", "has-vector-icon");
    node.replaceChildren(
      icon(
        item.type === "pref"
          ? "settings"
          : item.type === "mcp"
            ? "plug"
            : catalog.categories.find((group) => group.id === item.category)
                ?.icon || "terminal",
      ),
    );
  };
  const asset = APP_ICONS[item.id];
  if (asset) {
    const image = element("img");
    image.src = new URL(asset, import.meta.url).href;
    image.alt = "";
    image.width = 36;
    image.height = 36;
    image.loading = "lazy";
    image.decoding = "async";
    image.addEventListener("error", fallback, { once: true });
    node.classList.add("has-brand-icon");
    if (asset.endsWith(".svg")) node.classList.add("has-vector-icon");
    node.append(image);
  } else fallback();
  if (item.color) node.style.setProperty("--app-color", item.color);
  return node;
}
function source(item) {
  if (item.methodLabel) return item.methodLabel;
  return {
    brew: "Homebrew",
    cask: "Homebrew",
    mas: "App Store",
    pref: "Preference",
    step: "Setup step",
    manual: "Guided",
    web: "Web app",
    mcp: "MCP guide",
  }[item.type];
}
function sortedItems() {
  return [...catalog.items].sort((a, b) => {
    const rank = (item) =>
      PRIORITY.includes(item.id) ? PRIORITY.indexOf(item.id) : 1000;
    return rank(a) - rank(b);
  });
}
function announce(message) {
  requestTranslation();
  $("announcement").textContent = message;
}
function showError(message) {
  requestTranslation();
  $("app-error").textContent = message;
  $("app-error").hidden = false;
}
function persist() {
  try {
    localStorage.setItem(
      STORAGE_KEY,
      JSON.stringify(createPlan(catalog, profile, selected)),
    );
  } catch {
    announce(
      "Your choices work for this visit. Browser storage is unavailable.",
    );
  }
}
function changeItem(id, enabled) {
  const before = selected.size;
  selected = toggleSelection(catalog, selected, id, enabled);
  persist();
  renderSelection();
  renderCatalog();
  const extra = Math.abs(selected.size - before) > 1;
  announce(
    `${selected.size} items selected.${extra ? " Related prerequisites or setup steps were updated too." : ""}`,
  );
}
function resetFilters() {
  category = "all";
  selectedOnly = false;
  $("search").value = "";
  $("source-filter").value = "all";
  sourcePicker.sync();
  $("selected-filter").setAttribute("aria-pressed", "false");
  renderCategories();
  renderCatalog();
}
function renderProfiles() {
  requestTranslation();
  $("profiles").replaceChildren(
    ...catalog.profiles.map((entry) => {
      const label = element("label", "profile-option");
      const input = element("input");
      input.type = "radio";
      input.name = "profile";
      input.value = entry.id;
      input.checked = profile === entry.id;
      input.setAttribute("aria-label", entry.name);
      input.addEventListener("change", () => {
        profile = entry.id;
        selected = profileSelection(catalog, profile);
        persist();
        resetFilters();
        renderSelection();
        liquid.syncRail($("profiles"), ".profile-option:has(input:checked)");
        announce(`${entry.name} applied. Review and change any optional item.`);
      });
      label.append(
        input,
        icon(entry.icon),
        element("span", "profile-name", entry.name),
        element("span", "profile-description", entry.description),
      );
      return label;
    }),
  );
  liquid.syncRail($("profiles"), ".profile-option:has(input:checked)");
}
function renderCategories() {
  requestTranslation();
  const existing = $("categories").querySelectorAll("button");
  if (existing.length) {
    existing.forEach((button) =>
      button.setAttribute(
        "aria-pressed",
        String(button.dataset.category === category),
      ),
    );
    liquid.syncRail($("categories"), '[aria-pressed="true"]');
    return;
  }
  $("categories").replaceChildren(
    ...[
      { id: "all", name: "All items", icon: "all" },
      ...catalog.categories,
    ].map((entry) => {
      const button = element("button", "category-button");
      button.dataset.category = entry.id;
      button.setAttribute("aria-pressed", String(category === entry.id));
      button.append(icon(entry.icon), element("span", "", entry.name));
      button.addEventListener("click", () => {
        category = entry.id;
        renderCategories();
        renderCatalog();
      });
      return button;
    }),
  );
  liquid.syncRail($("categories"), '[aria-pressed="true"]');
}
function showDetails(item, opener) {
  requestTranslation();
  $("dialog-title").textContent = item.name;
  const content = $("dialog-content");
  content.replaceChildren(element("p", "", item.description));
  content.append(
    element(
      "p",
      "",
      `Source: ${source(item)}.${item.locked ? " Required by the installer." : ""}`,
    ),
  );
  if (item.paid || item.purchaseNote)
    content.append(
      element(
        "p",
        "",
        item.paid
          ? "Requires a licence or an existing App Store purchase. mac-setup does not buy apps for you."
          : item.purchaseNote,
      ),
    );
  if (item.architectures)
    content.append(element("p", "", "Requires an Apple Silicon Mac."));
  if (item.dependencies.length) {
    content.append(
      element(
        "p",
        "",
        `Selecting this also selects: ${item.dependencies.map((id) => catalog.items.find((i) => i.id === id).name).join(", ")}. Removing a prerequisite removes its related setup step.`,
      ),
    );
  }
  if (item.type === "mcp") {
    content.append(
      element(
        "p",
        "",
        "This creates a guided follow-up. Open the official instructions in your chosen agent, review access, and authenticate yourself. No tokens or agent configuration files are written automatically.",
      ),
    );
    if (item.endpoint) content.append(element("code", "", item.endpoint));
  }
  if (item.type === "web")
    content.append(
      element(
        "p",
        "",
        "No desktop package is installed. Your completion checklist includes a link to the browser app.",
      ),
    );
  if (item.id === "pref:xcode:full_xcode")
    content.append(
      element(
        "p",
        "",
        "Xcode is a large optional download. Its setup includes Apple’s developer tools licence and first-launch configuration.",
      ),
    );
  if (item.url) content.append(officialLink(item.url, "View official source"));
  liquid.openDialog(opener);
}
function syncCategoryActions() {
  for (const button of $("catalog").querySelectorAll(
    "[data-select-category]",
  )) {
    const allSelected = catalog.items
      .filter((item) => item.category === button.dataset.selectCategory)
      .every((item) => selected.has(item.id));
    // Keep focus on the action after activation, including for keyboard users.
    button.setAttribute("aria-disabled", String(allSelected));
    button.dataset.complete = String(allSelected);
  }
}
function renderCatalog() {
  requestTranslation();
  const focusedId = document.activeElement?.dataset.itemId;
  const focusedCategory = document.activeElement?.dataset.selectCategory;
  const query = $("search").value.trim().toLocaleLowerCase();
  const filter = $("source-filter").value;
  const visible = sortedItems().filter(
    (item) =>
      (category === "all" || item.category === category) &&
      (!selectedOnly || selected.has(item.id)) &&
      (!query ||
        `${item.name} ${item.description} ${translate(item.name)} ${translate(item.description)} ${item.token || ""}`
          .toLocaleLowerCase()
          .includes(query)) &&
      (filter === "all" ||
        (filter === "mas" &&
          (item.type === "mas" || item.methodLabel === "App Store")) ||
        (filter === "homebrew" && ["brew", "cask"].includes(item.type)) ||
        (filter === "guided" && ["manual", "web", "mcp"].includes(item.type))),
  );
  $("result-count").textContent =
    `${visible.length} of ${catalog.items.length} items · ${selected.size} selected`;
  const signature = `${category}|${visible.map((item) => item.id).join("|")}`;
  if ($("catalog").dataset.signature === signature) {
    $("catalog")
      .querySelectorAll("input[data-item-id]")
      .forEach((input) => {
        input.checked = selected.has(input.dataset.itemId);
      });
    syncCategoryActions();
    return;
  }
  const groups = [];
  for (const group of catalog.categories) {
    const items = visible.filter((item) => item.category === group.id);
    if (!items.length) continue;
    const section = element("section", "catalog-group");
    const heading = element("h2", "group-title", group.name);
    heading.append(element("span", "", `(${items.length})`));
    const grid = element("div", "app-grid");
    const displayed = category === "all" && !query ? items.slice(0, 6) : items;
    for (const item of displayed) {
      const row = element("div", "app-row");
      const label = element("label", "app-choice");
      const input = element("input");
      input.type = "checkbox";
      input.checked = selected.has(item.id);
      input.dataset.itemId = item.id;
      input.disabled = item.locked;
      input.setAttribute("aria-label", item.name);
      input.addEventListener("change", () =>
        changeItem(item.id, input.checked),
      );
      const text = element("span", "app-copy");
      text.append(
        element("span", "app-name", item.name),
        element("span", "app-description", item.description),
      );
      text.title = `${item.name}: ${item.description}`;
      const mark = element("span", "choice-mark");
      mark.setAttribute("aria-hidden", "true");
      const check = icon("check");
      const path = check.querySelector("path");
      mark.style.setProperty(
        "--check-len",
        Math.ceil(path.getTotalLength()) + 1,
      );
      mark.append(check);
      label.append(input, mark, logo(item), text);
      const details = element(
        "button",
        "app-source",
        item.locked ? "Required" : source(item),
      );
      details.setAttribute(
        "aria-label",
        `${item.locked ? "Required" : source(item)}${item.paid ? " Paid" : item.purchaseNote ? " In-app" : ""}. About ${item.name}`,
      );
      details.title = `Source and details for ${item.name}`;
      if (item.paid || item.purchaseNote)
        details.append(
          element("span", "source-dot", item.paid ? " Paid" : " In-app"),
        );
      details.addEventListener("click", (event) =>
        showDetails(item, event.currentTarget),
      );
      row.append(label, details);
      grid.append(row);
    }
    section.append(heading, grid);
    const actions = element("div", "group-actions");
    if (displayed.length < items.length) {
      const more = element(
        "button",
        "group-more text-button",
        `View all ${items.length} in ${group.name}`,
      );
      more.addEventListener("click", () => {
        category = group.id;
        renderCategories();
        renderCatalog();
        $("search").focus();
      });
      actions.append(more);
    }
    const selectAll = element(
      "button",
      "text-button group-select",
      `Select all ${group.name}`,
    );
    selectAll.dataset.selectCategory = group.id;
    selectAll.setAttribute("aria-label", `Select all ${group.name}`);
    const wholeCategory = catalog.items.filter(
      (item) => item.category === group.id,
    );
    selectAll.title = `Select all ${wholeCategory.length} items in ${group.name}, including items hidden by filters. Required prerequisites are included.`;
    selectAll.addEventListener("click", () => {
      if (selectAll.getAttribute("aria-disabled") === "true") return;
      selected = selectCategory(catalog, selected, group.id);
      persist();
      renderSelection();
      renderCatalog();
      announce(
        `All ${wholeCategory.length} items in ${group.name} selected. Required prerequisites are included. You can remove individual choices before continuing.`,
      );
    });
    actions.append(selectAll);
    section.append(actions);
    groups.push(section);
  }
  if (!groups.length) {
    const empty = element("div", "empty-state");
    empty.append(
      element("h3", "", "Nothing here yet."),
      element("p", "", "Try another search or show all items."),
    );
    const reset = element("button", "secondary-button", "Reset filters");
    reset.addEventListener("click", resetFilters);
    empty.append(reset);
    groups.push(empty);
  }
  $("catalog").replaceChildren(...groups);
  $("catalog").dataset.signature = signature;
  $("catalog").setAttribute("aria-busy", "false");
  syncCategoryActions();
  liquid.revealCatalog();
  if (focusedCategory) {
    [...$("catalog").querySelectorAll("[data-select-category]")]
      .find((button) => button.dataset.selectCategory === focusedCategory)
      ?.focus({ preventScroll: true });
  }
  if (focusedId) {
    const replacement = [...$("catalog").querySelectorAll("input")].find(
      (input) => input.dataset.itemId === focusedId,
    );
    (replacement || $("selected-filter")).focus({ preventScroll: true });
  }
}
function renderSelection() {
  requestTranslation();
  const focusedChip = [
    ...$("selected-chips").querySelectorAll("button"),
  ].indexOf(document.activeElement);
  const counts = selectionCounts(catalog, selected);
  liquid.updateCount($("apps-count"), counts.apps);
  liquid.updateCount($("preferences-count"), counts.preferences);
  liquid.updateCount($("connections-count"), counts.connections);
  const edited =
    [...profileSelection(catalog, profile)].sort().join("|") !==
    [...selected].sort().join("|");
  $("selected-profile").textContent =
    catalog.profiles.find((p) => p.id === profile).name +
    (edited ? " · edited" : "");
  const apps = sortedItems().filter(
    (item) => selected.has(item.id) && !item.locked,
  );
  $("selection-label").textContent = `Selected items (${counts.total})`;
  $("selected-chips").replaceChildren(
    ...apps.slice(0, 3).map((item) => {
      const chip = element("span", "chip");
      const remove = element("button");
      remove.setAttribute("aria-label", `Remove ${item.name}`);
      remove.append(icon("close"));
      remove.addEventListener("click", () => changeItem(item.id, false));
      chip.append(logo(item), element("span", "", item.name), remove);
      return chip;
    }),
  );
  $("more-count").textContent =
    apps.length > 3
      ? `and ${apps.length - 3} more optional items`
      : "Homebrew and Command Line Tools are required.";
  $("review-button").disabled = false;
  if (focusedChip >= 0) {
    const removals = $("selected-chips").querySelectorAll("button");
    (
      removals[Math.min(focusedChip, removals.length - 1)] || $("review-button")
    ).focus({ preventScroll: true });
  }
}
function setView(view, moveFocus = true) {
  requestTranslation();
  for (const name of ["choose", "review", "guide", "progress"])
    $(`${name}-view`).hidden = name !== view;
  const step = view === "choose" ? 0 : view === "review" ? 1 : 2;
  document.querySelectorAll(".stepper li").forEach((node, index) => {
    node.classList.toggle("complete", index < step);
    if (index === step) node.setAttribute("aria-current", "step");
    else node.removeAttribute("aria-current");
  });
  const titles = {
    choose: [
      "Make this ",
      "Mac yours.",
      "Your apps, your tools, your preferences. One thoughtful setup.",
    ],
    review: [
      "A setup that ",
      "feels like you.",
      "Take one last look. Every choice is still yours.",
    ],
    guide: [
      "Your setup, ",
      "step by step.",
      "A short handoff, then your Mac takes it from here.",
    ],
    progress: [
      "Your setup, ",
      "step by step.",
      "Keep this window and Terminal open. We’ll show what needs your attention.",
    ],
  };
  $("page-title").replaceChildren(
    document.createTextNode(titles[view][0]),
    element("span", "gradient-text", titles[view][1]),
  );
  $("page-description").textContent = titles[view][2];
  $("app-error").hidden = true;
  liquid.revealView($(`${view}-view`));
  if (moveFocus) {
    $("page-title").focus({ preventScroll: true });
    window.scrollTo({
      top: 0,
      behavior:
        document.documentElement.dataset.motion === "reduced"
          ? "instant"
          : "smooth",
    });
  }
}
function renderReview() {
  requestTranslation();
  const items = catalog.items.filter((item) => selected.has(item.id));
  const paid = items.filter((item) => item.paid);
  $("paid-notice").hidden = paid.length === 0;
  $("paid-notice").textContent =
    `Paid apps selected: ${paid.map((i) => i.name).join(", ")}. Have the required purchases or licences ready. mac-setup will not purchase them.`;
  $("review-total").textContent =
    `${items.length} items · ${catalog.profiles.find((p) => p.id === profile).name}`;
  const groups = [];
  for (const group of catalog.categories) {
    const selectedItems = items.filter((item) => item.category === group.id);
    if (!selectedItems.length) continue;
    const details = element("details", "review-group");
    details.open = true;
    const summary = element("summary", "", group.name);
    summary.append(element("span", "", `(${selectedItems.length})`));
    const list = element("ul");
    for (const item of selectedItems) {
      const row = element("li");
      row.append(
        element("strong", "", item.name),
        element(
          "span",
          "",
          `${source(item)}${item.paid ? " · Paid" : ""}${item.locked ? " · Required" : ""}`,
        ),
      );
      list.append(row);
    }
    details.append(summary, list);
    groups.push(details);
    if (
      group.id === "preferences" &&
      selectedItems.some((item) => item.id.startsWith("pref:macos:"))
    ) {
      details.append(
        element(
          "p",
          "preference-note",
          "Mac preferences also restore stock window and animation behaviour where older mac-setup overrides exist. Existing preferences are otherwise applied only for the categories you selected.",
        ),
      );
    }
  }
  $("review-list").replaceChildren(...groups);
  $("confirmation-label").hidden = !session;
  $("git-identity").hidden = !session || !selected.has("step:git");
  $("confirm-install").checked = false;
  $("continue-button").disabled = Boolean(session);
  $("continue-button").textContent = session
    ? session.dryRun
      ? "Start dry-run preview"
      : "Install my setup"
    : "Download plan & continue";
  $("review-explanation").textContent = session
    ? session.dryRun
      ? "Preview your actual installer commands. No apps, shell files or system preferences will be changed."
      : "The local companion will run this selection. Administrator prompts appear in Terminal. Account sign-ins and purchases remain yours."
    : "Download your plan, then open the local companion on your Mac for a guided installation.";
  $("review-caption").textContent = session
    ? "Keep Terminal open throughout setup."
    : "Your plan contains choices, never credentials.";
  setView("review");
}
function download(content, name, type = "application/json") {
  const url = URL.createObjectURL(new Blob([content], { type }));
  const link = element("a");
  link.href = url;
  link.download = name;
  document.body.append(link);
  link.click();
  link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}
function exportPlan() {
  download(
    JSON.stringify(createPlan(catalog, profile, selected), null, 2) + "\n",
    "mac-setup-plan.json",
  );
}
async function api(path, options = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 10000);
  try {
    const response = await fetch(`/api/${path}`, {
      ...options,
      signal: controller.signal,
      headers: { Authorization: `Bearer ${token}`, ...options.headers },
      cache: "no-store",
    });
    if (!response.ok) {
      const problem = await response.json();
      throw new Error(
        problem.error || "The local companion could not complete this request.",
      );
    }
    return response;
  } finally {
    clearTimeout(timeout);
  }
}
async function startInstallation() {
  if (starting) return;
  if (!session) {
    exportPlan();
    setView("guide");
    return;
  }
  if (!$("confirm-install").checked) {
    showError(
      "Review your choices and tick the confirmation before continuing.",
    );
    return;
  }
  if (!$("git-email").reportValidity()) return;
  starting = true;
  $("continue-button").disabled = true;
  // Discard the previous run's presentation before the new request can yield.
  // A completed, hidden view must not look like the new run has finished.
  followupSignature = "";
  lastRunStatus = "";
  renderRun({
    status: "starting",
    dryRun: session.dryRun,
    modules: [],
    records: [],
    reports: [],
    log: "",
  });
  try {
    await api("runs", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        plan: createPlan(catalog, profile, selected),
        confirm: true,
        identity: {
          name: selected.has("step:git") ? $("git-name").value : "",
          email: selected.has("step:git") ? $("git-email").value : "",
        },
      }),
    });
    setView("progress");
    await pollRun();
  } catch (error) {
    showError(error.message);
    $("continue-button").disabled = false;
  } finally {
    starting = false;
  }
}
function officialLink(url, text) {
  const link = element("a", "", text);
  if (!url.startsWith("https://")) return element("span", "", text);
  link.href = url;
  link.target = "_blank";
  link.rel = "noopener noreferrer";
  link.append(icon("arrow"));
  return link;
}
function renderRun(run) {
  requestTranslation();
  const finished = [
    "complete",
    "needs_attention",
    "failed",
    "interrupted",
  ].includes(run.status);
  const modules = run.modules || [];
  const processed = modules.filter((m) =>
    ["complete", "needs_attention"].includes(m.status),
  ).length;
  $("run-progress").max = Math.max(1, modules.length);
  $("run-progress").value = processed;
  $("run-mode").textContent = run.dryRun
    ? "Dry-run preview"
    : "Local installation";
  $("progress-count").textContent = modules.length
    ? `${processed} of ${modules.length} steps processed`
    : "Preparing your setup…";
  $("progress-description").textContent =
    run.status === "authorising"
      ? "Approve the administrator prompt in Terminal. Your password never enters this page."
      : finished
        ? run.status === "complete"
          ? run.dryRun
            ? "Preview finished. No apps or preferences were changed."
            : "Installation finished. Review any follow-ups below and open a new terminal to load your shell."
          : run.dryRun
            ? "Preview stopped with items to review. No apps or preferences were changed."
            : "Setup stopped with items to review. Open the report and installer output for details."
        : run.dryRun
          ? "Previewing commands. No apps or preferences are being changed."
          : "Your reviewed selection is running on this Mac. Already installed items are checked and skipped.";
  const statuses = {
    pending: "Waiting",
    running: "In progress",
    complete: run.dryRun ? "Previewed" : "Processed",
    needs_attention: "Needs attention",
    skipped: "Skipped",
  };
  const previousStatuses = new Map(
    [...$("module-list").children].map((row) => [
      row.dataset.module,
      row.dataset.status,
    ]),
  );
  $("module-list").replaceChildren(
    ...modules.map((entry, index) => {
      const row = element("li", `module-row ${entry.status}`);
      row.dataset.module = entry.id;
      row.dataset.status = entry.status;
      if (
        entry.status === "complete" &&
        previousStatuses.get(entry.id) !== "complete"
      )
        row.classList.add("just-completed");
      const mark = element("span", "module-status-icon");
      mark.setAttribute("aria-hidden", "true");
      if (entry.status === "complete") mark.append(icon("check"));
      else
        mark.textContent = entry.status === "needs_attention" ? "!" : index + 1;
      const text = element("div", "module-copy");
      const detail = MODULE_DETAILS[entry.id] || [
        "layers",
        "Run the selected setup step",
      ];
      const stageIcon = element("span", "module-stage-icon");
      stageIcon.append(icon(detail[0]));
      text.append(
        element("h3", "", MODULE_NAMES[entry.id] || entry.id),
        element("p", "", detail[1]),
      );
      row.append(
        mark,
        stageIcon,
        text,
        element("span", "module-label", statuses[entry.status]),
      );
      return row;
    }),
  );
  $("installer-output").textContent = (run.log || "").replace(
    /\x1b\[[0-9;]*[a-zA-Z]/g,
    "",
  );
  const records = run.records || [];
  const failed = records.filter((record) => record.status === "FAIL");
  $("run-error").hidden = !run.error && !failed.length;
  $("run-error").textContent =
    run.error ||
    `${failed.length} reported issue(s). Check the report before considering this setup complete.`;
  const followups = records.filter((record) => record.status === "MANUAL");
  const signature = JSON.stringify(followups);
  if (signature !== followupSignature) {
    followupSignature = signature;
    const unique = new Map(followups.map((entry) => [entry.item, entry]));
    $("followups").replaceChildren(
      ...[...unique.values()].map((entry) => {
        const [url, reason, steps] = entry.detail.split("|");
        const row = element("li");
        row.append(
          element("h3", "", entry.item),
          element("p", "", reason || entry.detail),
        );
        if (steps) row.append(element("p", "", steps));
        if (url?.startsWith("https://"))
          row.append(officialLink(url, "Open official guide"));
        return row;
      }),
    );
    if (!unique.size)
      $("followups").append(
        element(
          "li",
          "quiet",
          finished
            ? "No manual actions were recorded."
            : "Follow-ups will appear as the installer checks your selection.",
        ),
      );
  }
  $("followup-title").textContent = followups.length
    ? "A few things need you"
    : "Your follow-up checklist";
  $("report-button").disabled = !run.reports?.includes("install");
  $("manual-report-button").disabled = !run.reports?.includes("manual");
  $("report-caption").textContent = finished
    ? "Reports describe this run, including dry-run mode."
    : "Available when the run finishes.";
  $("new-plan").hidden = !finished;
  if (lastRunStatus !== run.status) {
    announce($("progress-description").textContent);
    lastRunStatus = run.status;
  }
  return finished;
}
async function pollRun() {
  clearTimeout(pollTimer);
  try {
    const run = await (await api("state")).json();
    $("connection-notice").hidden = true;
    if (run.status === "idle") return;
    if (!renderRun(run)) pollTimer = setTimeout(pollRun, 1200);
  } catch {
    const notice = $("connection-notice");
    notice.replaceChildren(
      element(
        "span",
        "",
        "Connection lost. The installer may still be running. Keep Terminal open and reconnect to its private setup link.",
      ),
    );
    const retry = element("button", "text-button", "Retry connection");
    retry.addEventListener("click", pollRun);
    notice.append(retry);
    notice.hidden = false;
    requestTranslation();
  }
}
async function downloadReport(name) {
  try {
    download(
      await (await api(`reports/${name}`)).text(),
      name === "manual" ? "manual-actions.md" : "install-report.md",
      "text/markdown",
    );
  } catch (error) {
    showError(error.message);
  }
}
function applyImported(plan) {
  requestTranslation();
  const result = importPlan(catalog, plan);
  profile = result.profile;
  selected = result.selected;
  persist();
  renderProfiles();
  renderSelection();
  resetFilters();
  setView("choose");
  if (result.changed)
    showError(
      "This plan used an older catalogue. Available choices were carried over and prerequisites updated. Review every selection before installing.",
    );
  else announce("Plan imported. Review your choices before continuing.");
}
function bindEvents() {
  document.addEventListener("mac-setup:locale", () => {
    if ($("search").value.trim()) renderCatalog();
  });
  $("search").addEventListener("input", renderCatalog);
  $("source-filter").addEventListener("change", renderCatalog);
  $("selected-filter").addEventListener("click", () => {
    selectedOnly = !selectedOnly;
    $("selected-filter").setAttribute("aria-pressed", String(selectedOnly));
    renderCatalog();
  });
  $("clear-button").addEventListener("click", () => {
    selected = requiredSelection(catalog);
    persist();
    renderSelection();
    renderCatalog();
    announce("Optional items cleared. Required tools remain selected.");
  });
  $("review-button").addEventListener("click", renderReview);
  $("back-button").addEventListener("click", () => setView("choose"));
  $("guide-back").addEventListener("click", renderReview);
  $("export-button").addEventListener("click", exportPlan);
  $("download-again").addEventListener("click", exportPlan);
  $("continue-button").addEventListener("click", startInstallation);
  $("confirm-install").addEventListener("change", () => {
    $("continue-button").disabled = !$("confirm-install").checked;
  });
  $("import-button").addEventListener("click", () => $("plan-file").click());
  $("plan-file").addEventListener("change", async (event) => {
    const file = event.target.files[0];
    if (!file) return;
    try {
      if (file.size > 65536)
        throw new Error(
          "This plan is too large. Choose an exported mac-setup JSON file.",
        );
      applyImported(JSON.parse(await file.text()));
    } catch (error) {
      showError(
        error instanceof SyntaxError
          ? "This file is not valid JSON. Choose an exported mac-setup plan."
          : error.message,
      );
    } finally {
      event.target.value = "";
    }
  });
  $("copy-command").addEventListener("click", async () => {
    try {
      await navigator.clipboard.writeText($("launch-command").textContent);
      $("copy-command").textContent = "Copied";
      requestTranslation();
    } catch {
      showError(
        "Clipboard access is unavailable. Select the command and copy it manually.",
      );
    }
  });
  $("report-button").addEventListener("click", () => downloadReport("install"));
  $("manual-report-button").addEventListener("click", () =>
    downloadReport("manual"),
  );
  $("new-plan").addEventListener("click", () => {
    clearTimeout(pollTimer);
    setView("choose");
  });
}
function setupFloatingSummary() {
  const summary = document.querySelector(".selection-column");
  const home = document.createComment("Desktop summary position");
  summary.before(home);
  const slot = document.createElement("div");
  slot.id = "floating-summary-slot";
  $("setup-window").after(slot);
  const compact = matchMedia("(max-width: 1050px)");
  const place = () => {
    const focus = summary.contains(document.activeElement)
      ? document.activeElement
      : null;
    if (compact.matches) slot.append(summary);
    else home.after(summary);
    focus?.focus({ preventScroll: true });
    liquid.refresh();
  };
  compact.addEventListener("change", place);
  place();
}

async function init() {
  liquid = setupSiteChrome();
  setupFloatingSummary();
  sourcePicker = createSourcePicker($("source-filter"));
  try {
    const response = await fetch(new URL("./catalog.json", import.meta.url));
    if (!response.ok)
      throw new Error(
        "The installer catalogue could not load. Reload the page to try again.",
      );
    catalog = await response.json();
    selected = profileSelection(catalog, profile);
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (stored) {
        const result = importPlan(catalog, JSON.parse(stored));
        profile = result.profile;
        selected = result.selected;
      }
    } catch {
      announce(
        "Saved choices could not be restored. Essentials is ready as a starting point.",
      );
    }
    bindEvents();
    renderProfiles();
    renderCategories();
    renderSelection();
    renderCatalog();
    if (location.hostname === "127.0.0.1") {
      const fragment = new URLSearchParams(location.hash.slice(1));
      try {
        token =
          fragment.get("session") ||
          sessionStorage.getItem("mac-setup.session") ||
          "";
        if (fragment.has("session")) {
          sessionStorage.setItem("mac-setup.session", token);
          history.replaceState(null, "", location.pathname);
        }
      } catch {
        token = fragment.get("session") || "";
      }
      if (token) {
        try {
          session = await (await api("session")).json();
          $("environment").textContent = session.dryRun
            ? "Local companion · Dry-run preview"
            : `Local companion · ${session.architecture === "arm64" ? "Apple Silicon" : "Intel"}`;
          requestTranslation();
          if (session.plan) applyImported(session.plan);
          const run = await (await api("state")).json();
          if (run.status !== "idle") {
            setView("progress", false);
            renderRun(run);
            if (
              ![
                "complete",
                "needs_attention",
                "failed",
                "interrupted",
              ].includes(run.status)
            )
              await pollRun();
          }
        } catch {
          showError(
            "The local companion could not connect. Open the private setup link printed in Terminal. Your choices are still available.",
          );
        }
      }
    }
  } catch (error) {
    $("catalog").setAttribute("aria-busy", "false");
    $("catalog").replaceChildren(
      element(
        "div",
        "empty-state",
        "Your catalogue is temporarily unavailable.",
      ),
    );
    showError(error.message);
    const retry = element("button", "text-button", "Reload catalogue");
    retry.addEventListener("click", () => location.reload());
    $("app-error").append(retry);
  }
}
init();
