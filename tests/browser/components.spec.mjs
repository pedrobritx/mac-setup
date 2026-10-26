import { test, expect } from "@playwright/test";

test("component geometry, confirmation and busy/disabled states share one contract", async ({
  page,
}) => {
  await page.goto("http://127.0.0.1:3420/#session=browser-test-session-only");
  await expect(
    page.getByRole("radio", { name: "Essentials", exact: true }),
  ).toBeVisible();
  await expect(page.locator(".category-button").first()).toHaveCSS(
    "border-radius",
    "16px",
  );
  await expect(page.locator(".source-option").first()).toHaveCSS(
    "border-radius",
    "16px",
  );
  await page.getByRole("button", { name: "Review setup", exact: true }).click();
  const headings = await page
    .locator(".review-panel h2, .review-side h2")
    .evaluateAll((nodes) => nodes.map((n) => n.getBoundingClientRect().top));
  expect(Math.abs(headings[0] - headings[1])).toBeLessThan(1);
  const confirm = page.locator("#confirm-install");
  await confirm.focus();
  await page.keyboard.press("Space");
  await expect(confirm).toBeChecked();
  await expect(page.locator("#confirmation-label .choice-mark")).toHaveCSS(
    "border-radius",
    "6px",
  );
  let release;
  const pending = new Promise((resolve) => {
    release = resolve;
  });
  let requests = 0;
  await page.route("**/api/runs", async (route) => {
    if (route.request().method() !== "POST") return route.continue();
    requests++;
    await pending;
    await route.fulfill({
      status: 503,
      contentType: "application/json",
      body: JSON.stringify({ error: "Controlled unavailable companion" }),
    });
  });
  const start = page.locator("#continue-button");
  try {
    await start.click();
    await expect(start).toHaveAttribute("aria-busy", "true");
    await expect(start).toBeDisabled();
    await start.dispatchEvent("pointerdown", { bubbles: true });
    await expect(start).not.toHaveClass(/is-liquid-pressed/);
    expect(requests).toBe(1);
  } finally {
    release();
  }
  await expect(start).not.toHaveAttribute("aria-busy", "true");
  await expect(start).toBeEnabled();
});

test("render an internal reference from real controls in both themes and motion modes", async ({
  page,
}, testInfo) => {
  await page.goto("/");
  await expect(
    page.getByRole("radio", { name: "Essentials", exact: true }),
  ).toBeVisible();
  // Clone current product controls, rather than maintaining a second component implementation.
  await page.evaluate(() => {
    const board = document.createElement("main");
    board.id = "component-reference";
    board.style.cssText =
      "padding:24px;display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:16px";
    for (const selector of [
      ".primary-button",
      ".secondary-button",
      ".back-button",
      ".confirmation",
      ".profile-option",
      ".text-button",
      ".icon-button",
      ".category-button",
      ".source-option",
      ".app-choice",
    ]) {
      const source = document.querySelector(selector);
      const selection = [
        ".confirmation",
        ".profile-option",
        ".category-button",
        ".source-option",
        ".app-choice",
      ].includes(selector);
      const states = selection
        ? ["rest", "selected", "disabled"]
        : ["rest", "pressed", "disabled", "busy"];
      if (selector === ".text-button") states.push("complete");
      for (const state of states) {
        const card = document.createElement("section");
        const title = document.createElement("h2");
        title.textContent = `${selector} · ${state}`;
        title.style.cssText = "font-size:14px;margin:0 0 12px";
        const node = source.cloneNode(true);
        for (const el of [node, ...node.querySelectorAll("*")])
          el.removeAttribute("id");
        node.hidden = false;
        node.removeAttribute("aria-busy");
        if (node.matches("button, input")) node.disabled = false;
        node.querySelectorAll("input, button").forEach((el) => {
          el.disabled = false;
          if ("checked" in el) el.checked = false;
        });
        if (node.hasAttribute("aria-pressed"))
          node.setAttribute("aria-pressed", "false");
        if (node.hasAttribute("aria-selected"))
          node.setAttribute("aria-selected", "false");
        if (state === "pressed") node.classList.add("is-liquid-pressed");
        if (state === "selected") {
          node
            .querySelectorAll('input[type="checkbox"], input[type="radio"]')
            .forEach((el) => {
              el.checked = true;
            });
          if (node.hasAttribute("aria-pressed"))
            node.setAttribute("aria-pressed", "true");
          if (node.hasAttribute("aria-selected"))
            node.setAttribute("aria-selected", "true");
        }
        if (state === "busy") node.setAttribute("aria-busy", "true");
        if (state === "disabled" || state === "busy") {
          if (node.matches("button, input")) node.disabled = true;
          node.querySelectorAll("input, button").forEach((el) => {
            el.disabled = true;
          });
        }
        if (node.matches(".text-button"))
          node.textContent =
            state === "rest"
              ? "Selecionar todos os elementos desta categoria"
              : state === "complete"
                ? "Copied"
                : "Selecionar todos";
        node.style.maxWidth = "100%";
        card.style.minWidth = "0";
        card.append(title, node);
        board.append(card);
      }
    }
    document.body.replaceChildren(board);
  });
  for (const theme of ["dark", "light"]) {
    for (const motion of ["full", "reduced"]) {
      await page.locator("html").evaluate(
        (node, values) => {
          node.dataset.theme = values.theme;
          node.dataset.motion = values.motion;
        },
        { theme, motion },
      );
      await page.evaluate(() => document.activeElement?.blur());
      await page.mouse.move(0, 0);
      await page.screenshot({
        path: testInfo.outputPath(`components-${theme}-${motion}.png`),
        fullPage: true,
        animations: "disabled",
      });
      const target = page.locator("#component-reference .text-button").first();
      await target.focus();
      await expect(target).toBeFocused();
      await target.hover();
    }
  }
  await page.setViewportSize({ width: 390, height: 844 });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
});
