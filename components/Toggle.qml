// Toggle.qml
// On/off switch, 40×22. Set `checked`, react to `toggled(checked)`.
import QtQuick
import "../config"

Item {
  id: root

  property bool checked: false
  property string accessibleName

  signal toggled(bool checked)

  implicitWidth: 40
  implicitHeight: 22
  activeFocusOnTab: true

  Accessible.role: Accessible.CheckBox
  Accessible.name: accessibleName
  Accessible.checked: checked
  Keys.onSpacePressed: flip()

  function flip(): void {
    checked = !checked;
    toggled(checked);
  }

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: root.checked ? Theme.accent : Theme.overlay
    border.width: root.activeFocus ? 1 : 0
    border.color: Theme.text

    Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }

    Rectangle {
      width: 18
      height: 18
      radius: 9
      y: 2
      x: root.checked ? parent.width - width - 2 : 2
      color: root.checked ? Theme.onAccent : Theme.text

      Behavior on x {
        NumberAnimation { duration: Theme.anim.toggle; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
      }
      Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.flip()
  }
}
