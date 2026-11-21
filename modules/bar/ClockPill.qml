// ClockPill.qml
// Centre of the bar. Red dot = unread notifications, moon = Do not disturb
// (also while the daily quiet hours are on).
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
                  + (Notifications.quiet ? ", do not disturb" : "")
                  + (Power.scheduled ? ", " + (Power.action(Power.scheduledId)?.label ?? "") + " at " + Power.scheduledTime : "")

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) {
      Notifications.dnd = !Notifications.dnd;
    } else if (mouse.button === Qt.MiddleButton) {
      Notifications.clearAll();
    } else {
      Panels.toggleClockPanel(root.screen, Notifications.unread > 0 ? "notifications" : "calendar");
    }
  }

  // "Fri 20 Nov", when chosen in Settings → Bar & panels
  Label {
    visible: Config.bar.showDate
    text: Qt.formatDateTime(Time.date, "ddd d MMM")
    color: Theme.subtext
    font.pixelSize: Theme.font.body
    anchors.verticalCenter: parent.verticalCenter
  }

  Label {
    text: Time.time
    kind: "title"
    font.pixelSize: Theme.font.body + 1
    anchors.verticalCenter: parent.verticalCenter
  }

  // Restart or shut down scheduled from the power menu
  Row {
    visible: Power.scheduled
    spacing: 4
    anchors.verticalCenter: parent.verticalCenter
    Icon { name: "clock"; size: 13; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
    Label { text: Power.scheduledTime; color: Theme.warn; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
  }

  // Do not disturb, by hand or by the schedule
  Icon {
    visible: Notifications.quiet
    name: "moon"
    size: 13
    color: Theme.subtext
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    visible: Notifications.unread > 0 && !Notifications.quiet
    width: 7
    height: 7
    radius: 4
    color: Theme.error
    anchors.verticalCenter: parent.verticalCenter
  }
}
