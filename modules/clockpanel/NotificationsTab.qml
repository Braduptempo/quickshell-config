// NotificationsTab.qml
// Notification history, Do not disturb, clear all.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../../config"
import "../../components"
import "../../services"
import "../notifications"

ColumnLayout {
  id: root
  Layout.fillWidth: true
  spacing: 10

  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    Icon {
      name: "moon"
      size: 16
      color: Notifications.dnd ? Theme.accent : Theme.subtext
    }
    Label {
      text: "Do not disturb"
      Layout.fillWidth: true
    }
    Toggle {
      checked: Notifications.dnd
      accessibleName: "Do not disturb"
      onToggled: value => Notifications.dnd = value
    }
    Button {
      visible: Notifications.count > 0
      text: "Clear all"
      size: Theme.size.buttonSmall
      variant: "ghost"
      onClicked: Notifications.clearAll()
    }
  }

  Label {
    visible: Notifications.dnd
    text: "Only critical notifications pop up. Everything else waits here."
    kind: "muted"
    Layout.fillWidth: true
  }

  // Empty state
  ColumnLayout {
    visible: Notifications.count === 0
    Layout.fillWidth: true
    Layout.topMargin: 24
    Layout.bottomMargin: 24
    spacing: 8

    Icon {
      name: "bell"
      size: 28
      color: Theme.subtext
      Layout.alignment: Qt.AlignHCenter
    }
    Label {
      text: "You're all caught up"
      kind: "title"
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
    }
    Label {
      text: "New notifications show up here."
      kind: "muted"
      horizontalAlignment: Text.AlignHCenter
      Layout.fillWidth: true
    }
  }

  Flickable {
    visible: Notifications.count > 0
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(list.implicitHeight, 520)
    contentHeight: list.implicitHeight
    clip: true

    Column {
      id: list
      width: parent.width
      spacing: 8

      Repeater {
        model: Notifications.history

        NotificationCard {
          required property Notification modelData
          notification: modelData
          width: list.width
          glass: false
          maxLines: 6
          onActivated: {
            if (Notifications.activate(modelData)) Panels.closeClockPanel();
          }
        }
      }
    }
  }
}
