// GlassPanel.qml
// The translucent panel used for quick settings, menus and dialogs.
// Hyprland blurs what is behind it (layerrule blur), this draws the glass.
import QtQuick
import "../config"

Rectangle {
  radius: Theme.radiusPanel
  color: Theme.panel
  border.width: 1
  border.color: Theme.border

  // Thin highlight along the top edge, like light on glass
  Rectangle {
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - parent.radius * 2
    height: 1
    color: Theme.highlight
  }
}
