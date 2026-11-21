// ClockPill.qml
// Centre of the bar. Red dot = unread notifications, moon = Do not disturb
// (also while the daily quiet hours are on).
// Click: the overview (or the notifications, when there are unread ones).
// The weather shows next to the time when chosen in Settings → Weather.
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
                  + (Config.weather.showInBar && Weather.current ? ", " + Weather.degrees(Weather.current.temperature) + " " + Weather.describe(Weather.current.code) : "")
                  + (Notifications.unread > 0 ? ", " + Notifications.unread + " unread notifications" : "")
                  + (Notifications.quiet ? ", do not disturb" : "")
                  + (Power.scheduled ? ", " + (Power.action(Power.scheduledId)?.label ?? "") + " at " + Power.scheduledTime : "")

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) {
      Notifications.dnd = !Notifications.dnd;
    } else if (mouse.button === Qt.MiddleButton) {
      Notifications.clearAll();
    } else {
      Panels.toggleClockPanel(root.screen, Notifications.unread > 0 ? "notifications" : "overview");
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

  // The weather, from Settings → Weather
  Row {
    visible: Config.weather.showInBar && Weather.current !== null
    spacing: 5
    anchors.verticalCenter: parent.verticalCenter
    Icon {
      name: Weather.current ? Weather.icon(Weather.current.code, Weather.current.isDay) : "cloud"
      size: 14
      color: Theme.subtext
      anchors.verticalCenter: parent.verticalCenter
    }
    Label {
      text: Weather.current ? Weather.degrees(Weather.current.temperature) : ""
      color: Theme.subtext
      anchors.verticalCenter: parent.verticalCenter
    }
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
    radius: Theme.r(4)
    color: Theme.error
    anchors.verticalCenter: parent.verticalCenter
  }
}
