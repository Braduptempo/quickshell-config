// KeybindsPage.qml
// Every keybind, read from the Hyprland Lua config: your own files in
// ~/.config/hypr and the shell's hyprland/quickshell.lua. Shell shortcuts get
// a readable name. A combination that's bound twice is marked; one that the
// shell takes over (hl.unbind) is shown as replaced.
// Changing them happens in the files themselves (buttons below).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Keybinds"
  description: "Read from your Hyprland config. To change one, edit the file it comes from; hyprctl reload applies it."

  readonly property string hyprDir: Quickshell.env("HOME") + "/.config/hypr"
  readonly property string shellFile: Quickshell.shellPath("hyprland/quickshell.lua")
  property var binds: []
  property string query: ""

  readonly property var shown: {
    const q = query.trim().toLowerCase();
    return binds.filter(b => q === "" || b.action.toLowerCase().includes(q) || b.keys.toLowerCase().includes(q) || b.group.toLowerCase().includes(q));
  }
  readonly property int conflicts: binds.filter(b => b.conflict).length

  Component.onCompleted: reader.running = true

  // Every Lua file of the config, the shell's file last (it's loaded last)
  Process {
    id: reader
    command: ["sh", "-c",
      "for f in \"$1\"/hyprland.lua \"$1\"/modules/*.lua \"$2\"; do [ -f \"$f\" ] && echo \"@@FILE $f\" && cat \"$f\"; done",
      "sh", page.hyprDir, page.shellFile]
    stdout: StdioCollector {
      onStreamFinished: page.binds = page.parse(text)
    }
  }

  // --- Turning Lua lines into rows -----------------------------------------------------
  // What the shell's own `qs ipc call …` binds do
  readonly property var shellNames: ({
    "launcher toggle": "App launcher",
    "quicksettings toggle": "Quick settings",
    "notifications toggle": "Notifications",
    "notifications dnd": "Do not disturb",
    "lock lock": "Lock screen",
    "power toggle": "Power menu",
    "clipboard toggle": "Clipboard history",
    "capture toggle": "Screenshot & recording toolbar",
    "capture shot region": "Screenshot of an area",
    "capture shot screen": "Screenshot of the screen",
    "capture stop": "Stop recording",
    "pickers theme": "Theme picker",
    "pickers wallpaper": "Wallpaper picker",
    "settings toggle": "Settings",
    "osd caps": "Caps Lock pop-up",
    "osd brightness": "Brightness pop-up"
  })

  function prettyKeys(combo: string): string {
    const names = {
      SUPER: "Super", SHIFT: "Shift", CTRL: "Ctrl", CONTROL: "Ctrl", ALT: "Alt",
      space: "Space", Escape: "Esc", comma: ",", period: ".", Print: "Print", Return: "Enter",
      "mouse:272": "Left mouse", "mouse:273": "Right mouse", mouse_down: "Scroll down", mouse_up: "Scroll up",
      XF86AudioRaiseVolume: "Volume up key", XF86AudioLowerVolume: "Volume down key", XF86AudioMute: "Mute key",
      XF86AudioMicMute: "Mic mute key", XF86MonBrightnessUp: "Brightness up key", XF86MonBrightnessDown: "Brightness down key",
      XF86AudioNext: "Next track key", XF86AudioPrev: "Previous track key", XF86AudioPlay: "Play key", XF86AudioPause: "Pause key",
      Caps_Lock: "Caps Lock", left: "←", right: "→", up: "↑", down: "↓"
    };
    return combo.split("+").map(p => p.trim()).filter(p => p !== "").map(p => names[p] ?? (p.length === 1 ? p.toUpperCase() : p)).join(" + ");
  }

  // A Lua key expression: "SUPER + A", mainMod .. " + Q", mainMod .. " + " .. key
  function evalKey(expr: string, vars: var, inLoop: bool): string {
    let out = "";
    for (const part of expr.split("..").map(p => p.trim())) {
      const lit = part.match(/^"([^"]*)"$|^'([^']*)'$/);
      if (lit) out += lit[1] ?? lit[2];
      else if (vars[part] !== undefined) out += vars[part];
      else if (inLoop) out += "1…0";
      else out += part;
    }
    return out;
  }

  function describe(action: string): var {
    const exec = action.match(/^hl\.dsp\.exec_cmd\((.*)\)$/);
    if (exec) {
      const arg = exec[1].trim();
      const str = arg.match(/^"(.*)"$/);
      const cmd = str ? str[1] : arg;
      const ipc = cmd.match(/qs ipc call (.+)$/);
      if (ipc) return { group: "Shell", text: shellNames[ipc[1].trim()] ?? ipc[1].trim() };
      const app = arg.match(/^apps\.(\w+)/);
      if (app) return { group: "Apps", text: "Open " + app[1].replace(/([A-Z])/g, " $1").toLowerCase() + (arg.includes("drun") ? " (app menu)" : "") };
      if (/wpctl|playerctl|brightnessctl/.test(cmd)) return { group: "Media", text: cmd.replace(/@DEFAULT_AUDIO_(SINK|SOURCE)@/, "").replace(/\s+/g, " ") };
      return { group: "Apps", text: cmd.length > 60 ? cmd.slice(0, 57) + "…" : cmd };
    }
    const d = action.replace(/^hl\.dsp\./, "");
    const known = [
      [/^window\.close/, "Close window"], [/^window\.float/, "Float or tile window"], [/^window\.pseudo/, "Pseudo-tile window"],
      [/^window\.drag/, "Move window with the mouse"], [/^window\.resize/, "Resize window with the mouse"],
      [/^window\.move\(\{ ?workspace = "special/, "Move window to the scratchpad"],
      [/^window\.move\(\{ ?workspace/, "Move window to workspace"],
      [/^focus\(\{ ?direction = "(\w+)"/, "Focus window $1"],
      [/^focus\(\{ ?workspace = "e\+1"/, "Next workspace"], [/^focus\(\{ ?workspace = "e-1"/, "Previous workspace"],
      [/^focus\(\{ ?workspace/, "Go to workspace"],
      [/^workspace\.toggle_special/, "Show the scratchpad"], [/^layout\("togglesplit"\)/, "Swap split direction"], [/^exit/, "Leave Hyprland"]
    ];
    for (const [re, text] of known) {
      const m = d.match(re);
      if (m) return { group: "Windows", text: text.replace("$1", m[1] ?? "") };
    }
    return { group: "Windows", text: d };
  }

  function parse(text: string): var {
    const rows = [];
    const vars = {};
    let file = "";
    let loopDepth = 0;
    for (const raw of text.split("\n")) {
      if (raw.startsWith("@@FILE ")) {
        file = raw.slice(7);
        loopDepth = 0;
        continue;
      }
      const line = raw.replace(/--.*$/, "").trim();
      if (line === "") continue;
      const local = line.match(/^local (\w+)\s*=\s*"([^"]*)"/);
      if (local) vars[local[1]] = local[2];
      if (/^for .* do$/.test(line)) loopDepth++;
      if (line === "end" && loopDepth > 0) loopDepth--;

      const unbind = line.match(/hl\.unbind\((.+)\)/);
      if (unbind) {
        const keys = prettyKeys(evalKey(unbind[1], vars, loopDepth > 0));
        for (const r of rows) if (r.keys === keys) r.replaced = true;
        continue;
      }
      // hl.bind(<keys>, hl.dsp.<action>(…)[, { options }])
      const m = line.match(/hl\.bind\((.+?),\s*(hl\.dsp\.[\w.]+\(.*?\))\s*(?:,\s*(\{.*\}))?\s*\)\s*$/);
      if (!m) continue;
      const keys = prettyKeys(evalKey(m[1], vars, loopDepth > 0));
      const what = describe(m[2]);
      // non_consuming binds run next to the other one on purpose (brightness pop-up)
      const alongside = /non_consuming\s*=\s*true/.test(m[3] ?? "");
      rows.push({ keys, action: what.text, group: what.group, file: file.replace(Quickshell.env("HOME"), "~"), replaced: false, conflict: false, alongside });
    }
    // Bound twice (and still active)
    const count = {};
    for (const r of rows) if (!r.replaced && !r.alongside) count[r.keys] = (count[r.keys] ?? 0) + 1;
    for (const r of rows) r.conflict = !r.replaced && !r.alongside && count[r.keys] > 1;
    const order = ["Shell", "Apps", "Windows", "Media"];
    return rows.sort((a, b) => order.indexOf(a.group) - order.indexOf(b.group) || a.action.localeCompare(b.action));
  }

  // --- The list ---------------------------------------------------------------------------
  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 38
      radius: Theme.pill(height)
      color: Theme.item

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10
        Icon { name: "search"; size: 14; color: Theme.subtext }
        TextInput {
          id: search
          Layout.fillWidth: true
          color: Theme.text
          font.family: Theme.font.family
          font.pixelSize: Theme.font.body
          clip: true
          onTextChanged: page.query = text
          Accessible.role: Accessible.EditableText
          Accessible.name: "Search keybinds"
          Label { visible: search.text === ""; text: "Search " + page.binds.length + " keybinds by action or keys…"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }

    Button {
      text: "Your keybinds"
      variant: "ghost"
      size: Theme.size.buttonList
      onClicked: DefaultApps.inTerminal("${EDITOR:-nvim} \"$1\"", [page.hyprDir + "/modules/keybinds.lua"])
    }
    Button {
      text: "Shell keybinds"
      variant: "ghost"
      size: Theme.size.buttonList
      onClicked: DefaultApps.inTerminal("${EDITOR:-nvim} \"$1\"", [page.shellFile])
    }
  }

  Rectangle {
    visible: page.conflicts > 0
    Layout.fillWidth: true
    implicitHeight: conflictLabel.implicitHeight + 20
    radius: Theme.radiusCard
    color: Theme.alpha(Theme.error, 0.1)
    border.width: 1
    border.color: Theme.alpha(Theme.error, 0.4)

    Label {
      id: conflictLabel
      x: 14
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width - 28
      wrapMode: Text.Wrap
      color: Theme.error
      font.pixelSize: Theme.font.small
      text: page.conflicts + " keybinds share a key combination (marked below). Hyprland runs both; change one in its file."
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: list.implicitHeight
    radius: Theme.radiusCard
    color: Theme.item
    clip: true

    ColumnLayout {
      id: list
      width: parent.width
      spacing: 0

      Repeater {
        model: page.shown

        Item {
          id: bind
          required property var modelData
          required property int index
          readonly property bool newGroup: index === 0 || page.shown[index - 1].group !== modelData.group

          Layout.fillWidth: true
          implicitHeight: 34 + (newGroup ? 26 : 0)

          Accessible.role: Accessible.Row
          Accessible.name: modelData.action + ", " + modelData.keys + (modelData.conflict ? ", used twice" : "") + (modelData.replaced ? ", replaced by the shell" : "")

          Label {
            visible: bind.newGroup
            x: 14
            y: 10
            text: bind.modelData.group
            kind: "label"
          }

          Rectangle {
            visible: bind.index > 0 && !bind.newGroup
            width: parent.width
            height: 1
            color: Theme.hairline
          }

          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 34
            anchors.leftMargin: 14
            anchors.rightMargin: 12
            spacing: 10

            Label {
              Layout.fillWidth: true
              text: bind.modelData.action
              font.pixelSize: Theme.font.small
              color: bind.modelData.replaced ? Theme.subtext : Theme.text
              font.strikeout: bind.modelData.replaced
              elide: Text.ElideRight
            }
            Label {
              visible: bind.modelData.replaced || bind.modelData.conflict
              text: bind.modelData.replaced ? "replaced by the shell" : "used twice"
              color: bind.modelData.replaced ? Theme.subtext : Theme.error
              font.pixelSize: Theme.font.label
            }
            Label {
              text: bind.modelData.file.split("/").pop()
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
            Rectangle {
              implicitHeight: 24
              implicitWidth: keysLabel.implicitWidth + 16
              radius: Theme.r(12)
              color: Theme.surface
              border.width: bind.modelData.conflict ? 1 : 0
              border.color: Theme.error
              Label { id: keysLabel; anchors.centerIn: parent; text: bind.modelData.keys; font.pixelSize: Theme.font.label; font.weight: Font.Bold }
            }
          }
        }
      }
    }
  }
}
