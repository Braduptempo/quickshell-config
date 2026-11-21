// Chip.qml
// Small pill for status ("Connected", "Error") or a filter you can toggle.
// tone: "neutral", "accent", "good", "warn", "error". checkable: acts as a filter.
import QtQuick
import "../config"

Item {
  id: root

  property string text
  property string tone: "neutral"
  property bool checkable: false
  property bool checked: false

  signal toggled(bool checked)

  readonly property color toneColor: {
    switch (tone) {
    case "accent": return Theme.accent;
    case "good": return Theme.good;
    case "warn": return Theme.warn;
    case "error": return Theme.error;
    default: return Theme.text;
    }
  }

  implicitHeight: checkable ? 28 : 24
  implicitWidth: label.implicitWidth + 20

  Accessible.role: checkable ? Accessible.CheckBox : Accessible.StaticText
  Accessible.name: text
  Accessible.checked: checked

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: root.checkable
           ? (root.checked ? Theme.alpha(Theme.accent, 0.16) : "transparent")
           : (root.tone === "neutral" ? Theme.item : Theme.alpha(root.toneColor, 0.16))
    border.width: root.checkable ? 1 : 0
    border.color: root.checked ? Theme.accent : Theme.border

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
  }

  Label {
    id: label
    anchors.centerIn: parent
    text: root.text
    kind: "label"
    font.capitalization: Font.MixedCase
    font.letterSpacing: 0
    color: root.checkable ? (root.checked ? Theme.text : Theme.subtext) : root.toneColor
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.checkable
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      root.checked = !root.checked;
      root.toggled(root.checked);
    }
  }
}
