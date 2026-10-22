import messages from "./messages.mjs";

export const LANGUAGES = [
  { id: "en-GB", name: "English (UK)", flag: "gb" },
  { id: "pt-BR", name: "Português (Brasil)", flag: "br" },
  { id: "fr-FR", name: "Français", flag: "fr" },
  { id: "de-DE", name: "Deutsch", flag: "de" },
  { id: "es-ES", name: "Español (España)", flag: "es" },
];
const normalise = (text) => text.replace(/\s+/g, " ").trim();
const dictionaries = new Map(
  LANGUAGES.map(({ id }, index) => [
    id,
    new Map(
      messages.map(([source, ...values]) => [
        normalise(source),
        index ? values[index - 1] : source,
      ]),
    ),
  ]),
);
const escape = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const templates = messages
  .filter(([source]) => /\{\d+\}/.test(source))
  // Longer literal phrases must win over catch-all slots such as “Select all {0}”.
  .sort(
    (a, b) =>
      b[0].replace(/\{\d+\}/g, "").length - a[0].replace(/\{\d+\}/g, "").length,
  )
  .map(([source]) => ({
    source,
    pattern: new RegExp(
      "^" +
        source
          .split(/(\{\d+\})/)
          .map((part) => (/^\{\d+\}$/.test(part) ? "(.+?)" : escape(part)))
          .join("") +
        "$",
    ),
    slots: [...source.matchAll(/\{(\d+)\}/g)].map((match) => +match[1]),
  }));
let locale = "en-GB";
try {
  const stored = localStorage.getItem("mac-setup.locale.v1");
  if (dictionaries.has(stored)) locale = stored;
} catch {
  /* Storage is optional. */
}
export const getLocale = () => locale;
export function translate(text, depth = 0) {
  const key = normalise(text);
  if (locale === "en-GB") return text;
  const dictionary = dictionaries.get(locale);
  if (dictionary.has(key)) return dictionary.get(key);
  if (depth < 2)
    for (const template of templates) {
      const match = template.pattern.exec(key);
      if (!match) continue;
      const values = new Map(
        template.slots.map((slot, index) => [
          slot,
          translate(match[index + 1], depth + 1),
        ]),
      );
      return dictionary
        .get(template.source)
        .replace(/\{(\d+)\}/g, (_, slot) => values.get(+slot));
    }
  return text;
}
const textBindings = new WeakMap();
const attributeBindings = new WeakMap();
const ignore =
  "script, style, code, pre, input, textarea, select, [data-i18n-ignore]";
function update(value, previous) {
  const source =
    previous && value === previous.output ? previous.source : value;
  const leading = source.match(/^\s*/)[0],
    trailing = source.match(/\s*$/)[0];
  const output = leading + translate(normalise(source)) + trailing;
  return { source, output };
}
/** Explicit render hooks retain canonical English; commands, input values and logs stay intact. */
export function translateTree(root = document.body) {
  if (!root) return;
  const walker = document.createTreeWalker(root, NodeFilter.SHOW_TEXT, {
    acceptNode(node) {
      return node.parentElement?.closest(ignore)
        ? NodeFilter.FILTER_REJECT
        : NodeFilter.FILTER_ACCEPT;
    },
  });
  while (walker.nextNode()) {
    const node = walker.currentNode;
    if (!node.data.trim()) continue;
    const binding = update(node.data, textBindings.get(node));
    textBindings.set(node, binding);
    if (node.data !== binding.output) node.data = binding.output;
  }
  for (const element of root.querySelectorAll(
    "[aria-label], [placeholder], [title]",
  )) {
    if (element.closest("script, style, code, pre, select, [data-i18n-ignore]"))
      continue;
    let bindings = attributeBindings.get(element);
    if (!bindings) {
      bindings = new Map();
      attributeBindings.set(element, bindings);
    }
    for (const name of ["aria-label", "placeholder", "title"]) {
      if (!element.hasAttribute(name)) continue;
      const binding = update(element.getAttribute(name), bindings.get(name));
      bindings.set(name, binding);
      if (element.getAttribute(name) !== binding.output)
        element.setAttribute(name, binding.output);
    }
  }
  const title = document.querySelector("title");
  if (title) {
    const binding = update(title.textContent, textBindings.get(title));
    textBindings.set(title, binding);
    title.textContent = binding.output;
  }
}
let queued = false;
export function requestTranslation() {
  if (queued) return;
  queued = true;
  queueMicrotask(() => {
    queued = false;
    translateTree();
  });
}
export function setLocale(next) {
  if (!dictionaries.has(next)) throw new Error("Unsupported language.");
  locale = next;
  document.documentElement.lang = locale;
  try {
    localStorage.setItem("mac-setup.locale.v1", locale);
  } catch {
    /* This visit still works. */
  }
  translateTree();
  document.dispatchEvent(
    new CustomEvent("mac-setup:locale", { detail: locale }),
  );
}
if (typeof document !== "undefined") document.documentElement.lang = locale;
