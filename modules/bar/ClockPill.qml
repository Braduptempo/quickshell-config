// ClockPill.qml
// Centre of the bar. Red dot = unread notifications.
// Click opens the notification history (the calendar panel comes later).
import QtQuick
import Quickshell
import "../../config"
import "../../components"
import "../../widgets/clock"
import "../../widgets/notifications"

BarItem {
  id: root

  padding: 14
  active: history.visible
  accessibleName: "Clock " + Time.time + (Notifications.unread > 0 ? ", " + Notifications.unread + " unread notifications" : "")

  onClicked: {
    history.visible = !history.visible;
    if (history.visible) Notifications.markRead();
  }

  Label {
    text: Time.time
    kind: "title"
    font.pixelSize: Theme.font.body + 1
    anchors.verticalCenter: parent.verticalCenter
  }

  Rectangle {
    visible: Notifications.unread > 0
    width: 7
    height: 7
    radius: 4
    color: Theme.error
    anchors.verticalCenter: parent.verticalCenter
  }

  NotificationDropdown {
    id: history
    visible: false
    listModel: Notifications.model
    anchor.item: root
    anchor.rect.width: root.width
    anchor.rect.height: root.height
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.margins.top: 10
  }
}
