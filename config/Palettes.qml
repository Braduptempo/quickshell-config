// Palettes.qml
// Colour palettes for the theme picker. Every palette has the same keys,
// so a component never needs to know which theme is active.
// Your own themes (Settings → Theme → New theme) live in settings.json under
// appearance.customThemes and come after the built-in ones, with custom: true.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  readonly property var builtIn: [
    { name: "Mocha",      light: false, crust: "#11111b", base: "#1e1e2e", surface: "#313244", overlay: "#45475a", text: "#cdd6f4", subtext: "#a6adc8", accent: "#89b4fa", good: "#a6e3a1", warn: "#f9e2af", error: "#f38ba8", dots: ["#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#89b4fa", "#cba6f7"] },
    { name: "Midnight",   light: false, crust: "#13141c", base: "#1a1b26", surface: "#292e42", overlay: "#414868", text: "#c0caf5", subtext: "#a9b1d6", accent: "#7aa2f7", good: "#9ece6a", warn: "#e0af68", error: "#f7768e", dots: ["#f7768e", "#ff9e64", "#e0af68", "#9ece6a", "#7aa2f7", "#bb9af7"] },
    { name: "Forest",     light: false, crust: "#1a2023", base: "#232a2e", surface: "#343f44", overlay: "#475258", text: "#d3c6aa", subtext: "#9da9a0", accent: "#7fbbb3", good: "#a7c080", warn: "#dbbc7f", error: "#e67e80", dots: ["#e67e80", "#e69875", "#dbbc7f", "#a7c080", "#7fbbb3", "#d699b6"] },
    { name: "Rose",       light: false, crust: "#191724", base: "#232136", surface: "#393552", overlay: "#44415a", text: "#e0def4", subtext: "#908caa", accent: "#c4a7e7", good: "#9ccfd8", warn: "#f6c177", error: "#eb6f92", dots: ["#eb6f92", "#f6c177", "#ea9a97", "#3e8fb0", "#9ccfd8", "#c4a7e7"] },
    { name: "Ice",        light: false, crust: "#242933", base: "#2e3440", surface: "#3b4252", overlay: "#4c566a", text: "#eceff4", subtext: "#d8dee9", accent: "#88c0d0", good: "#a3be8c", warn: "#ebcb8b", error: "#bf616a", dots: ["#bf616a", "#d08770", "#ebcb8b", "#a3be8c", "#88c0d0", "#b48ead"] },
    { name: "Ember",      light: false, crust: "#1d2021", base: "#282828", surface: "#3c3836", overlay: "#504945", text: "#ebdbb2", subtext: "#a89984", accent: "#83a598", good: "#b8bb26", warn: "#fabd2f", error: "#fb4934", dots: ["#fb4934", "#fe8019", "#fabd2f", "#b8bb26", "#83a598", "#d3869b"] },
    { name: "Wave",       light: false, crust: "#16161d", base: "#1f1f28", surface: "#2a2a37", overlay: "#363646", text: "#dcd7ba", subtext: "#c8c093", accent: "#7e9cd8", good: "#98bb6c", warn: "#e6c384", error: "#e46876", dots: ["#e46876", "#ffa066", "#e6c384", "#98bb6c", "#7e9cd8", "#957fb8"] },
    { name: "Neon",       light: false, crust: "#16161c", base: "#1c1e26", surface: "#2e303e", overlay: "#3d4050", text: "#e0e0e0", subtext: "#a0a2b0", accent: "#26bbd9", good: "#29d398", warn: "#fab795", error: "#e95678", dots: ["#e95678", "#fab795", "#fac29a", "#29d398", "#26bbd9", "#ee64ac"] },
    { name: "Mono dark",  light: false, crust: "#0a0a0a", base: "#101010", surface: "#2a2a2a", overlay: "#3a3a3a", text: "#f5f5f5", subtext: "#9a9a9a", accent: "#f5f5f5", good: "#4ade80", warn: "#facc15", error: "#ff4d4d", dots: ["#f5f5f5", "#d4d4d4", "#a3a3a3", "#737373", "#525252", "#ff4d4d"] },
    { name: "Paper",      light: true,  crust: "#dce0e8", base: "#eff1f5", surface: "#ccd0da", overlay: "#bcc0cc", text: "#4c4f69", subtext: "#6c6f85", accent: "#1e66f5", good: "#40a02b", warn: "#df8e1d", error: "#d20f39", dots: ["#d20f39", "#fe640b", "#df8e1d", "#40a02b", "#1e66f5", "#8839ef"] },
    { name: "Sand",       light: true,  crust: "#f2e5bc", base: "#fbf1c7", surface: "#ebdbb2", overlay: "#d5c4a1", text: "#3c3836", subtext: "#7c6f64", accent: "#076678", good: "#79740e", warn: "#b57614", error: "#9d0006", dots: ["#9d0006", "#af3a03", "#b57614", "#79740e", "#076678", "#8f3f71"] },
    { name: "Mono light", light: true,  crust: "#e5e5e5", base: "#f5f5f5", surface: "#d6d6d6", overlay: "#c4c4c4", text: "#111111", subtext: "#5f5f5f", accent: "#111111", good: "#15803d", warn: "#a16207", error: "#dc2626", dots: ["#111111", "#3a3a3a", "#5f5f5f", "#8a8a8a", "#bdbdbd", "#dc2626"] }
  ]

  // The colours a theme is made of, in the order the editor shows them
  readonly property var keys: ["base", "surface", "overlay", "crust", "text", "subtext", "accent", "good", "warn", "error"]

  // A saved custom theme, completed: missing colours come from Mocha, and the
  // preview dots are made from its own colours
  function complete(t: var): var {
    const p = Object.assign({}, builtIn[0], t, { custom: true });
    p.dots = [p.error, p.warn, p.good, p.accent, p.subtext, p.text];
    return p;
  }

  readonly property var custom: (Config.appearance.customThemes ?? []).map(t => complete(t))
  readonly property var list: builtIn.concat(custom)
  readonly property var names: list.map(p => p.name)

  function byName(name: string): var {
    for (let i = 0; i < list.length; i++) {
      if (list[i].name === name) return list[i];
    }
    return list[0];
  }

  function isValidColor(c: string): bool {
    return /^#[0-9a-fA-F]{6}$/.test(c);
  }

  // --- Your own themes --------------------------------------------------------------------
  // Only the stored fields, never the computed dots / custom flag
  function stored(p: var): var {
    const t = { name: p.name, light: p.light };
    for (const k of keys) t[k] = p[k];
    return t;
  }

  // A copy of the current theme under a free name, chosen right away
  function create(from: var): string {
    let n = 1;
    let name = "My theme";
    while (names.indexOf(name) >= 0) name = "My theme " + (++n);
    const t = stored(from);
    t.name = name;
    Config.appearance.customThemes = (Config.appearance.customThemes ?? []).concat([t]);
    Config.appearance.theme = name;
    return name;
  }

  function update(name: string, changes: var): void {
    Config.appearance.customThemes = (Config.appearance.customThemes ?? []).map(t => t.name === name ? Object.assign({}, t, changes) : t);
  }

  // false when the name is empty or taken
  function rename(from: string, to: string): bool {
    to = to.trim();
    if (to === "" || to === from) return to === from;
    if (names.indexOf(to) >= 0) return false;
    const chosen = Config.appearance.theme === from;
    update(from, { name: to });
    if (chosen) Config.appearance.theme = to;
    return true;
  }

  function remove(name: string): void {
    if (Config.appearance.theme === name) Config.appearance.theme = builtIn[0].name;
    Config.appearance.customThemes = (Config.appearance.customThemes ?? []).filter(t => t.name !== name);
  }
}
