const ICONS = {
  leaf: ["M20 4C8 2 3 8 5 15c2 7 14 6 15-11Z", "M5 21 16 10"],
  code: ["m8 5-6 7 6 7m8-14 6 7-6 7M14 3l-4 18"],
  book: [
    "M12 5c-3-3-7-3-10-1v16c3-2 7-2 10 0 3-2 7-2 10 0V4c-3-2-7-2-10 1Zm0 0v15",
  ],
  layers: ["M6 3h12v18H6z", "M9 7h6M9 11h6M9 15h4"],
  pen: ["m15 3 6 6-11 11-7 1 1-7L15 3Zm-2 2 6 6M4 14l6 6"],
  spark: [
    "m12 3 2.8 5.7 6.2.9-4.5 4.4 1.1 6.2-5.6-2.9-5.6 2.9 1.1-6.2L3 9.6l6.2-.9Z",
  ],
  sun: [
    "M16 12a4 4 0 1 0-8 0 4 4 0 0 0 8 0Z",
    "M12 2v2m0 16v2M2 12h2m16 0h2M5 5l1.5 1.5m11 11L19 19M5 19l1.5-1.5m11-11L19 5",
  ],
  moon: ["M20.5 13.2A8.8 8.8 0 0 1 10.8 3.5a8.8 8.8 0 1 0 9.7 9.7Z"],
  chat: [
    "M21 11a9 8 0 0 1-9 8c-1 0-2 0-3-.5L4 21l1-5A8 8 0 0 1 3 11a9 8 0 0 1 18 0Z",
  ],
  sliders: [
    "M5 3v7m0 4v7M12 3v12m0 4v2M19 3v2m0 4v12",
    "M2 10h6M9 15h6M16 5h6",
  ],
  play: ["M8 5v14l12-7Z"],
  terminal: ["m4 5 7 7-7 7m10 0h7"],
  settings: [
    "m9 3 1-1h4l1 1 1 3 3 1 2 3v4l-2 3-3 1-1 3h-6l-1-3-3-1-2-3v-4l2-3 3-1Z",
    "M15 12a3 3 0 1 0-6 0 3 3 0 0 0 6 0",
  ],
  plug: ["m9 15 6-6M8 10l-3 3a4 4 0 0 0 6 6l3-3M10 8l3-3a4 4 0 0 1 6 6l-3 3"],
  all: ["M3 3h6v6H3zM15 3h6v6h-6zM3 15h6v6H3zM15 15h6v6h-6z"],
  laptop: ["M5 4h14v13H5zM2 20h20l-3-3H5Z"],
  arrow: ["M4 12h16m-6-6 6 6-6 6"],
  back: ["M20 12H4m6-6-6 6 6 6"],
  shield: ["m12 2 9 4v7c-1 5-5 8-9 10-4-2-8-5-9-10V6Z"],
  info: ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18ZM12 11v6m0-10v1"],
  close: ["m6 6 12 12M6 18 18 6"],
  check: ["m5 12 5 5L20 7"],
};

export function icon(name) {
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  svg.setAttribute("viewBox", "0 0 24 24");
  svg.setAttribute("aria-hidden", "true");
  for (const path of ICONS[name] || ICONS.layers) {
    const node = document.createElementNS(svg.namespaceURI, "path");
    node.setAttribute("d", path);
    svg.append(node);
  }
  return svg;
}
