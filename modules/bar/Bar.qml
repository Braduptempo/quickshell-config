// Bar.qml
// The bar, on every monitor (see Config.bar and Settings → Bar & panels).
// Left: workspaces, window title, media. Centre: clock. Right: tray,
// clipboard and status. At the top or bottom, as a floating pill or attached
// to the edge. Other monitors can get the full bar, a light one (workspaces
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

  Variants {
    // The first monitor always has a bar; the others unless set to "none"
    model: Quickshell.screens.filter((s, i) => i === 0 || Config.bar.otherMonitors !== "none")

    PanelWindow {
      id: panel

      required property ShellScreen modelData
      readonly property bool light: modelData !== Quickshell.screens[0] && Config.bar.otherMonitors === "light"

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

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 7
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Workspaces {
            screen: panel.modelData
          }

          // What the focused window is called
          BarItem {
            id: titleItem
            readonly property string title: Hyprland.activeToplevel?.title ?? ""
            visible: Config.bar.showWindowTitle && !panel.light && title !== ""
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

          MediaPill {
            screen: panel.modelData
            visible: Config.bar.showMedia && !panel.light && player !== null && player.trackTitle !== ""
          }
        }

        ClockPill {
          screen: panel.modelData
          anchors.centerIn: parent
        }

        Row {
          visible: !panel.light
          anchors.right: parent.right
          anchors.rightMargin: 7
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          // While recording
          RecordingPill {
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
