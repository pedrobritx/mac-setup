import { createLiquidUI } from "./liquid.mjs";
import { setupLanguagePicker } from "./language-picker.mjs";
import { requestTranslation } from "./i18n.mjs";
import { icon } from "./icons.mjs";

const $ = (id) => document.getElementById(id);

function node(tag, className, text) {
  const element = document.createElement(tag);
  if (className) element.className = className;
  if (text) element.textContent = text;
  return element;
}

export function showHowItWorks(liquid) {
  requestTranslation();
  $("dialog-title").textContent = "A thoughtful setup, in three steps.";
  const flow = node("ol", "setup-flow");
  const steps = [
    [
      "sliders",
      "Make it yours",
      "In your browser",
      "Choose a profile. Add or remove apps, tools, Mac preferences and connections.",
    ],
    [
      "layers",
      "Review & take your plan",
      "Browser → your Mac",
      "Check your selection and download your JSON plan. Open the local companion and import it.",
    ],
    [
      "check",
      "Confirm, then follow along",
      "On your Mac",
      "Confirm locally to start. See real progress, keep Terminal open for prompts, and finish any guided follow-ups.",
    ],
  ];
  for (const [
    index,
    [symbol, title, location, description],
  ] of steps.entries()) {
    const step = node("li", "flow-step");
    const badge = node("span", "flow-badge");
    badge.append(icon(symbol));
    const copy = node("div", "flow-copy");
    copy.append(
      node("span", "eyebrow", `${index + 1} · ${location}`),
      node("h3", "", title),
      node("p", "", description),
    );
    step.append(badge, copy);
    flow.append(step);
  }
  const detail = node("div", "flow-note");
  detail.append(
    icon("info"),
    node(
      "p",
      "",
      "App Store purchases, account sign-ins and MCP permissions stay with you. Web apps and vendor-only installers appear as guided follow-ups.",
    ),
  );
  const privacy = node("a", "text-button", "How safety & privacy work");
  privacy.href = "safety.html";
  $("dialog-content").replaceChildren(flow, detail, privacy);
  liquid.openDialog($("how-button"));
}

/** Shared chrome keeps the setup and Safety page on the same appearance contract. */
export function setupSiteChrome() {
  const liquid = createLiquidUI();
  setupLanguagePicker();
  requestTranslation();
  document
    .querySelectorAll("[data-icon]")
    .forEach((element) => element.replaceChildren(icon(element.dataset.icon)));
  let theme = "dark";
  try {
    const stored = localStorage.getItem("mac-setup.theme");
    if (["dark", "light"].includes(stored)) theme = stored;
  } catch {
    /* Appearance works for this visit if storage is unavailable. */
  }
  const applyTheme = () => {
    requestTranslation();
    document.documentElement.dataset.theme = theme;
    $("theme-button").replaceChildren(icon(theme === "dark" ? "sun" : "moon"));
    $("theme-button").setAttribute(
      "aria-label",
      `Switch to ${theme === "dark" ? "light" : "dark"} theme`,
    );
  };
  applyTheme();
  $("theme-button").addEventListener("click", () => {
    theme = theme === "dark" ? "light" : "dark";
    applyTheme();
    try {
      localStorage.setItem("mac-setup.theme", theme);
    } catch {
      /* Optional. */
    }
  });
  $("close-dialog").addEventListener("click", liquid.closeDialog);
  $("how-button").addEventListener("click", () => showHowItWorks(liquid));
  return liquid;
}
