import {
  LANGUAGES,
  getLocale,
  setLocale,
  requestTranslation,
} from "./i18n.mjs";
import { createSourcePicker } from "./source-picker.mjs";

export function setupLanguagePicker() {
  const root = document.createElement("div");
  root.className = "source-picker language-picker";
  const label = document.createElement("span");
  label.id = "language-label";
  label.className = "sr-only";
  label.textContent = "Language";
  const select = document.createElement("select");
  select.id = "language-select";
  select.setAttribute("aria-label", "Language");
  for (const language of LANGUAGES) {
    const option = new Option(language.name, language.id);
    option.lang = language.id;
    select.append(option);
  }
  select.value = getLocale();
  root.append(label, select);
  document.querySelector(".nav-actions").append(root);
  createSourcePicker(select, {
    prefix: "language",
    triggerClass: "icon-button language-trigger",
  });
  const value = document.getElementById("language-value");
  value.classList.add("sr-only");
  value.dataset.i18nIgnore = "";
  value.lang = getLocale();
  const list = document.getElementById("language-options");
  list.dataset.i18nIgnore = "";
  const makeFlag = (language) => {
    const flag = document.createElement("img");
    flag.className = "language-flag";
    flag.src = new URL(`./flags/${language.flag}.svg`, import.meta.url).href;
    flag.alt = "";
    flag.width = 26;
    flag.height = 26;
    return flag;
  };
  [...list.children].forEach((option, index) => {
    option.prepend(makeFlag(LANGUAGES[index]));
    option.lang = LANGUAGES[index].id;
  });
  const trigger = document.getElementById("language-trigger");
  const flag = makeFlag(
    LANGUAGES.find((language) => language.id === getLocale()),
  );
  trigger.prepend(flag);
  trigger.title = "Choose language";
  select.addEventListener("change", () => {
    const language = LANGUAGES.find((entry) => entry.id === select.value);
    flag.src = new URL(`./flags/${language.flag}.svg`, import.meta.url).href;
    value.lang = language.id;
    setLocale(language.id);
    requestTranslation();
  });
}
