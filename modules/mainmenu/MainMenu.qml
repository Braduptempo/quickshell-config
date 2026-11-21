// MainMenu.qml
// The menu behind the button at the far left of the bar (Super + X):
// search, tools, settings and power. Everything that isn't a live status.
//   Left click on the button: this menu. Right click: the launcher.
//   Esc closes it; every item closes it before it does its thing.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Panels.mainMenuOpen
  readonly property bool fromBottom: Config.bar.position === "bottom"
  readonly property string style: Config.animations.panelStyle

  screen: Panels.mainMenuScreen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-mainmenu"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: !window.fromBottom
    bottom: window.fromBottom
    left: true
  }
  margins {
    top: 6
    bottom: 6
    left: 4
  }
  implicitWidth: 360 + 24
  implicitHeight: card.implicitHeight + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.mainMenuOpen = false
  }

  // Close first, then act (pickers and toolbars need the screen free)
  function run(action: var): void {
    const s = window.screen;
    Panels.mainMenuOpen = false;
    action(s);
  }

  readonly property var tools: [
    { label: "Screenshot", icon: "camera", tint: Theme.accent,
      act: s => { Capture.mode = "shot"; Capture.toggle(s); } },
    { label: "Record", icon: "record", tint: Theme.error,
      act: s => { Capture.mode = "record"; Capture.toggle(s); } },
    { label: "Clipboard", icon: "clipboard", tint: Theme.warn,
      act: s => Clipboard.toggle(s) },
    { label: "Color picker", icon: "pipette", tint: Theme.palette.dots[5] ?? Theme.accent,
      act: s => LauncherTools.pickColor() },
    { label: "Emoji", icon: "smile", tint: Theme.palette.dots[1] ?? Theme.warn,
      act: s => Launcher.openWith(s, ":") },
    { label: "System", icon: "activity", tint: Theme.good,
      act: s => Panels.openQuickSettings(s, "system") }
  ]

  readonly property var links: [
    { label: "Settings", icon: "settings", keys: "Super + ,", act: s => Panels.openSettings(s, "") },
    { label: "Theme and wallpaper", icon: "palette", keys: "Super + T", act: s => Panels.toggleThemePicker(s) },
    { label: "Keybinds", icon: "keyboard", keys: "all shortcuts", act: s => Panels.openSettings(s, "keybinds") },
    { label: "Notification history", icon: "bell", keys: "Super + N", act: s => Panels.openClockPanel(s, "notifications") }
  ]

  // --- Who and how long ----------------------------------------------------------------
  property string userName: Quickshell.env("USER") ?? ""
  property string uptime: ""

  Process {
    // The full name from the account, if there is one
    running: true
    command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1"]
    stdout: StdioCollector {
      onStreamFinished: if (text.trim() !== "") window.userName = text.trim()
    }
  }

  FileView {
    id: uptimeFile
    path: "/proc/uptime"
    onLoaded: {
      const s = Math.floor(parseFloat(text().split(" ")[0]));
      const d = Math.floor(s / 86400);
      const h = Math.floor(s % 86400 / 3600);
      const m = Math.floor(s % 3600 / 60);
      window.uptime = "Up for " + (d > 0 ? d + " d " + h + " h" : h > 0 ? h + " h " + m + " min" : m + " min");
    }
  }

  onShownChanged: if (shown) uptimeFile.reload()

  GlassPanel {
    id: card
    color: Theme.panelSolid

    x: 12
    width: 360
    implicitHeight: column.implicitHeight + 28
    height: implicitHeight
    focus: true
    transformOrigin: window.fromBottom ? Item.BottomLeft : Item.TopLeft

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.92

    Accessible.role: Accessible.Dialog
    Accessible.name: "Main menu"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    Keys.onEscapePressed: Panels.mainMenuOpen = false

    ColumnLayout {
      id: column
      x: 14
      y: 14
      width: parent.width - 28
      spacing: 14

      // --- Search: opens the launcher ---------------------------------------------------
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 40
        radius: Theme.pill(height)
        color: searchMouse.containsMouse ? Theme.hover(Theme.item) : Theme.alpha(Theme.crust, 0.5)
        border.width: 1
        border.color: Theme.border

        Accessible.role: Accessible.Button
        Accessible.name: "Search apps and commands"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 8
          spacing: 10
          Icon { name: "search"; size: 15; color: Theme.subtext }
          Label { Layout.fillWidth: true; text: "Search apps and commands…"; kind: "muted"; font.pixelSize: Theme.font.small }
          Kbd { text: "Super + Space" }
        }
        MouseArea {
          id: searchMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: window.run(s => Launcher.toggle(s))
        }
      }

      // --- Tools ----------------------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 8

        Label { text: "Tools"; kind: "label" }

        GridLayout {
          Layout.fillWidth: true
          columns: 3
          columnSpacing: 8
          rowSpacing: 8

          Repeater {
            model: window.tools

            Rectangle {
              id: tool
              required property var modelData
              readonly property bool available: modelData.label !== "Color picker" || LauncherTools.hasPicker

              Layout.fillWidth: true
              implicitHeight: 78
              radius: 14
              color: toolMouse.containsMouse && available ? Theme.hover(Theme.item) : Theme.item
              opacity: available ? 1 : 0.45

              Accessible.role: Accessible.Button
              Accessible.name: modelData.label

              Column {
                anchors.centerIn: parent
                spacing: 7
                Rectangle {
                  anchors.horizontalCenter: parent.horizontalCenter
                  width: 32
                  height: 32
                  radius: 16
                  color: tool.modelData.tint
                  Icon { anchors.centerIn: parent; name: tool.modelData.icon; size: 15; color: Theme.crust }
                }
                Label {
                  anchors.horizontalCenter: parent.horizontalCenter
                  text: tool.modelData.label
                  font.pixelSize: Theme.font.label
                }
              }

              MouseArea {
                id: toolMouse
                anchors.fill: parent
                hoverEnabled: true
                enabled: tool.available
                cursorShape: Qt.PointingHandCursor
                onClicked: window.run(tool.modelData.act)
              }
            }
          }
        }
      }

      // --- Settings and history ---------------------------------------------------------
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Repeater {
          model: window.links

          Rectangle {
            id: link
            required property var modelData

            Layout.fillWidth: true
            implicitHeight: 40
            radius: Theme.pill(height)
            color: linkMouse.containsMouse ? Theme.item : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: modelData.label

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 10
              anchors.rightMargin: 8
              spacing: 12
              Icon { name: link.modelData.icon; size: 16; color: Theme.subtext }
              Label { Layout.fillWidth: true; text: link.modelData.label; font.pixelSize: Theme.font.small }
              Kbd { text: link.modelData.keys }
            }
            MouseArea {
              id: linkMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: window.run(link.modelData.act)
            }
          }
        }
      }

      // --- You, and power -----------------------------------------------------------------
      Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairline }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          implicitWidth: 32
          implicitHeight: 32
          radius: 16
          color: Theme.surface
          Icon { anchors.centerIn: parent; name: "user"; size: 16; color: Theme.subtext }
        }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Label { text: window.userName; font.weight: Font.Bold; font.pixelSize: Theme.font.small; elide: Text.ElideRight; Layout.fillWidth: true }
          Label { visible: text !== ""; text: window.uptime; kind: "muted"; font.pixelSize: Theme.font.label }
        }
        IconButton { icon: "lock"; size: 34; accessibleName: "Lock"; onClicked: window.run(s => Lock.lock()) }
        IconButton { icon: "logout"; size: 34; accessibleName: "Log out"; onClicked: window.run(s => Power.openWith(s, "E")) }
        IconButton { icon: "power"; size: 34; variant: "dangerSoft"; accessibleName: "Power menu"; onClicked: window.run(s => Power.toggle(s)) }
      }
    }
  }
}
