// Bar.qml
// The floating pill bar from the design, on every monitor.
// Left: workspaces and media. Centre: clock. Right: tray and status.
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

          MediaPill {}
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

          Tray {
            window: panel
            anchors.verticalCenter: parent.verticalCenter
          }

          StatusPill {
            screen: panel.modelData
          }
        }
      }
    }
  }
}
