// Input.qml
// Keyboard and mouse settings for Settings → Keyboard & mouse.
// The current values are read from Hyprland (hyprctl getoption). A change is
// applied right away with `hyprctl eval` and saved to hyprland/input.lua,
// which hyprland/quickshell.lua loads last (per machine, not in git; delete
// it to use your own input config again).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool loaded: false
  property string layouts: "us"
  property string variants: ""
  property string options: ""
  property int repeatRate: 25
  property int repeatDelay: 600
  property real sensitivity: 0
  // "" (Hyprland's default, adaptive), "flat" or "adaptive"
  property string accelProfile: ""
  property bool naturalScroll: false
  property int followMouse: 1
  property bool numlock: false
  property bool hideWhileTyping: false
  property string cursorTheme: Quickshell.env("XCURSOR_THEME") || "Adwaita"
  property int cursorSize: parseInt(Quickshell.env("XCURSOR_SIZE") || "24")

  readonly property bool capsIsEscape: options.split(",").some(o => o.startsWith("caps:escape"))

  function refresh(): void {
    read.running = true;
    themes.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: read
    command: ["sh", "-c",
      "for o in input:kb_layout input:kb_variant input:kb_options input:repeat_rate input:repeat_delay input:sensitivity " +
      "input:accel_profile input:natural_scroll input:follow_mouse input:numlock_by_default cursor:hide_on_key_press; do " +
      "printf '%s=' \"$o\"; hyprctl getoption \"$o\" -j 2>/dev/null | tr -d '\\n'; echo; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        for (const line of text.split("\n")) {
          const i = line.indexOf("=");
          if (i < 0) continue;
          let v;
          try {
            const j = JSON.parse(line.slice(i + 1));
            v = j.str ?? j.int ?? j.float ?? j.bool;
            if (v === "[[EMPTY]]") v = "";
          } catch (e) {
            continue;
          }
          switch (line.slice(0, i)) {
          case "input:kb_layout": root.layouts = v; break;
          case "input:kb_variant": root.variants = v; break;
          case "input:kb_options": root.options = v; break;
          case "input:repeat_rate": root.repeatRate = v; break;
          case "input:repeat_delay": root.repeatDelay = v; break;
          case "input:sensitivity": root.sensitivity = v; break;
          case "input:accel_profile": root.accelProfile = v; break;
          case "input:natural_scroll": root.naturalScroll = v === true || v === 1; break;
          case "input:follow_mouse": root.followMouse = v; break;
          case "input:numlock_by_default": root.numlock = v === true || v === 1; break;
          case "cursor:hide_on_key_press": root.hideWhileTyping = v === true || v === 1; break;
          }
        }
        root.loaded = true;
      }
    }
  }

  // Installed cursor themes (folders with a cursors/ directory)
  property var cursorThemes: []

  Process {
    id: themes
    command: ["sh", "-c", "for d in /usr/share/icons/* \"$HOME/.icons\"/* \"$HOME/.local/share/icons\"/*; do [ -d \"$d/cursors\" ] && basename \"$d\"; done; true"]
    stdout: StdioCollector {
      onStreamFinished: root.cursorThemes = [...new Set(text.split("\n").filter(t => t !== ""))].sort()
    }
  }

  // --- Changing ---------------------------------------------------------------------
  function luaString(s: string): string {
    return "\"" + s.replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\"";
  }

  readonly property string configLua: "hl.config({ input = { kb_layout = " + luaString(layouts) + ", kb_variant = " + luaString(variants)
    + ", kb_options = " + luaString(options) + ", repeat_rate = " + repeatRate + ", repeat_delay = " + repeatDelay
    + ", sensitivity = " + sensitivity.toFixed(2) + ", accel_profile = " + luaString(accelProfile)
    + ", natural_scroll = " + naturalScroll + ", follow_mouse = " + followMouse + ", numlock_by_default = " + numlock
    + " }, cursor = { hide_on_key_press = " + hideWhileTyping + " } })"

  property string error: ""

  // Set one or more values, then apply and save them all
  function set(values: var): void {
    for (const key of Object.keys(values)) root[key] = values[key];
    applyDelay.restart();
  }

  // Sliders send many values; apply once they settle
  Timer {
    id: applyDelay
    interval: 250
    onTriggered: {
      root.error = "";
      apply.command = ["hyprctl", "eval", root.configLua];
      apply.running = true;
    }
  }

  Process {
    id: apply
    stdout: StdioCollector {
      onStreamFinished: {
        if (text.trim().startsWith("error")) {
          root.error = text.trim();
          return;
        }
        save.running = true;
      }
    }
  }

  function setCursor(theme: string, size: int): void {
    cursorTheme = theme;
    cursorSize = size;
    Quickshell.execDetached(["hyprctl", "setcursor", theme, String(size)]);
    save.running = true;
  }

  Process {
    id: save
    command: ["sh", "-c", "printf '%s\\n' \"$2\" > \"$1\"", "sh", Quickshell.shellPath("hyprland/input.lua"),
      "-- Made by Settings → Keyboard & mouse. Delete this file to use your own input config again.\n"
      + root.configLua + "\n"
      + "hl.env(\"XCURSOR_THEME\", " + root.luaString(root.cursorTheme) + ")\n"
      + "hl.env(\"XCURSOR_SIZE\", \"" + root.cursorSize + "\")\n"
      + "hl.on(\"hyprland.start\", function() hl.exec_cmd(\"hyprctl setcursor " + root.cursorTheme + " " + root.cursorSize + "\") end)"]
  }

  // --- Layouts --------------------------------------------------------------------------
  // Common xkb layouts: [code, name]
  readonly property var knownLayouts: [
    ["us", "English (US)"], ["gb", "English (UK)"], ["us(intl)", "English (US, international)"], ["nl", "Dutch"],
    ["be", "Belgian"], ["de", "German"], ["fr", "French"], ["es", "Spanish"], ["it", "Italian"], ["pt", "Portuguese"],
    ["se", "Swedish"], ["no", "Norwegian"], ["dk", "Danish"], ["fi", "Finnish"], ["pl", "Polish"], ["cz", "Czech"],
    ["tr", "Turkish"], ["ru", "Russian"], ["ua", "Ukrainian"], ["gr", "Greek"], ["jp", "Japanese"], ["kr", "Korean"],
    ["ara", "Arabic"], ["il", "Hebrew"]
  ]

  // [{ code, variant }] from "us,nl" and ",intl"
  readonly property var layoutList: {
    const codes = layouts.split(",").map(s => s.trim()).filter(s => s !== "");
    const vars = variants.split(",");
    return codes.map((code, i) => ({ code, variant: (vars[i] ?? "").trim() }));
  }

  function layoutName(entry: var): string {
    const key = entry.variant !== "" ? entry.code + "(" + entry.variant + ")" : entry.code;
    return (knownLayouts.find(k => k[0] === key) ?? [key, key])[1];
  }

  function setLayouts(list: var): void {
    if (list.length === 0) return;
    set({ layouts: list.map(l => l.code).join(","), variants: list.some(l => l.variant !== "") ? list.map(l => l.variant).join(",") : "" });
  }

  function addLayout(key: string): void {
    const m = key.match(/^(\w+)(?:\((\w+)\))?$/);
    if (!m) return;
    setLayouts(layoutList.concat([{ code: m[1], variant: m[2] ?? "" }]));
  }

  function removeLayout(index: int): void {
    setLayouts(layoutList.filter((l, i) => i !== index));
  }

  // Turns one xkb option on or off, e.g. "caps:escape_shifted_capslock";
  // options with the same group ("caps:…") replace each other
  function setOption(option: string, on: bool): void {
    const group = option.split(":")[0] + ":";
    const rest = options.split(",").filter(o => o !== "" && !o.startsWith(group));
    set({ options: (on ? rest.concat([option]) : rest).join(",") });
  }

  function setCapsEscape(on: bool): void {
    setOption("caps:escape_shifted_capslock", on);
  }

  readonly property bool altShiftSwitch: options.split(",").indexOf("grp:alt_shift_toggle") >= 0
}
