// IconButton.qml
// Round button with only an icon. Always give it an `accessibleName`.
// variant: "ghost" (default), "primary", "dangerSoft", "plain" (no background).
import QtQuick
import "../config"

Item {
  id: root

  property string icon
  property string accessibleName
  property string variant: "ghost"
  property int size: Theme.size.buttonSmall
  property bool checked: false

  signal clicked()

  readonly property bool hovered: mouse.containsMouse
  readonly property color baseColor: {
    if (checked) return Theme.accent;
    switch (variant) {
    case "primary": return Theme.accent;
    case "dangerSoft": return Theme.alpha(Theme.error, 0.18);
    case "plain": return "transparent";
    default: return Theme.item;
    }
  }
  readonly property color iconColor: {
    if (checked || variant === "primary") return Theme.onAccent;
    if (variant === "dangerSoft") return Theme.error;
    if (variant === "plain") return Theme.subtext;
    return Theme.text;
  }

  implicitWidth: size
  implicitHeight: size
  activeFocusOnTab: true

  Accessible.role: Accessible.Button
  Accessible.name: accessibleName
  Keys.onSpacePressed: clicked()
  Keys.onReturnPressed: clicked()

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Theme.pill(height)
    color: root.hovered && root.variant === "plain" ? Theme.item
         : root.hovered ? Theme.hover(root.baseColor) : root.baseColor
    border.width: root.activeFocus ? 1 : 0
    border.color: Theme.accent
    scale: mouse.pressed ? 0.92 : 1

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }
  }

  Icon {
    anchors.centerIn: parent
    name: root.icon
    size: Math.round(root.size * 0.45)
    color: root.iconColor
    strokeWidth: 2.2
    scale: bg.scale
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
