// Theme.qml
// Every colour, size and timing in the shell comes from here, so changing
// the theme, accent or animation speed in Config updates everything at once.
// Values follow the Spec and Components boards of the design.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  // Typed groups, so tools and qmllint can see every token
  component SizeTokens: QtObject {
    // Settings → Bar & panels → Size
    readonly property int barStep: Config.bar.size === "compact" ? -1 : Config.bar.size === "large" ? 1 : 0
    readonly property int bar: 44 + barStep * 6
    readonly property int barItem: 30 + barStep * 4
    readonly property int button: 36
    readonly property int buttonSmall: 32
    readonly property int buttonList: 28
    readonly property int buttonRow: 26
    readonly property int input: 36
    readonly property int search: 44
    readonly property int slider: 38
    readonly property int toggle: 52
    readonly property int row: 44
  }

  component SpaceTokens: QtObject {
    readonly property int xs: 4
    readonly property int s: 6
    readonly property int m: 8
    readonly property int l: 12
    readonly property int xl: 16
    readonly property int xxl: 24
  }

  component FontTokens: QtObject {
    readonly property string family: Config.appearance.fontFamily
    readonly property real scale: Config.appearance.fontScale
    readonly property int label: Math.round(10 * scale)
    readonly property int small: Math.round(11 * scale)
    readonly property int body: Math.round(12 * scale)
    readonly property int title: Math.round(14 * scale)
    readonly property int section: Math.round(20 * scale)
  }

  component AnimTokens: QtObject {
    property real speed: 1
    readonly property int fast: Math.round(120 * speed)
    readonly property int toggle: Math.round(160 * speed)
    readonly property int segment: Math.round(200 * speed)
    readonly property int panelIn: Math.round(180 * speed)
    readonly property int panelOut: Math.round(140 * speed)
    readonly property int stack: Math.round(240 * speed)
    readonly property int osd: Math.round(150 * speed)
    readonly property int wallpaper: Math.round(600 * speed)
    // Use with easing.type: Easing.BezierSpline
    readonly property var emphasized: [0.05, 0.7, 0.1, 1, 1, 1]
    readonly property var accelerate: [0.3, 0, 0.8, 0.15, 1, 1]
    readonly property var standard: [0.2, 0.8, 0.2, 1, 1, 1]
  }


  readonly property var palette: Palettes.byName(Config.appearance.theme)
  readonly property bool light: palette.light

  // --- Colours -------------------------------------------------------------
  readonly property color crust: palette.crust
  readonly property color base: palette.base
  readonly property color surface: palette.surface
  readonly property color overlay: palette.overlay
  readonly property color text: palette.text
  readonly property color subtext: palette.subtext
  readonly property color accent: {
    const a = Config.appearance.accent;
    if (a === "wallpaper") return wallpaperAccent ?? palette.accent;
    return /^#[0-9a-fA-F]{6}$/.test(a) ? a : palette.accent;
  }
  // The wallpaper's accent in this theme's lightness; undefined until made
  readonly property var wallpaperAccent: {
    const w = Config.appearance.wallpaperAccent;
    if (w?.hue === undefined) return undefined;
    return Qt.hsla(w.hue, w.sat, light ? 0.42 : 0.72, 1);
  }
  // Text on top of the accent: dark on dark themes, light on light themes
  readonly property color onAccent: light ? palette.base : palette.crust
  readonly property color good: palette.good
  readonly property color warn: palette.warn
  readonly property color error: palette.error

  // Glass: panels are translucent; the blur itself comes from Hyprland
  // (layerrule blur on the quickshell namespace)
  readonly property real glass: Config.appearance.glass
  readonly property color panel: Qt.rgba(base.r, base.g, base.b, glass)
  // Menus and panels with text to read (Settings → Theme → Panels)
  readonly property color panelSolid: Qt.rgba(base.r, base.g, base.b, Math.max(0.5, Math.min(1, Config.appearance.panelOpacity)))
  // Bar style "pills": no bar behind them, so every pill gets the glass
  readonly property bool barPills: Config.bar.style === "pills"
  readonly property color barItem: barPills ? panel : item
  readonly property bool borders: Config.appearance.borders
  readonly property bool shadows: Config.appearance.shadows
  readonly property color item: light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(crust.r, crust.g, crust.b, 0.45)
  readonly property color border: light ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, 0.14)
  readonly property color highlight: light ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.22)
  readonly property color hairline: light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(1, 1, 1, 0.05)

  function alpha(c: color, a: real): color {
    return Qt.rgba(c.r, c.g, c.b, a);
  }

  // Slightly lighter on dark themes, slightly darker on light ones
  function hover(c: color): color {
    return light ? Qt.darker(c, 1.06) : Qt.lighter(c, 1.18);
  }

  // --- Shape ---------------------------------------------------------------
  // Every control is a pill: radius = height / 2. Settings → Theme →
  // Corners scales every radius, down to square.
  readonly property real roundness: Math.max(0, Math.min(1, Config.appearance.roundness))
  function pill(height: real): real {
    return height / 2 * roundness;
  }
  // A radius from the design, scaled the same way
  function r(radius: real): real {
    return radius * roundness;
  }
  readonly property real radiusPanel: 18 * roundness
  readonly property real radiusCard: 14 * roundness

  // --- Sizes ---------------------------------------------------------------
  readonly property SizeTokens size: SizeTokens {}

  // --- Spacing -------------------------------------------------------------
  readonly property SpaceTokens space: SpaceTokens {}

  // --- Type ----------------------------------------------------------------
  readonly property FontTokens font: FontTokens {}

  // --- Motion --------------------------------------------------------------
  // Speed from Settings: off, slow, normal, fast
  // Durations are multiplied by this: 0 is off. The slider's rate (2 = twice
  // as fast) wins; the old Slow / Fast steps count until it's moved.
  readonly property real speed: {
    const step = Config.animations.speed;
    if (step === 0) return 0;
    const rate = Config.animations.rate;
    if (rate !== 1 || step === 2) return 1 / Math.max(0.25, Math.min(2, rate));
    return [0, 1.5, 1, 0.6][step] ?? 1;
  }

  readonly property AnimTokens anim: AnimTokens { speed: root.speed }
}
