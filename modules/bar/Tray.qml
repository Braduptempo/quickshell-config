// Tray.qml
// System tray behind an arrow. Click the arrow to show the app icons.
// Icon: left click opens the app's menu (or the app itself, Settings → Bar &
// panels → Tray click), right click always the menu, middle click opens the
// app. Many apps (Spotify, Electron apps) ignore "open" and only have a menu,
// which is why the menu is the default. The menu is drawn by the shell
// (TrayMenu.qml), in its own style.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../../config"
import "../../components"
import "../../services"

SmoothRow {
  id: root
  // The icons pop in when the arrow opens them; no sliding (right half)
  slide: false

  required property QsWindow window
  // Settings → Bar & panels: icons hidden behind the arrow, or always shown
  readonly property bool collapsible: Config.bar.collapseTray
  property bool expanded: false
  readonly property bool showIcons: expanded || !collapsible

  spacing: 6
  visible: SystemTray.items.values.length > 0

  // A plain pill, not a BarItem: a BarItem's own MouseArea lies over its
  // content and would catch the clicks meant for the icons
  Rectangle {
    id: icons
    visible: root.showIcons
    implicitHeight: Theme.size.barItem
    implicitWidth: iconRow.implicitWidth + 12
    Behavior on implicitWidth { NumberAnimation { duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard } }
    anchors.verticalCenter: parent.verticalCenter
    radius: Theme.pill(height)
    color: Theme.barItem
    border.width: Theme.barPills && Theme.borders ? 1 : 0
    border.color: Theme.border

    SmoothRow {
      id: iconRow
      slide: false
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

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              const item = trayItem.modelData;
              const wantsMenu = mouse.button === Qt.RightButton || item.onlyMenu
                                || (mouse.button === Qt.LeftButton && Config.bar.trayClick === "menu");
              if (wantsMenu && item.hasMenu) Panels.toggleTrayMenu(item, root.window.screen, trayItem.mapToItem(null, trayItem.width / 2, 0).x);
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
