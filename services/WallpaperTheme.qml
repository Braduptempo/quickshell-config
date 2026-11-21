// WallpaperTheme.qml
// The "Wallpaper" theme: colours picked from the main screen's wallpaper with
// Quickshell's ColorQuantizer, kept in Config.appearance.wallpaperPalette and
// made again whenever the wallpaper changes. Palettes lists it like a theme.
//   Light or dark follows the picture (Settings → Theme → From wallpaper:
//   Auto), or is set by hand.
pragma Singleton

import QtQuick
import Quickshell
import "../config"

Singleton {
  id: root

  readonly property string path: {
    const map = Object.assign({}, Wallpapers.current, Wallpapers.videos);
    const file = map[Config.displays.primary] ?? Object.values(map)[0] ?? "";
    // A video: its still frame
    return Wallpapers.isVideo(file) ? Wallpapers.posterFor(file) : file;
  }
  readonly property bool active: Config.appearance.theme === "Wallpaper"
  // Read the picture only when the theme is in use or being shown
  property bool wanted: active

  ColorQuantizer {
    id: quantizer
    source: root.wanted && root.path !== "" ? "file://" + root.path : ""
    // 2^4 = 16 colours from a small copy of the picture
    depth: 4
    rescaleSize: 96
    onColorsChanged: root.build()
  }

  function clamp(v: real, lo: real, hi: real): real {
    return Math.max(lo, Math.min(hi, v));
  }

  function hex(c: color): string {
    const h = v => Math.round(clamp(v, 0, 1) * 255).toString(16).padStart(2, "0");
    return "#" + h(c.r) + h(c.g) + h(c.b);
  }

  function hsl(h: real, s: real, l: real): string {
    return hex(Qt.hsla(((h % 1) + 1) % 1, clamp(s, 0, 1), clamp(l, 0, 1), 1));
  }

  function build(): void {
    const list = quantizer.colors ?? [];
    if (list.length === 0) return;

    // The picture's overall lightness
    const lum = c => 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    const avg = list.reduce((sum, c) => sum + lum(c), 0) / list.length;
    const mode = Config.appearance.wallpaperMode;
    const light = mode === "light" || (mode === "auto" && avg > 0.62);

    // The accent: the most colourful colour that isn't nearly black or white
    const vivid = list.slice().sort((a, b) => (b.hsvSaturation * b.hsvValue) - (a.hsvSaturation * a.hsvValue));
    const pick = vivid.find(c => c.hsvValue > 0.35 && c.hsvSaturation > 0.25) ?? vivid[0];
    const hue = pick.hslHue < 0 ? 0.6 : pick.hslHue;
    const sat = clamp(pick.hslSaturation, 0.45, 0.85);

    // The background: the picture's most common hue, nearly grey
    const base = list[0];
    const bgHue = base.hslHue < 0 ? hue : base.hslHue;
    const bgSat = clamp(base.hslSaturation * 0.35, 0.04, 0.22);

    const p = light ? {
      light: true,
      crust: hsl(bgHue, bgSat, 0.88), base: hsl(bgHue, bgSat, 0.95), surface: hsl(bgHue, bgSat, 0.84), overlay: hsl(bgHue, bgSat, 0.75),
      text: hsl(bgHue, bgSat, 0.18), subtext: hsl(bgHue, bgSat, 0.38),
      accent: hsl(hue, sat, 0.42), good: hsl(0.36, 0.55, 0.36), warn: hsl(0.10, 0.75, 0.42), error: hsl(0.97, 0.7, 0.45)
    } : {
      light: false,
      crust: hsl(bgHue, bgSat, 0.07), base: hsl(bgHue, bgSat, 0.11), surface: hsl(bgHue, bgSat, 0.19), overlay: hsl(bgHue, bgSat, 0.27),
      text: hsl(bgHue, bgSat * 0.6, 0.88), subtext: hsl(bgHue, bgSat * 0.6, 0.70),
      accent: hsl(hue, sat, 0.72), good: hsl(0.33, 0.5, 0.72), warn: hsl(0.11, 0.8, 0.76), error: hsl(0.97, 0.75, 0.74)
    };
    p.name = "Wallpaper";
    p.source = root.path;
    // Only write when something changed (it lands in settings.json)
    if (JSON.stringify(p) !== JSON.stringify(Config.appearance.wallpaperPalette)) Config.appearance.wallpaperPalette = p;
  }

  // Light or dark changed in Settings: make it again
  Connections {
    target: Config.appearance
    function onWallpaperModeChanged() { root.build(); }
  }
}
