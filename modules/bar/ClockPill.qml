// ClockPill.qml
// Centre of the bar. Red dot = unread notifications, moon = Do not disturb.
// Click: calendar (or the notifications, when there are unread ones).
// Right click: Do not disturb. Middle click: clear all notifications.
import QtQuick
import Quickshell
import "../../config"
import "../../components"
import "../../services"

BarItem {
  id: root

  required property ShellScreen screen

  padding: 14
  active: Panels.clockPanelOpen && Panels.clockScreen === screen
  accessibleName: "Clock " + Time.time
                  + (Notifications.unread > 0 ? ", " + Notifications.unread + " unread notifications" : "")
                  + (Notifications.dnd ? ", do not disturb" : "")

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) {
      Notifications.dnd = !Notifications.dnd;
    } else if (mouse.button === Qt.MiddleButton) {
      Notifications.clearAll();
    } else {
      Panels.toggleClockPanel(root.screen, Notifications.unread > 0 ? "notifications" : "calendar");
    }
  }

  Label {
    text: Time.time
    kind: "title"
    font.pixelSize: Theme.font.body + 1
    anchors.verticalCenter: parent.verticalCenter
  }

  Icon {
    visible: Notifications.dnd
    name: "moon"
    size: 13
    color: Theme.subtext
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    visible: Notifications.unread > 0 && !Notifications.dnd
    width: 7
    height: 7
    radius: 4
    color: Theme.error
    anchors.verticalCenter: parent.verticalCenter
  }
}
