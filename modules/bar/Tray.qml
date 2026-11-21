// Tray.qml
// System tray behind an arrow. Click the arrow to show the app icons.
// Icon: left click opens the app's menu (or the app itself, Settings → Bar &
// panels → Tray click), right click always the menu, middle click opens the
// app. Many apps (Spotify, Electron apps) ignore "open" and only have a menu,
// which is why the menu is the default.
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
  // Settings → Bar & panels: icons hidden behind the arrow, or always shown
  readonly property bool collapsible: Config.bar.collapseTray
  property bool expanded: false
  readonly property bool showIcons: expanded || !collapsible
  readonly property bool fromBottom: Config.bar.position === "bottom"

  spacing: 6
  visible: SystemTray.items.values.length > 0

  // A plain pill, not a BarItem: a BarItem's own MouseArea lies over its
  // content and would catch the clicks meant for the icons
  Rectangle {
    id: icons
    visible: root.showIcons
    implicitHeight: Theme.size.barItem
    implicitWidth: iconRow.implicitWidth + 12
    anchors.verticalCenter: parent.verticalCenter
    radius: Theme.pill(height)
    color: Theme.item

    Row {
      id: iconRow
      anchors.centerIn: parent
      spacing: 8

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

          // The app's own menu, opened under the icon
          QsMenuAnchor {
            id: menuAnchor
            menu: trayItem.modelData.menu
            anchor.item: trayItem
            anchor.edges: root.fromBottom ? Edges.Top : Edges.Bottom
            anchor.gravity: root.fromBottom ? Edges.Top : Edges.Bottom
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              const item = trayItem.modelData;
              const wantsMenu = mouse.button === Qt.RightButton || item.onlyMenu
                                || (mouse.button === Qt.LeftButton && Config.bar.trayClick === "menu");
              if (wantsMenu && item.hasMenu) menuAnchor.open();
              else if (mouse.button === Qt.MiddleButton && Config.bar.trayClick !== "menu") item.secondaryActivate();
              else item.activate();
            }
            onWheel: wheel => trayItem.modelData.scroll(wheel.angleDelta.y, false)
          }
        }
      }
    }
  }

  BarItem {
    visible: root.collapsible
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
