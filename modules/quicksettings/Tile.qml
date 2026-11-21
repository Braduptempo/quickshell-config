// Tile.qml
// Quick settings toggle: icon circle, label and status, and an optional
// arrow that opens the detail page.
import QtQuick
import "../../config"
import "../../components"

Item {
  id: root

  property string icon
  property string label
  property string status
  property bool checked: false
  // On, but not the one in use (e.g. Wi-Fi while the cable carries traffic)
  property bool standby: false
  property color statusColor: Theme.subtext
  property bool hasDetails: false

  signal toggled()
  signal detailsRequested()

  implicitHeight: Theme.size.toggle
  implicitWidth: 180

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: root.checked && !root.standby ? Theme.alpha(Theme.accent, 0.14)
         : mainMouse.containsMouse ? Theme.hover(Theme.item) : Theme.item
    border.width: 1
    border.color: root.standby ? Theme.alpha(Theme.accent, 0.35)
                : root.checked ? Theme.alpha(Theme.accent, 0.5) : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }
    Behavior on border.color { ColorAnimation { duration: Theme.anim.toggle } }
  }

  Item {
    id: main
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: root.hasDetails ? detailsButton.left : parent.right

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked

    Rectangle {
      id: circle
      width: 36
      height: 36
      radius: 18
      anchors.left: parent.left
      anchors.leftMargin: 8
      anchors.verticalCenter: parent.verticalCenter
      color: root.standby ? Theme.alpha(Theme.accent, 0.25)
           : root.checked ? Theme.accent : Theme.alpha(Theme.text, 0.08)

      Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }

      Icon {
        anchors.centerIn: parent
        name: root.icon
        size: 16
        strokeWidth: 2.2
        color: root.standby ? Theme.accent : root.checked ? Theme.onAccent : Theme.text
      }
    }

    Column {
      anchors.left: circle.right
      anchors.leftMargin: 10
      anchors.right: parent.right
      anchors.rightMargin: 4
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Label {
        text: root.label
        font.weight: Font.Bold
        width: parent.width
      }
      Label {
        text: root.status
        kind: "muted"
        color: root.statusColor
        font.pixelSize: Theme.font.label
        width: parent.width
      }
    }

    MouseArea {
      id: mainMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggled()
    }
  }

  IconButton {
    id: detailsButton
    visible: root.hasDetails
    icon: "chevron-right"
    size: 28
    variant: "plain"
    accessibleName: root.label + " details"
    anchors.right: parent.right
    anchors.rightMargin: 7
    anchors.verticalCenter: parent.verticalCenter
    onClicked: root.detailsRequested()
  }
}
