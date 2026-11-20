// Button.qml
// Pill button. variant: "primary", "secondary", "ghost", "outline",
// "danger" or "dangerSoft". size: 36 (dialogs), 32 (settings), 28 (lists), 26 (rows).
import QtQuick
import "../config"

Item {
  id: root

  property string text
  property string icon
  property string variant: "secondary"
  property int size: Theme.size.button

  signal clicked()

  readonly property int padding: size >= 36 ? 16 : size >= 32 ? 14 : size >= 28 ? 12 : 10
  readonly property bool hovered: mouse.containsMouse
  readonly property bool pressed: mouse.pressed

  readonly property color baseColor: {
    switch (variant) {
    case "primary": return Theme.accent;
    case "ghost": return Theme.item;
    case "outline": return "transparent";
    case "danger": return Theme.error;
    case "dangerSoft": return Theme.alpha(Theme.error, 0.18);
    default: return Theme.overlay;
    }
  }
  readonly property color contentColor: {
    if (!enabled) return Theme.alpha(Theme.subtext, 0.6);
    switch (variant) {
    case "primary": return Theme.onAccent;
    case "danger": return Theme.crust;
    case "dangerSoft": return Theme.error;
    default: return Theme.text;
    }
  }

  implicitHeight: size
  implicitWidth: content.implicitWidth + padding * 2
  activeFocusOnTab: true
  opacity: enabled ? 1 : 0.55

  Accessible.role: Accessible.Button
  Accessible.name: text
  Keys.onSpacePressed: if (enabled) clicked()
  Keys.onReturnPressed: if (enabled) clicked()

  Rectangle {
    id: bg
    anchors.fill: parent
    radius: Theme.pill(height)
    color: !root.enabled ? Theme.alpha(Theme.crust, 0.3)
         : root.hovered && root.variant === "outline" ? Theme.item
         : root.hovered ? Theme.hover(root.baseColor) : root.baseColor
    border.width: root.variant === "outline" || root.activeFocus ? 1 : 0
    border.color: root.activeFocus ? Theme.accent : Theme.border
    scale: root.pressed ? 0.96 : root.hovered ? 1.02 : 1

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
    Behavior on scale {
      NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
    }
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: 7
    scale: bg.scale

    Icon {
      visible: root.icon !== ""
      name: root.icon
      size: root.size >= 32 ? 14 : 12
      color: root.contentColor
      strokeWidth: 2.4
      anchors.verticalCenter: parent.verticalCenter
    }

    Label {
      visible: root.text !== ""
      text: root.text
      kind: root.size >= 36 ? "body" : root.size >= 32 ? "small" : "label"
      font.capitalization: Font.MixedCase
      font.letterSpacing: 0
      font.weight: root.variant === "primary" || root.variant === "danger" ? Font.Bold : Font.Normal
      color: root.contentColor
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: if (root.enabled) root.clicked()
  }
}
