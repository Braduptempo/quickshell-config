// Bar.qml
// The floating pill bar from the design, on every monitor.
// Left: workspaces and media. Centre: clock. Right: tray, clipboard and status.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../components"
import "../../services"

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: panel

      required property ShellScreen modelData

      screen: modelData
      color: "transparent"
      // Hyprland blurs layers with this namespace (hyprland/quickshell.lua)
      WlrLayershell.namespace: "quickshell-bar"

      anchors {
        top: true
        left: true
        right: true
      }
      implicitHeight: Theme.size.bar + 8

      // Caffeine from quick settings: keep the screen awake
      IdleInhibitor {
        window: panel
        enabled: Session.caffeine
      }

      GlassPanel {
        id: bar
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        radius: Theme.pill(height)

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 7
          anchors.verticalCenter: parent.verticalCenter
          spacing: 6

          Workspaces {
            screen: panel.modelData
          }

          MediaPill {
            screen: panel.modelData
          }
        }

        ClockPill {
          screen: panel.modelData
          anchors.centerIn: parent
        }

        Row {
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
            visible: Clipboard.available
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
