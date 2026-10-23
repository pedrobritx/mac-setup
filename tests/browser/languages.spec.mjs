import { test, expect } from "@playwright/test";
import AxeBuilder from "@axe-core/playwright";
import path from "node:path";

test("five languages keep choices, translate new renders and persist across Safety", async ({
  page,
}) => {
  await page.setViewportSize({ width: 932, height: 932 });
  await page.goto("/");
  await expect(page.locator("#profiles")).toHaveAttribute(
    "data-liquid-state",
    "settled",
  );
  await page.getByRole("radio", { name: "Developer", exact: true }).check();
  const savedPlan = await page.evaluate(() =>
    localStorage.getItem("mac-setup.plan.v1"),
  );
  const choose = async (name, id) => {
    await page.locator("#language-trigger").click();
    await page.getByRole("option", { name, exact: true }).click();
    await expect(page.locator("html")).toHaveAttribute("lang", id);
  };
  for (const [name, id, heading, review] of [
    [
      "Português (Brasil)",
      "pt-BR",
      "Deixe este Mac com a sua cara.",
      "Revisar configuração",
    ],
    ["Français", "fr-FR", "Un Mac à votre image.", "Vérifier la configuration"],
    [
      "Deutsch",
      "de-DE",
      "Mach diesen Mac zu deinem.",
      "Einrichtung überprüfen",
    ],
    [
      "Español (España)",
      "es-ES",
      "Haz este Mac tuyo.",
      "Revisar configuración",
    ],
    ["English (UK)", "en-GB", "Make this Mac yours.", "Review setup"],
  ]) {
    await choose(name, id);
    await expect(page.locator("#page-title")).toHaveText(heading);
    await expect(page.locator("#review-button")).toHaveText(new RegExp(review));
    expect(
      await page.evaluate(() => localStorage.getItem("mac-setup.plan.v1")),
    ).toBe(savedPlan);
    await page.locator("#review-button").click();
    await expect(page.locator("#review-view")).toBeVisible();
    await page.locator("#back-button").click();
    expect(
      await page.evaluate(() =>
        document.querySelector(".selection-column").closest(".setup-window"),
      ),
    ).toBeNull();
    expect(
      await page.evaluate(
        () => document.documentElement.scrollWidth <= innerWidth,
      ),
    ).toBe(true);
    const result = await new AxeBuilder({ page })
      .withTags(["wcag2a", "wcag2aa", "wcag21aa"])
      .analyze();
    expect(
      result.violations.map((v) => ({
        id: v.id,
        nodes: v.nodes.map((n) => n.target),
      })),
    ).toEqual([]);
    for (const width of [390, 320]) {
      await page.setViewportSize({ width, height: 844 });
      // The measured SVG surfaces need a resize frame before layout is settled.
      await expect
        .poll(() => page.evaluate(() => document.documentElement.scrollWidth))
        .toBeLessThanOrEqual(width);
      await expect(page.locator("#language-trigger")).toBeVisible();
    }
    await page.setViewportSize({ width: 932, height: 932 });
  }
  // Keyboard selection and dismissal use the same listbox contract as Source.
  await page.locator("#language-trigger").focus();
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("End");
  await expect(
    page.getByRole("option", { name: "Español (España)", exact: true }),
  ).toBeFocused();
  await page.keyboard.press("Enter");
  await expect(page.locator("html")).toHaveAttribute("lang", "es-ES");
  await page.keyboard.press("ArrowDown");
  await page.keyboard.press("Escape");
  await expect(page.locator("#language-options")).not.toBeVisible();
  await expect(page.locator("#language-trigger")).toBeFocused();
  await choose("Português (Brasil)", "pt-BR");
  await expect(
    page.getByRole("button", {
      name: "Selecionar tudo em Desenvolvimento",
      exact: true,
    }),
  ).toHaveAttribute(
    "title",
    "Selecionar todos os 36 itens de Desenvolvimento, incluindo os ocultos pelos filtros. Os pré-requisitos obrigatórios são incluídos.",
  );
  await page.getByRole("searchbox").fill("Contêineres");
  await expect(
    page.getByRole("checkbox", { name: "Docker Desktop", exact: true }),
  ).toBeVisible();
  await choose("English (UK)", "en-GB");
  await expect(
    page.getByRole("checkbox", { name: "Docker Desktop", exact: true }),
  ).toHaveCount(0);
  await choose("Português (Brasil)", "pt-BR");
  await expect(
    page.getByRole("checkbox", { name: "Docker Desktop", exact: true }),
  ).toBeVisible();
  await page.getByRole("searchbox").fill("");
  await page.locator("#language-trigger").click();
  await page.screenshot({
    path: path.resolve("outputs/preview-language-picker.png"),
    animations: "disabled",
  });
  await page.keyboard.press("Escape");
  await page.screenshot({
    path: path.resolve("outputs/preview-portuguese.png"),
    animations: "disabled",
  });
  await page.setViewportSize({ width: 390, height: 844 });
  await page.screenshot({
    path: path.resolve("outputs/preview-portuguese-mobile.png"),
    animations: "disabled",
  });
  await page.setViewportSize({ width: 932, height: 932 });
  await page.locator('.nav-actions a[href="safety.html"]').click();
  await expect(page.locator("html")).toHaveAttribute("lang", "pt-BR");
  await expect(page.locator("#safety-title")).toHaveText(
    "Sua configuração fica com você.",
  );
  await page.setViewportSize({ width: 390, height: 844 });
  expect(
    await page.evaluate(
      () => document.documentElement.scrollWidth <= innerWidth,
    ),
  ).toBe(true);
  await page.screenshot({
    path: path.resolve("outputs/preview-portuguese-safety-mobile.png"),
    animations: "disabled",
  });
});
