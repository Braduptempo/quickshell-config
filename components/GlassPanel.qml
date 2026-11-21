// GlassPanel.qml
// The translucent panel used for the bar, quick settings, menus and dialogs.
// Hyprland blurs what is behind it (layerrule blur), this draws the glass:
// the fill, a border, a highlight along the top and a soft shadow (the last
// three can be turned off in Settings → Theme).
import QtQuick
import QtQuick.Effects
import "../config"

Rectangle {
  id: root

  // Off for the bar: it sits against the screen edge
  property bool shadow: true

  radius: Theme.radiusPanel
  color: Theme.panel
  border.width: Theme.borders ? 1 : 0
  border.color: Theme.border

  RectangularShadow {
    visible: Theme.shadows && root.shadow && root.color.a > 0
    z: -1
    anchors.fill: parent
    radius: root.radius
    offset.y: 6
    blur: 24
    spread: -4
    color: Qt.rgba(0, 0, 0, Theme.light ? 0.16 : 0.32)
  }

  // Thin highlight along the top edge, like light on glass
  Rectangle {
    visible: Theme.borders
    anchors.top: parent.top
    anchors.topMargin: 1
    anchors.horizontalCenter: parent.horizontalCenter
    width: parent.width - parent.radius * 2
    height: 1
    color: Theme.highlight
  }
}
