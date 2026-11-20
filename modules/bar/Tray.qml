// Tray.qml
// System tray behind an arrow. Click the arrow to show the app icons.
// Icon: left click opens the app, right click its menu, middle click its
// secondary action.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config"
import "../../components"

Row {
  id: root

  required property QsWindow window
  property bool expanded: false

  spacing: 6
  visible: SystemTray.items.values.length > 0

  BarItem {
    id: icons
    visible: root.expanded
    padding: 6

    Repeater {
      model: SystemTray.items

      Item {
        id: trayItem
        required property SystemTrayItem modelData

        width: 22
        height: 22
        anchors.verticalCenter: parent.verticalCenter

        Accessible.role: Accessible.Button
        Accessible.name: modelData.tooltipTitle !== "" ? modelData.tooltipTitle : modelData.title

        IconImage {
          anchors.centerIn: parent
          implicitSize: 18
          source: trayItem.modelData.icon
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
          cursorShape: Qt.PointingHandCursor
          onClicked: mouse => {
            const item = trayItem.modelData;
            if (mouse.button === Qt.RightButton || item.onlyMenu) {
              if (item.hasMenu) {
                const pos = trayItem.mapToItem(null, 0, trayItem.height + 14);
                item.display(root.window, pos.x, pos.y);
              }
            } else if (mouse.button === Qt.MiddleButton) {
              item.secondaryActivate();
            } else {
              item.activate();
            }
          }
          onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
        }
      }
    }
  }

  BarItem {
    flat: true
    padding: 0
    accessibleName: root.expanded ? "Collapse system tray" : "Expand system tray"
    onClicked: root.expanded = !root.expanded

    Icon {
      name: root.expanded ? "chevron-right" : "chevron-left"
      size: 14
      strokeWidth: 2.4
      color: Theme.subtext
      anchors.verticalCenter: parent.verticalCenter
    }
  }
}
