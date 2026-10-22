import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import { readFile } from "node:fs/promises";
import path from "node:path";

const ready = async (page) =>
  expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
const capture = (page, name) =>
  page.screenshot({
    path: path.resolve("outputs", name),
    animations: "disabled",
  });
const axe = async (page) => {
  const result = await new AxeBuilder({ page })
    .withTags(["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"])
    .analyze();
  expect(
    result.violations.map((entry) => ({
      id: entry.id,
      nodes: entry.nodes.map((node) => node.target),
    })),
  ).toEqual([]);
};

test("the source picker supports keyboard selection, dismissal and the floating summary", async ({
  page,
}) => {
  await page.setViewportSize({ width: 932, height: 932 });
  await page.goto("/");
  await ready(page);
  const trigger = page.getByRole("button", {
    name: "Source All sources",
    exact: true,
  });
  await trigger.focus();
  await page.keyboard.press("ArrowDown");
  const list = page.getByRole("listbox", { name: "Source", exact: true });
  await expect(list).toBeVisible();
  await expect(
    page.getByRole("option", { name: "All sources", exact: true }),
  ).toBeFocused();
  await expect(page.locator("#source-options")).toHaveAttribute(
    "data-side",
    "above",
  );
  const menuBounds = await list.boundingBox();
  const summaryBounds = await page.locator(".selection-column").boundingBox();
  expect(menuBounds.y + menuBounds.height).toBeLessThan(summaryBounds.y);
  await capture(page, "preview-source-picker.png");
  await axe(page);
  await page.keyboard.press("h");
  await expect(
    page.getByRole("option", { name: "Homebrew", exact: true }),
  ).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(
    page.getByRole("button", { name: "Source Homebrew", exact: true }),
  ).toBeFocused();
  await expect(
    page.getByRole("checkbox", { name: "Visual Studio Code", exact: true }),
  ).toBeVisible();
  await expect(
    page.getByRole("checkbox", { name: "Slack", exact: true }),
  ).toHaveCount(0);
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("End");
  await expect(
    page.getByRole("option", { name: "Guided follow-up", exact: true }),
  ).toBeFocused();
  await page.keyboard.press("Escape");
  await expect(list).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: "Source Homebrew", exact: true }),
  ).toBeFocused();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Tab");
  await expect(list).not.toBeVisible();
  await expect(
    page.getByRole("button", { name: "Source Homebrew", exact: true }),
  ).not.toBeFocused();
  await page
    .getByRole("button", { name: "Source Homebrew", exact: true })
    .click();
  await page.getByRole("searchbox").click();
  await expect(list).not.toBeVisible();
});

test("category selection includes hidden items, retains focus and survives reload", async ({
  page,
}) => {
  const catalog = JSON.parse(
    await readFile(new URL("../../docs/assets/catalog.json", import.meta.url)),
  );
  await page.goto("/");
  await ready(page);
  await page.getByRole("searchbox").fill("Python");
  const action = page.getByRole("button", {
    name: "Select all Development",
    exact: true,
  });
  await action.focus();
  await page.keyboard.press("Enter");
  await expect(action).toBeFocused();
  await expect(action).toHaveAttribute("aria-disabled", "true");
  const saved = await page.evaluate(() =>
    JSON.parse(localStorage.getItem("mac-setup.plan.v1")),
  );
  const ids = catalog.items
    .filter((item) => item.category === "development")
    .map((item) => item.id);
  expect(saved.selected).toEqual(expect.arrayContaining(ids));
  for (const item of catalog.items.filter((item) =>
    saved.selected.includes(item.id),
  ))
    expect(saved.selected).toEqual(expect.arrayContaining(item.dependencies));
  await page.reload();
  await ready(page);
  await expect(
    page.getByRole("checkbox", { name: "Docker Desktop", exact: true }),
  ).toBeChecked();
  await expect(
    page.getByRole("button", { name: "Select all Development", exact: true }),
  ).toHaveAttribute("aria-disabled", "true");
  await capture(page, "preview-category-selection.png");
});

