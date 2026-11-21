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

  EmptyState {
    visible: Notifications.count === 0
    Layout.fillWidth: true
    Layout.bottomMargin: 16
    icon: "bell-check"
    iconColor: Theme.good
    title: "You're all caught up"
    text: Notifications.quiet ? "Do not disturb is on: new notifications wait here quietly." : "No new notifications. New ones show up here."
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
