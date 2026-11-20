// Dropdown.qml
// A button that shows the current choice; clicking it opens the list below it
// (inside the page, no popup window). model: list of labels.
// Like Segmented, it doesn't change currentIndex itself: update your state in
// onActivated.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../config"

Item {
  id: root

  property var model: []
  property int currentIndex: 0
  property string accessibleName
  property int listHeight: 220
  property bool open: false

  signal activated(int index)

  implicitWidth: 240
  implicitHeight: 32 + (open ? Math.min(listHeight, list.contentHeight + 8) + 4 : 0)

  Behavior on implicitHeight { NumberAnimation { duration: Theme.anim.fast } }

  Accessible.role: Accessible.ComboBox
  Accessible.name: accessibleName

  Rectangle {
    id: button
    width: parent.width
    height: 32
    radius: Theme.pill(height)
    color: mouse.containsMouse ? Theme.hover(Theme.item) : Theme.alpha(Theme.crust, 0.5)
    border.width: 1
    border.color: root.open ? Theme.accent : Theme.border

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 12
      anchors.rightMargin: 10
      Label {
        Layout.fillWidth: true
        text: root.model[root.currentIndex] ?? ""
        font.pixelSize: Theme.font.small
        elide: Text.ElideRight
      }
      Icon { name: root.open ? "chevron-up" : "chevron-down"; size: 12; color: Theme.subtext }
    }

    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: root.open = !root.open
    }
  }

  Rectangle {
    visible: root.open
    y: button.height + 4
    width: parent.width
    height: Math.min(root.listHeight, list.contentHeight + 8)
    radius: 14
    color: Theme.surface
    border.width: 1
    border.color: Theme.border
    clip: true

    ListView {
      id: list
      anchors.fill: parent
      anchors.margins: 4
      model: root.model
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      delegate: Rectangle {
        id: option
        required property string modelData
        required property int index
        width: list.width
        height: 28
        radius: 14
        color: index === root.currentIndex ? Theme.alpha(Theme.accent, 0.18) : optionMouse.containsMouse ? Theme.item : "transparent"

        Accessible.role: Accessible.ListItem
        Accessible.name: modelData
        Accessible.selected: index === root.currentIndex

        Label {
          x: 10
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 20
          text: option.modelData
          font.pixelSize: Theme.font.small
          font.weight: option.index === root.currentIndex ? Font.Bold : Font.Normal
          elide: Text.ElideRight
        }

        MouseArea {
          id: optionMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            root.open = false;
            root.activated(option.index);
          }
        }
      }
    }
  }
}