test("the visual guide dismisses from its backdrop and returns keyboard focus", async ({
  page,
}) => {
  await page.goto("/");
  await ready(page);
  const how = page.getByRole("button", { name: "How it works", exact: true });
  await how.click();
  const dialog = page.getByRole("dialog");
  await expect(dialog.locator(".setup-flow > li")).toHaveCount(3);
  const close = page.getByRole("button", {
    name: "Close details",
    exact: true,
  });
  await expect(dialog).toHaveCSS("opacity", "1");
  const box = await close.boundingBox();
  expect(box.width).toBe(44);
  expect(box.height).toBe(44);
  await expect(close.locator("svg")).toHaveCount(1);
  await expect(dialog).toHaveCSS("opacity", "1");
  await capture(page, "preview-how-it-works.png");
  await axe(page);
  const bounds = await dialog.boundingBox();
  await page.mouse.click(bounds.x - 12, bounds.y + 24);
  await expect(dialog).not.toBeVisible();
  await expect(how).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(dialog).toBeVisible();
  const inside = await dialog.boundingBox();
  await page.mouse.move(inside.x + 40, inside.y + 40);
  await page.mouse.down();
  await page.mouse.move(inside.x - 12, inside.y + 40);
  await page.mouse.up();
  await expect(dialog).toBeVisible();
  await page.keyboard.press("Escape");
  await expect(dialog).not.toBeVisible();
});

test("Safety preserves appearance and links to creator, support and prefilled contributions without external assets", async ({
  page,
}) => {
  const requests = [];
  page.on("request", (request) => requests.push(request.url()));
  await page.goto("/");
  await ready(page);
  await page.getByRole("radio", { name: "Developer", exact: true }).check();
  await page
    .getByRole("button", { name: "Switch to light theme", exact: true })
    .click();
  await page.getByRole("link", { name: "Safety", exact: true }).click();
  await expect(
    page.getByRole("heading", {
      name: "Your setup stays with you.",
      exact: true,
    }),
  ).toBeVisible();
  await expect(page.locator("html")).toHaveAttribute("data-theme", "light");
  await expect(page.locator(".privacy-flow > li")).toHaveCount(3);
  for (const viewport of [
    { width: 932, height: 932 },
    { width: 390, height: 844 },
    { width: 320, height: 760 },
  ]) {
    await page.setViewportSize(viewport);
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= window.innerWidth,
      ),
    ).toBe(true);
    for (const theme of ["light", "dark"]) {
      if ((await page.locator("html").getAttribute("data-theme")) !== theme)
        await page
          .getByRole("button", {
            name: `Switch to ${theme} theme`,
            exact: true,
          })
          .click();
      await axe(page);
    }
    if (viewport.width !== 320)
      await capture(
        page,
        viewport.width === 932
          ? "preview-safety.png"
          : "preview-safety-mobile.png",
      );
  }
  await expect(page.locator(".creator-credit a").first()).toHaveAttribute(
    "href",
    "https://github.com/pedrobritx",
  );
  await expect(page.locator(".creator-credit a").last()).toHaveAttribute(
    "href",
    "https://www.linkedin.com/in/pedrobritx/",
  );
  await expect(
    page.getByRole("link", { name: /Buy me a coffee/ }),
  ).toHaveAttribute("href", "https://buymeacoffee.com/pedrobritx");
  for (const label of ["Suggest software", "Report a problem"]) {
    const link = page.getByRole("link", { name: new RegExp(label) });
    const url = new URL(await link.getAttribute("href"));
    expect(url.origin + url.pathname).toBe(
      "https://github.com/pedrobritx/mac-setup/issues/new",
    );
    expect(url.searchParams.get("body").length).toBeGreaterThan(60);
  }
  await page
    .getByRole("link", { name: "Back to your setup", exact: true })
    .click();
  await expect(
    page.getByRole("radio", { name: "Developer", exact: true }),
  ).toBeChecked();
  const image = page.locator('img[src$="mac-visual-studio-code.png"]').first();
  await expect(image).toBeVisible();
  expect(
    await image.evaluate((node) => node.complete && node.naturalWidth > 0),
  ).toBe(true);
  expect(
    requests.filter((url) => !url.startsWith("http://127.0.0.1:3419/")),
  ).toEqual([]);
});
