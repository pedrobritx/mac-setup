/** Progressive enhancement: keep the native select as the source of filter values. */
export function createSourcePicker(
  select,
  { prefix = "source", triggerClass = "secondary-button" } = {},
) {
  const root = select.parentElement;
  const trigger = document.createElement("button");
  trigger.type = "button";
  trigger.id = `${prefix}-trigger`;
  trigger.className = `source-trigger ${triggerClass}`;
  trigger.setAttribute("aria-haspopup", "listbox");
  trigger.setAttribute("aria-expanded", "false");
  trigger.setAttribute("aria-controls", `${prefix}-options`);
  trigger.setAttribute("aria-labelledby", `${prefix}-label ${prefix}-value`);
  const value = document.createElement("span");
  value.id = `${prefix}-value`;
  const chevron = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  chevron.setAttribute("viewBox", "0 0 24 24");
  chevron.setAttribute("aria-hidden", "true");
  const path = document.createElementNS(chevron.namespaceURI, "path");
  path.setAttribute("d", "m6 9 6 6 6-6");
  chevron.append(path);
  trigger.append(value, chevron);

  const list = document.createElement("div");
  list.id = `${prefix}-options`;
  list.className = "source-options";
  list.setAttribute("role", "listbox");
  list.setAttribute("aria-labelledby", `${prefix}-label`);
  list.hidden = true;
  const options = [...select.options].map((option) => {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "source-option";
    button.setAttribute("role", "option");
    button.tabIndex = -1;
    button.dataset.value = option.value;
    button.textContent = option.textContent;
    button.setAttribute("aria-label", option.textContent);
    button.addEventListener("click", () => {
      select.value = option.value;
      select.dispatchEvent(new Event("change", { bubbles: true }));
      close(true);
    });
    list.append(button);
    return button;
  });
  let closing;
  let typeAhead = "";
  let lastTyped = 0;
  const selectedIndex = () =>
    Math.max(
      0,
      options.findIndex((option) => option.dataset.value === select.value),
    );
  const sync = () => {
    value.textContent = select.selectedOptions[0].textContent;
    options.forEach((option) =>
      option.setAttribute(
        "aria-selected",
        String(option.dataset.value === select.value),
      ),
    );
  };
  function positionList() {
    const bounds = trigger.getBoundingClientRect();
    const summary = document.querySelector(".selection-column");
    const bottom =
      summary && getComputedStyle(summary).position === "fixed"
        ? Math.min(
            window.innerHeight - 16,
            summary.getBoundingClientRect().top - 12,
          )
        : window.innerHeight - 16;
    const below = bottom - bounds.bottom;
    const above = bounds.top - 96;
    const opensAbove = below < list.scrollHeight + 8 && above > below;
    list.dataset.side = opensAbove ? "above" : "below";
    list.style.maxHeight = `${Math.max(90, (opensAbove ? above : below) - 12)}px`;
  }
  function open(index = selectedIndex()) {
    clearTimeout(closing);
    typeAhead = "";
    lastTyped = 0;
    list.hidden = false;
    positionList();
    trigger.setAttribute("aria-expanded", "true");
    // Establish the closed frame before animating; never delay keyboard focus.
    void list.offsetWidth;
    list.classList.add("is-open");
    options[index].focus({ preventScroll: true });
  }
  function close(restoreFocus = false) {
    if (list.hidden) return;
    trigger.setAttribute("aria-expanded", "false");
    list.classList.remove("is-open");
    if (restoreFocus) trigger.focus({ preventScroll: true });
    // A closing list must leave the accessibility tree immediately.
    list.setAttribute("aria-hidden", "true");
    list.inert = true;
    clearTimeout(closing);
    const duration =
      document.documentElement.dataset.motion === "reduced" ? 0 : 150;
    closing = setTimeout(() => {
      list.hidden = true;
    }, duration);
  }
  trigger.addEventListener("click", () => {
    if (trigger.getAttribute("aria-expanded") === "true") close();
    else {
      list.removeAttribute("aria-hidden");
      list.inert = false;
      open();
    }
  });
  root.addEventListener("keydown", (event) => {
    const isOpen = trigger.getAttribute("aria-expanded") === "true";
    if (event.key === "Escape" && isOpen) {
      event.preventDefault();
      event.stopPropagation();
      close(true);
      return;
    }
    if (event.key === "Tab") {
      close(true);
      return;
    }
    let index = options.indexOf(document.activeElement);
    if (["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) {
      event.preventDefault();
      if (!isOpen) {
        list.removeAttribute("aria-hidden");
        list.inert = false;
        open(
          event.key === "End"
            ? options.length - 1
            : event.key === "Home"
              ? 0
              : selectedIndex(),
        );
      } else {
        index =
          event.key === "Home"
            ? 0
            : event.key === "End"
              ? options.length - 1
              : (index +
                  (event.key === "ArrowDown" ? 1 : -1) +
                  options.length) %
                options.length;
        options[index].focus();
      }
    } else if (
      isOpen &&
      event.key.length === 1 &&
      !event.ctrlKey &&
      !event.metaKey &&
      event.key !== " "
    ) {
      event.preventDefault();
      const now = performance.now();
      typeAhead = now - lastTyped > 650 ? event.key : typeAhead + event.key;
      lastTyped = now;
      if (
        [...typeAhead].every(
          (letter) => letter.toLowerCase() === event.key.toLowerCase(),
        )
      )
        typeAhead = event.key;
      const ordered = [
        ...options.slice(index + 1),
        ...options.slice(0, index + 1),
      ];
      const match = ordered.find((option) =>
        option.textContent.toLowerCase().startsWith(typeAhead.toLowerCase()),
      );
      match?.focus();
    }
  });
  document.addEventListener(
    "pointerdown",
    (event) => {
      if (!root.contains(event.target)) close();
    },
    { passive: true },
  );
  root.addEventListener("focusout", (event) => {
    if (!root.contains(event.relatedTarget)) close();
  });
  const reposition = () => {
    if (trigger.getAttribute("aria-expanded") === "true") positionList();
  };
  window.addEventListener("resize", reposition, { passive: true });
  window.addEventListener("scroll", reposition, { passive: true });
  select.addEventListener("change", sync);
  sync();
  root.append(trigger, list);
  select.hidden = true;
  return { sync };
}
