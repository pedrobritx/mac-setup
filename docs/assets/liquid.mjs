import {
  createSpring,
  advanceSpring,
  springSettled,
  surfaceStretch,
} from "./liquid-physics.mjs";

import { requestTranslation } from "./i18n.mjs";

const SVG_NS = "http://www.w3.org/2000/svg";
const clamp = (value, minimum, maximum) =>
  Math.min(maximum, Math.max(minimum, value));

/** Decorative material stays independent of selection and installation state. */
export function createLiquidUI() {
  const root = document.documentElement;
  const reduceMotion = matchMedia("(prefers-reduced-motion: reduce)");
  const reduceTransparency = matchMedia(
    "(prefers-reduced-transparency: reduce)",
  );
  const rails = new Map();
  const animations = new Set();
  const effectsButton = document.getElementById("effects-button");
  const dialog = document.getElementById("info-dialog");
  const toolbar = document.querySelector(".top-nav");
  const appWindow = document.querySelector(".setup-window");
  const windowToolbar = document.querySelector(".window-toolbar");
  const scrollPositions = new WeakMap();
  const scrollSurfaces = new Map();
  let preference =
    reduceMotion.matches || reduceTransparency.matches ? "calm" : "liquid";
  let frame = 0;
  let lastTime = 0;
  let previousScroll = window.scrollY;
  let navSpring = createSpring();
  let windowSpring = createSpring();
  let windowLight = null;
  let hover = null;
  let pressed = null;
  let closingTimer;
  let dialogOpener;
  let nextId = 0;
  try {
    const stored = localStorage.getItem("mac-setup.effects.v1");
    if (["liquid", "calm"].includes(stored)) preference = stored;
  } catch {
    /* Appearance remains available when storage is disabled. */
  }

  const motionAllowed = () => preference === "liquid" && !reduceMotion.matches;

  function animate(node, keyframes, options) {
    if (!motionAllowed() || !node.animate) return;
    const animation = node.animate(keyframes, options);
    animations.add(animation);
    const remove = () => animations.delete(animation);
    animation.addEventListener("finish", remove, { once: true });
    animation.addEventListener("cancel", remove, { once: true });
  }

  function wake() {
    if (!frame && !document.hidden && motionAllowed()) {
      lastTime = 0;
      frame = requestAnimationFrame(tick);
    }
  }

  function tick(time) {
    frame = 0;
    const elapsed = lastTime ? (time - lastTime) / 1000 : 1 / 120;
    lastTime = time;
    let moving = false;
    for (const rail of rails.values()) {
      if (!rail.visible) continue;
      let unsettled = false;
      for (const key of ["x", "y", "width", "height"]) {
        rail.body[key] = advanceSpring(
          rail.body[key],
          rail.target[key],
          elapsed,
        );
        rail.tail[key] = advanceSpring(
          rail.tail[key],
          rail.body[key].position,
          elapsed,
          150,
          22,
        );
        unsettled ||=
          !springSettled(rail.body[key], rail.target[key]) ||
          !springSettled(rail.tail[key], rail.target[key]);
      }
      if (!unsettled) snap(rail);
      paint(rail);
      rail.root.dataset.liquidState = unsettled ? "moving" : "settled";
      moving ||= unsettled;
    }
    if (hover) {
      hover.x = advanceSpring(hover.x, hover.targetX, elapsed, 300, 30);
      hover.y = advanceSpring(hover.y, hover.targetY, elapsed, 300, 30);
      hover.node.style.setProperty("--light-x", `${hover.x.position}%`);
      hover.node.style.setProperty("--light-y", `${hover.y.position}%`);
      moving ||=
        !springSettled(hover.x, hover.targetX) ||
        !springSettled(hover.y, hover.targetY);
    }
    if (windowLight) {
      windowLight.x = advanceSpring(
        windowLight.x,
        windowLight.targetX,
        elapsed,
        160,
        24,
      );
      windowLight.y = advanceSpring(
        windowLight.y,
        windowLight.targetY,
        elapsed,
        160,
        24,
      );
      appWindow.style.setProperty(
        "--window-light-x",
        `${windowLight.x.position}%`,
      );
      appWindow.style.setProperty(
        "--window-light-y",
        `${windowLight.y.position}%`,
      );
      moving ||=
        !springSettled(windowLight.x, windowLight.targetX) ||
        !springSettled(windowLight.y, windowLight.targetY);
    }
    navSpring = advanceSpring(navSpring, 0, elapsed, 150, 22);
    navSpring.position = clamp(navSpring.position, -4, 4);
    toolbar.style.setProperty(
      "--nav-drift",
      `${navSpring.position.toFixed(2)}px`,
    );
    moving ||= !springSettled(navSpring, 0);
    windowSpring = advanceSpring(windowSpring, 0, elapsed, 150, 22);
    windowSpring.position = clamp(windowSpring.position, -4, 4);
    appWindow?.style.setProperty(
      "--window-drift",
      `${windowSpring.position.toFixed(2)}px`,
    );
    windowToolbar?.style.setProperty(
      "--toolbar-drift",
      `${(windowSpring.position * 0.45).toFixed(2)}px`,
    );
    moving ||= !springSettled(windowSpring, 0);
    for (const [node, spring] of scrollSurfaces) {
      const next = advanceSpring(spring, 0, elapsed, 140, 22);
      node.style.setProperty(
        "--scroll-drift",
        `${clamp(next.position, -4, 4).toFixed(2)}px`,
      );
      if (springSettled(next, 0)) {
        node.classList.remove("has-scroll-elasticity");
        node.style.removeProperty("--scroll-drift");
        scrollSurfaces.delete(node);
      } else {
        scrollSurfaces.set(node, next);
        moving = true;
      }
    }
    if (moving) frame = requestAnimationFrame(tick);
  }

  function svgElement(name, attributes = {}) {
    const node = document.createElementNS(SVG_NS, name);
    for (const [key, value] of Object.entries(attributes))
      node.setAttribute(key, value);
    return node;
  }

  function snap(rail) {
    for (const key of ["x", "y", "width", "height"]) {
      rail.body[key] = createSpring(rail.target[key]);
      rail.tail[key] = createSpring(rail.target[key]);
    }
  }

  function paint(rail) {
    const stretch = surfaceStretch(rail.body.x.velocity, rail.body.y.velocity);
    for (const [node, state, inset] of [
      [rail.front, rail.body, 0],
      [rail.trail, rail.tail, 3],
    ]) {
      const width = Math.max(1, state.width.position - inset);
      const height = Math.max(1, state.height.position - inset);
      node.setAttribute("x", state.x.position - width / 2);
      node.setAttribute("y", state.y.position - height / 2);
      node.setAttribute("width", width);
      node.setAttribute("height", height);
      node.setAttribute("rx", Math.min(18, height / 2));
    }
    const { position: x } = rail.body.x;
    const { position: y } = rail.body.y;
    rail.front.setAttribute(
      "transform",
      `translate(${x} ${y}) rotate(${stretch.angle}) scale(${stretch.scaleX} ${stretch.scaleY}) rotate(${-stretch.angle}) translate(${-x} ${-y})`,
    );
  }

  function measure(rail, immediate = false) {
    const active = rail.root.querySelector(rail.selector);
    const bounds = rail.root.getBoundingClientRect();
    rail.visible = Boolean(active && bounds.width && bounds.height);
    rail.svg.style.display = rail.visible ? "" : "none";
    if (!rail.visible) return;
    if (!rail.svg.isConnected) rail.root.prepend(rail.svg);
    const rect = active.getBoundingClientRect();
    rail.target = {
      x: rect.left - bounds.left + rail.root.scrollLeft + rect.width / 2,
      y: rect.top - bounds.top + rail.root.scrollTop + rect.height / 2,
      width: rect.width - 2,
      height: rect.height - 2,
    };
    const width = Math.max(
      rail.root.clientWidth,
      ...[...rail.root.children]
        .filter((node) => node !== rail.svg)
        .map((node) => node.offsetLeft + node.offsetWidth),
    );
    rail.svg.setAttribute("width", width);
    rail.svg.setAttribute("height", bounds.height);
    rail.svg.style.width = `${width}px`;
    rail.svg.style.height = `${bounds.height}px`;
    rail.svg.setAttribute("viewBox", `0 0 ${width} ${bounds.height}`);
    rail.filter.setAttribute("width", width + 80);
    rail.filter.setAttribute("height", bounds.height + 80);
    if (immediate || !rail.body || !motionAllowed()) {
      rail.body = {};
      rail.tail = {};
      snap(rail);
      paint(rail);
      rail.root.dataset.liquidState = "settled";
    } else {
      rail.root.dataset.liquidState = "moving";
      wake();
    }
  }

  function syncRail(container, selector) {
    let rail = rails.get(container);
    if (!rail) {
      const id = `liquid-material-${++nextId}`;
      const svg = svgElement("svg", {
        class: "liquid-rail",
        "aria-hidden": "true",
        focusable: "false",
      });
      const defs = svgElement("defs");
      const filter = svgElement("filter", {
        id,
        x: -40,
        y: -40,
        filterUnits: "userSpaceOnUse",
        "color-interpolation-filters": "sRGB",
      });
      filter.append(
        svgElement("feGaussianBlur", {
          in: "SourceGraphic",
          stdDeviation: 5,
          result: "soft",
        }),
        svgElement("feColorMatrix", {
          in: "soft",
          type: "matrix",
          values: "1 0 0 0 0  0 1 0 0 0  0 0 1 0 0  0 0 0 18 -7",
        }),
      );
      const gradient = svgElement("linearGradient", {
        id: `${id}-tint`,
        x1: "0%",
        y1: "0%",
        x2: "100%",
        y2: "45%",
      });
      gradient.append(
        svgElement("stop", { offset: "0%", "stop-color": "#7ee8c7" }),
        svgElement("stop", { offset: "56%", "stop-color": "#7fb5ff" }),
        svgElement("stop", { offset: "100%", "stop-color": "#c5a6ff" }),
      );
      defs.append(filter, gradient);
      const union = svgElement("g", {
        filter: `url(#${id})`,
        fill: `url(#${id}-tint)`,
        stroke: "none",
      });
      const trail = svgElement("rect");
      const front = svgElement("rect");
      union.append(trail, front);
      svg.append(defs, union);
      container.prepend(svg);
      container.classList.add("has-liquid");
      rail = {
        root: container,
        selector,
        svg,
        filter,
        front,
        trail,
        visible: false,
      };
      rails.set(container, rail);
      if (window.ResizeObserver) {
        const observer = new ResizeObserver(() => measure(rail, true));
        observer.observe(container);
      } else {
        window.addEventListener("resize", () => measure(rail, true));
      }
    }
    measure(rail);
  }

  function refresh() {
    for (const rail of rails.values()) measure(rail, true);
  }

  function applyPreference() {
    requestTranslation();
    root.dataset.effects = preference;
    root.dataset.motion = motionAllowed() ? "full" : "reduced";
    root.dataset.transparency =
      preference === "calm" || reduceTransparency.matches ? "solid" : "glass";
    const liquid = preference === "liquid";
    effectsButton.setAttribute("aria-pressed", String(liquid));
    effectsButton.setAttribute(
      "aria-label",
      liquid
        ? "Fluid effects. Use calm appearance"
        : "Calm appearance. Use fluid effects",
    );
    effectsButton.querySelector(".effects-label").textContent = liquid
      ? "Fluid"
      : "Calm";
    effectsButton.title = liquid
      ? "Use calm appearance: less motion and solid surfaces"
      : "Use fluid effects. System accessibility preferences are always respected.";
    if (!motionAllowed()) {
      cancelAnimationFrame(frame);
      frame = 0;
      for (const animation of animations) animation.cancel();
      hover?.node.classList.remove("has-liquid-light");
      hover = null;
      pressed?.classList.remove("is-liquid-pressed");
      pressed = null;
      navSpring = createSpring();
      windowSpring = createSpring();
      windowLight = null;
      toolbar.style.removeProperty("--nav-drift");
      appWindow?.style.removeProperty("--window-drift");
      appWindow?.style.removeProperty("--window-light-x");
      appWindow?.style.removeProperty("--window-light-y");
      windowToolbar?.style.removeProperty("--toolbar-drift");
      for (const node of scrollSurfaces.keys()) {
        node.classList.remove("has-scroll-elasticity");
        node.style.removeProperty("--scroll-drift");
      }
      scrollSurfaces.clear();
    }
    refresh();
  }
  effectsButton.addEventListener("click", () => {
    preference = preference === "liquid" ? "calm" : "liquid";
    applyPreference();
    try {
      localStorage.setItem("mac-setup.effects.v1", preference);
    } catch {
      /* Optional. */
    }
  });
  reduceMotion.addEventListener("change", applyPreference);
  reduceTransparency.addEventListener("change", applyPreference);
  document.addEventListener("visibilitychange", () => {
    cancelAnimationFrame(frame);
    frame = 0;
    if (!document.hidden) {
      refresh();
      wake();
    }
  });

  const surfaceSelector =
    ".primary-button, .secondary-button, .profile-option, .summary-panel, .app-row, .top-nav, .window-toolbar, .filter-button, .search-field, .icon-button, .text-button, .back-button, .nav-link";
  function clearHover() {
    hover?.node.classList.remove("has-liquid-light");
    hover = null;
  }
  document.addEventListener(
    "pointermove",
    (event) => {
      if (!motionAllowed() || event.pointerType === "touch") return;
      if (appWindow && event.target.closest(".setup-window") === appWindow) {
        const bounds = appWindow.getBoundingClientRect();
        const x = clamp(
          ((event.clientX - bounds.left) / bounds.width) * 100,
          0,
          100,
        );
        const y = clamp(
          ((event.clientY - bounds.top) / bounds.height) * 100,
          0,
          100,
        );
        windowLight ||= {
          x: createSpring(x),
          y: createSpring(y),
          targetX: x,
          targetY: y,
        };
        windowLight.targetX = x;
        windowLight.targetY = y;
        wake();
      }
      const node = event.target.closest(surfaceSelector);
      if (!node) {
        clearHover();
        return;
      }
      const rect = node.getBoundingClientRect();
      const x = clamp(((event.clientX - rect.left) / rect.width) * 100, 0, 100);
      const y = clamp(((event.clientY - rect.top) / rect.height) * 100, 0, 100);
      if (hover?.node !== node) {
        clearHover();
        hover = {
          node,
          x: createSpring(x),
          y: createSpring(y),
          targetX: x,
          targetY: y,
        };
        node.classList.add("has-liquid-light");
      }
      hover.targetX = x;
      hover.targetY = y;
      wake();
    },
    { passive: true },
  );
  document.addEventListener("pointerleave", clearHover);
  document.addEventListener(
    "pointerdown",
    (event) => {
      if (!motionAllowed()) return;
      pressed?.classList.remove("is-liquid-pressed");
      pressed = event.target.closest(
        ".primary-button, .secondary-button, .icon-button, .filter-button, .text-button, .back-button, .nav-link, .source-option, .app-source",
      );
      pressed?.classList.add("is-liquid-pressed");
    },
    { passive: true },
  );
  function release() {
    pressed?.classList.remove("is-liquid-pressed");
    pressed = null;
  }
  document.addEventListener("pointerup", release, { passive: true });
  document.addEventListener(
    "pointercancel",
    () => {
      release();
      clearHover();
    },
    { passive: true },
  );
  window.addEventListener("blur", () => {
    release();
    clearHover();
  });
  window.addEventListener(
    "scroll",
    () => {
      const delta = window.scrollY - previousScroll;
      previousScroll = window.scrollY;
      if (motionAllowed()) {
        navSpring.velocity = clamp(navSpring.velocity - delta * 2, -70, 70);
        windowSpring.velocity = clamp(
          windowSpring.velocity - delta * 2,
          -70,
          70,
        );
        wake();
      }
    },
    { passive: true },
  );
  document.addEventListener(
    "scroll",
    (event) => {
      const node = event.target;
      if (!(node instanceof Element)) return;
      const previous = scrollPositions.get(node) || { x: 0, y: 0 };
      const delta = node.scrollTop - previous.y || node.scrollLeft - previous.x;
      scrollPositions.set(node, { x: node.scrollLeft, y: node.scrollTop });
      if (!motionAllowed()) return;
      const surface = node.closest(
        "dialog, .output-details pre, .categories, .source-options",
      );
      if (!surface) return;
      const spring = scrollSurfaces.get(surface) || createSpring();
      spring.velocity = clamp(spring.velocity - delta, -60, 60);
      surface.classList.add("has-scroll-elasticity");
      scrollSurfaces.set(surface, spring);
      wake();
    },
    { capture: true, passive: true },
  );

  function openDialog(opener = document.activeElement) {
    clearTimeout(closingTimer);
    dialog.classList.remove("is-closing");
    if (!dialog.open) {
      dialogOpener = opener;
      dialog.showModal();
    }
    void dialog.offsetWidth;
    dialog.classList.add("is-open");
  }
  function closeDialog() {
    if (!dialog.open) return;
    clearTimeout(closingTimer);
    dialog.classList.remove("is-open");
    dialog.classList.add("is-closing");
    const duration = motionAllowed()
      ? Number.parseFloat(
          getComputedStyle(root).getPropertyValue("--modal-close-dur"),
        ) || 150
      : 0;
    closingTimer = setTimeout(() => {
      dialog.close();
      dialog.classList.remove("is-closing");
    }, duration);
  }
  let backdropPress = false;
  const outsideDialog = (event) => {
    const bounds = dialog.getBoundingClientRect();
    return (
      event.target === dialog &&
      (event.clientX < bounds.left ||
        event.clientX > bounds.right ||
        event.clientY < bounds.top ||
        event.clientY > bounds.bottom)
    );
  };
  dialog.addEventListener("pointerdown", (event) => {
    backdropPress = outsideDialog(event);
  });
  dialog.addEventListener("click", (event) => {
    if (backdropPress && outsideDialog(event)) closeDialog();
    backdropPress = false;
  });
  dialog.addEventListener("pointercancel", () => {
    backdropPress = false;
  });
  // Escape uses native immediate dismissal so the page is never left inert
  // while the person starts their next keyboard action. The close button animates.
  dialog.addEventListener("cancel", () => {
    clearTimeout(closingTimer);
    dialog.classList.remove("is-open", "is-closing");
  });
  dialog.addEventListener("close", () => {
    clearTimeout(closingTimer);
    dialog.classList.remove("is-open", "is-closing");
    if (dialogOpener?.isConnected) dialogOpener.focus({ preventScroll: true });
    dialogOpener = null;
  });
  applyPreference();
  document.fonts?.ready.then(refresh);

  return {
    syncRail,
    refresh,
    openDialog,
    closeDialog,
    revealView(node) {
      refresh();
      animate(node, [{ opacity: 0 }, { opacity: 1 }], {
        duration: 250,
        easing: "ease-out",
      });
    },
    revealCatalog() {
      clearHover();
      document.querySelectorAll(".catalog-group").forEach((node, index) => {
        animate(
          node,
          [
            { opacity: 0, transform: "translateY(7px)" },
            { opacity: 1, transform: "translateY(0)" },
          ],
          {
            duration: 350,
            delay: Math.min(index, 3) * 24,
            easing: "cubic-bezier(0.22, 1, 0.36, 1)",
          },
        );
      });
    },
    updateCount(node, value) {
      if (node.textContent === String(value)) return;
      node.textContent = value;
      animate(
        node,
        [
          { opacity: 0.4, transform: "translateY(3px)" },
          { opacity: 1, transform: "translateY(0)" },
        ],
        { duration: 250, easing: "ease-out" },
      );
    },
  };
}
