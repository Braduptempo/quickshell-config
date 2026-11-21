// Bar.qml
// The bar, on every monitor (see Config.bar and Settings → Bar & panels).
// Left: workspaces, window title, media. Centre: clock. Right: tray,
// clipboard and status. At the top or bottom, as a floating pill, attached
// to the edge, or only the pills with nothing behind them. Other monitors can get the full bar, a light one (workspaces
// and clock) or none.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

Scope {
  id: root

  readonly property bool bottom: Config.bar.position === "bottom"
  readonly property bool attached: Config.bar.style === "attached"
  // No bar behind the pills: they float on their own
  readonly property bool pills: Config.bar.style === "pills"

  // The main monitor (Settings → Displays), or the first one
  readonly property ShellScreen mainScreen: Quickshell.screens.find(s => s.name === Config.displays.primary) ?? Quickshell.screens[0] ?? null

  Variants {
    // The main monitor always has a bar; the others unless set to "none"
    model: Quickshell.screens.filter(s => s === root.mainScreen || Config.bar.otherMonitors !== "none")

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      readonly property bool light: modelData !== root.mainScreen && Config.bar.otherMonitors === "light"

      screen: modelData
      color: "transparent"
      // Hyprland blurs layers with this namespace (hyprland/quickshell.lua)
      WlrLayershell.namespace: "quickshell-bar"

      anchors {
        top: !root.bottom
        bottom: root.bottom
        left: true
        right: true
      }
      implicitHeight: Theme.size.bar + (root.attached ? 0 : 8)

      // Caffeine from quick settings: keep the screen awake
      IdleInhibitor {
        window: panel
        enabled: Session.caffeine
      }

      GlassPanel {
        id: bar
        anchors.fill: parent
        anchors.topMargin: root.attached || root.bottom ? 0 : 8
        anchors.bottomMargin: root.attached || !root.bottom ? 0 : 8
        anchors.leftMargin: root.attached ? 0 : 8
        anchors.rightMargin: root.attached ? 0 : 8
        radius: root.attached ? 0 : Theme.pill(height)
        color: root.pills ? "transparent" : Theme.panel
        border.width: root.pills || !Theme.borders ? 0 : 1
        shadow: false

        SmoothRow {
          anchors.left: parent.left
          anchors.leftMargin: 7
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          // Tools, settings and power (Super + X); right click: launcher
          MainMenuButton {
            screen: panel.modelData
          }

          Workspaces {
            screen: panel.modelData
          }

          // Before the window title, so a changing title doesn't move it
          MediaPill {
            screen: panel.modelData
            visible: Config.bar.showMedia && !panel.light && player !== null && player.trackTitle !== ""
          }

          // What the focused window is called. The light bar on other screens
          // always shows it, for that screen's own workspace
          BarItem {
            id: titleItem
            readonly property int workspace: Hyprland.monitorFor(panel.modelData)?.activeWorkspace?.id ?? -1
            readonly property string title: panel.light
              ? (Windows.windows.find(w => w.workspace === workspace)?.title ?? "")
              : (Hyprland.activeToplevel?.title ?? "")
            visible: (Config.bar.showWindowTitle || panel.light) && title !== ""
            flat: true
            accessibleName: "Window: " + title

            Label {
              text: titleItem.title
              kind: "muted"
              width: Math.min(implicitWidth, 300)
              elide: Text.ElideRight
              anchors.verticalCenter: parent.verticalCenter
            }
          }
        }

        ClockPill {
          screen: panel.modelData
          anchors.centerIn: parent
        }

        SmoothRow {
          visible: !panel.light
          // Anchored right: pop in, no sliding (see SmoothRow)
          slide: false
          anchors.right: parent.right
          anchors.rightMargin: 7
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          // Mic / camera / screen in use, updates, drives
          ExtrasPills {
            screen: panel.modelData
            anchors.verticalCenter: parent.verticalCenter
          }

          // While recording
          RecordingPill {
            anchors.verticalCenter: parent.verticalCenter
          }

          // While the replay buffer runs
          ReplayPill {
            anchors.verticalCenter: parent.verticalCenter
          }

          Tray {
            window: panel
            anchors.verticalCenter: parent.verticalCenter
          }

          // Clipboard history
          BarItem {
            id: clipButton
            visible: Clipboard.available && Config.bar.showClipboard
            padding: 0
            active: Clipboard.open
            accessibleName: "Clipboard"
            onClicked: Clipboard.toggle(panel.modelData)

            Icon {
              name: "clipboard"
              size: 15
              color: clipButton.active ? Theme.accent : Theme.text
            }
          }

          StatusPill {
            screen: panel.modelData
          }
        }
      }
    }
  }
}
