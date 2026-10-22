import { test, expect } from "@playwright/test";

test("the setup window springs with navigation while the compact summary stays anchored", async ({
  page,
}) => {
  await page.setViewportSize({ width: 932, height: 932 });
  await page.goto("/");
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  await expect(page.locator(".selection-column")).toHaveCSS(
    "position",
    "fixed",
  );
  const sampling = page.evaluate(
    () =>
      new Promise((resolve) => {
        const frames = [];
        const frame = () => {
          const win = document.querySelector("#setup-window");
          const nav = document.querySelector(".top-nav");
          frames.push({
            window: new DOMMatrixReadOnly(getComputedStyle(win).transform).m42,
            nav: parseFloat(nav.style.getPropertyValue("--nav-drift")) || 0,
            summary: document
              .querySelector(".selection-column")
              .getBoundingClientRect().top,
          });
          if (frames.length < 30) requestAnimationFrame(frame);
          else resolve(frames);
        };
        requestAnimationFrame(frame);
      }),
  );
  await page.mouse.wheel(0, 500);
  const frames = await sampling;
  expect(Math.max(...frames.map((f) => Math.abs(f.window)))).toBeGreaterThan(
    0.1,
  );
  for (const frame of frames) {
    expect(Math.abs(frame.window)).toBeLessThanOrEqual(4);
    expect(Math.abs(frame.window - frame.nav)).toBeLessThan(0.05);
    expect(frame.summary).toBeCloseTo(frames[0].summary, 1);
  }
  await page
    .getByRole("button", {
      name: "Fluid effects. Use calm appearance",
      exact: true,
    })
    .click();
  await expect(page.locator("#setup-window")).toHaveCSS("transform", "none");
  await page.setViewportSize({ width: 1536, height: 1024 });
  await expect(page.locator("#choose-view .selection-column")).toHaveCount(1);
  await expect(page.locator(".selection-column")).toHaveCSS(
    "position",
    "sticky",
  );
});

test("liquid surfaces follow native selection without replacing focused controls", async ({
  page,
}) => {
  const errors = [];
  page.on("pageerror", (error) => errors.push(error.message));
  await page.goto("/");
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  const railSize = await page.locator("#profiles .liquid-rail").boundingBox();
  const groupSize = await page.locator("#profiles").boundingBox();
  expect(railSize.width).toBeGreaterThan(groupSize.width - 2);

  const developer = page.getByRole("radio", { name: "Developer", exact: true });
  await developer.focus();
  await page.keyboard.press("ArrowRight");
  const education = page.getByRole("radio", { name: "Education", exact: true });
  await expect(education).toBeChecked();
  await expect(education).toBeFocused();
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  const aligned = await page.locator("#profiles").evaluate((group) => {
    const card = group
      .querySelector("input:checked")
      .parentElement.getBoundingClientRect();
    const shape = group
      .querySelector(".liquid-rail g rect:last-child")
      .getBoundingClientRect();
    return (
      Math.abs(card.x + card.width / 2 - shape.x - shape.width / 2) < 1 &&
      Math.abs(card.y + card.height / 2 - shape.y - shape.height / 2) < 1
    );
  });
  expect(aligned).toBe(true);

  const development = page
    .locator("#categories")
    .getByRole("button", { name: "Development", exact: true });
  await development.focus();
  await page.keyboard.press("Enter");
  await expect(development).toBeFocused();
  const code = page.getByRole("checkbox", {
    name: "Visual Studio Code",
    exact: true,
  });
  await code.focus();
  await page.keyboard.press("Space");
  await expect(code).toBeChecked();
  await expect(code).toBeFocused();
  await page.keyboard.press("Space");
  await expect(code).not.toBeChecked();
  await expect(code).toBeFocused();
  const firstRemoval = page.locator("#selected-chips button").first();
  const removalName = await firstRemoval.getAttribute("aria-label");
  await firstRemoval.focus();
  await page.keyboard.press("Enter");
  await expect(
    page.getByRole("button", { name: removalName, exact: true }),
  ).toHaveCount(0);
  await expect(page.locator("#selected-chips button").first()).toBeFocused();
  expect(errors).toEqual([]);
});

test("calm appearance persists and system reduced motion cannot be overridden", async ({
  page,
}) => {
  await page.emulateMedia({ reducedMotion: "reduce" });
  await page.goto("/");
  await expect(page.locator("html")).toHaveAttribute("data-motion", "reduced");
  await expect(page.locator("html")).toHaveAttribute(
    "data-transparency",
    "solid",
  );
  await page.getByRole("radio", { name: "Developer", exact: true }).check();
  await page
    .getByRole("button", {
      name: "Calm appearance. Use fluid effects",
      exact: true,
    })
    .click();
  await expect(page.locator("html")).toHaveAttribute("data-effects", "liquid");
  await expect(page.locator("html")).toHaveAttribute("data-motion", "reduced");
  expect(
    await page.evaluate(
      () =>
        document
          .getAnimations()
          .filter((animation) => animation.playState === "running").length,
    ),
  ).toBe(0);
  await page
    .getByRole("button", {
      name: "Fluid effects. Use calm appearance",
      exact: true,
    })
    .click();
  await page.reload();
  await expect(page.locator("html")).toHaveAttribute("data-effects", "calm");
  await expect(page.locator("html")).toHaveAttribute(
    "data-transparency",
    "solid",
  );
  await page.getByRole("button", { name: "How it works", exact: true }).focus();
  await page.keyboard.press("Enter");
  await expect(page.getByRole("dialog")).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(page.getByRole("dialog")).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: "How it works", exact: true }),
  ).toBeFocused();
});
