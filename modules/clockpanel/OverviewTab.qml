// OverviewTab.qml
// Today at a glance: events, the weather and the latest notifications, side
// by side. Each card opens its own tab.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../../config"
import "../../components"
import "../../services"

GridLayout {
  id: root

  readonly property var todayEvents: Calendar.eventsOn(Time.date).filter(e => e.allDay || e.end > Time.date.getTime())
  readonly property var later: Calendar.next

  columns: 3
  columnSpacing: 10
  rowSpacing: 10

  // A card with a header that opens its tab
  component Block: Rectangle {
    id: block
    property string icon
    property string title
    property string tab
    default property alias content: body.data

    // A third each, whatever the text inside: all start from 0 and share the
    // width equally, so long titles elide instead of pushing a card out
    Layout.fillWidth: true
    Layout.minimumWidth: 0
    Layout.preferredWidth: 0
    implicitWidth: 0
    Layout.fillHeight: true
    Layout.alignment: Qt.AlignTop
    implicitHeight: body.implicitHeight + head.height + 28
    radius: Theme.radiusCard
    color: Theme.item

    Rectangle {
      id: head
      x: 6
      y: 6
      width: parent.width - 12
      height: 32
      radius: Theme.pill(height)
      color: headMouse.containsMouse ? Theme.hover(Theme.item) : "transparent"

      Accessible.role: Accessible.Button
      Accessible.name: "Open " + block.title

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 8
        Icon { name: block.icon; size: 14; color: Theme.accent }
        Label { Layout.fillWidth: true; text: block.title; kind: "label" }
        Icon { name: "chevron-right"; size: 13; color: Theme.subtext }
      }
      MouseArea {
        id: headMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.clockTab = block.tab
      }
    }

    ColumnLayout {
      id: body
      x: 14
      anchors.top: head.bottom
      anchors.topMargin: 6
      width: parent.width - 28
      spacing: 8
    }
  }

  // --- Today --------------------------------------------------------------------------
  Block {
    icon: "calendar"
    title: "Today"
    tab: "calendar"

    Label { text: Qt.formatDate(Time.date, "dddd d MMMM"); font.weight: Font.Bold }

    Repeater {
      model: root.todayEvents.slice(0, 4)
      RowLayout {
        id: ev
        required property var modelData
        Layout.fillWidth: true
        spacing: 8
        Rectangle { implicitWidth: 3; implicitHeight: 28; radius: Theme.r(2); color: ev.modelData.color }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 0
          Label { text: ev.modelData.title; font.pixelSize: Theme.font.small; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
          Label {
            text: ev.modelData.allDay ? "All day" : Qt.formatDateTime(new Date(ev.modelData.start), "HH:mm") + " – " + Qt.formatDateTime(new Date(ev.modelData.end), "HH:mm")
            kind: "muted"
            font.pixelSize: Theme.font.label
          }
        }
      }
    }

    Label {
      visible: root.todayEvents.length === 0
      Layout.fillWidth: true
      text: root.later ? "Nothing more today. Next: " + root.later.title + ", " + Qt.formatDateTime(new Date(root.later.start), "ddd HH:mm") : "Nothing planned."
      kind: "muted"
      font.pixelSize: Theme.font.small
      wrapMode: Text.Wrap
    }
    Label {
      visible: root.todayEvents.length > 4
      text: "+" + (root.todayEvents.length - 4) + " more"
      kind: "muted"
      font.pixelSize: Theme.font.label
    }
  }

  // --- Weather ------------------------------------------------------------------------
  Block {
    icon: "cloud-sun"
    title: "Weather"
    tab: "weather"

    RowLayout {
      visible: Weather.current !== null
      Layout.fillWidth: true
      spacing: 10
      Icon { name: Weather.current ? Weather.icon(Weather.current.code, Weather.current.isDay) : "cloud"; size: 28; color: Theme.accent }
      ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        Label { text: Weather.current ? Weather.degrees(Weather.current.temperature) : ""; kind: "title" }
        Label { text: Weather.current ? Weather.describe(Weather.current.code) : ""; kind: "muted"; font.pixelSize: Theme.font.label; elide: Text.ElideRight; Layout.fillWidth: true }
      }
    }

    // The next hours
    RowLayout {
      visible: Weather.hours.length > 1
      Layout.fillWidth: true
      spacing: 4
      Repeater {
        model: Weather.hours.slice(1, 6)
        ColumnLayout {
          id: h
          required property var modelData
          Layout.fillWidth: true
          spacing: 2
          Label { Layout.alignment: Qt.AlignHCenter; text: Qt.formatTime(h.modelData.time, "HH"); kind: "muted"; font.pixelSize: Theme.font.label }
          Icon { Layout.alignment: Qt.AlignHCenter; name: Weather.icon(h.modelData.code, h.modelData.isDay); size: 13; color: Theme.text }
          Label { Layout.alignment: Qt.AlignHCenter; text: Weather.degrees(h.modelData.temperature); font.pixelSize: Theme.font.label }
        }
      }
    }

    Label {
      visible: Weather.rainNote !== ""
      text: Weather.rainNote
      color: Theme.accent
      font.pixelSize: Theme.font.label
      font.weight: Font.Bold
    }
    Label {
      visible: !Weather.configured
      Layout.fillWidth: true
      text: "Choose your city in Settings → Weather."
      kind: "muted"
      font.pixelSize: Theme.font.small
      wrapMode: Text.Wrap
    }
  }

  // --- Notifications -----------------------------------------------------------------
  Block {
    icon: "bell"
    title: "Notifications" + (Notifications.count > 0 ? " · " + Notifications.count : "")
    tab: "notifications"

    Repeater {
      model: Notifications.history.slice(0, 3)
      ColumnLayout {
        id: n
        required property Notification modelData
        Layout.fillWidth: true
        spacing: 0
        RowLayout {
          Layout.fillWidth: true
          Label { Layout.fillWidth: true; text: n.modelData.appName || "App"; font.pixelSize: Theme.font.label; font.weight: Font.Bold; elide: Text.ElideRight }
          Label { text: Notifications.timeOf(n.modelData); kind: "muted"; font.pixelSize: Theme.font.label }
        }
        Label { Layout.fillWidth: true; text: n.modelData.summary; font.pixelSize: Theme.font.small; elide: Text.ElideRight }
      }
    }

    Label {
      visible: Notifications.count === 0
      text: Notifications.quiet ? "All caught up · Do not disturb" : "All caught up"
      kind: "muted"
      font.pixelSize: Theme.font.small
    }
    Label {
      visible: Notifications.count > 3
      text: "+" + (Notifications.count - 3) + " more"
      kind: "muted"
      font.pixelSize: Theme.font.label
    }
  }
}
