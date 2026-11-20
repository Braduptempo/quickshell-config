// ClockPanel.qml
// Opens from the clock: a Calendar tab (month and the chosen day) and a
// Notifications tab (history, Do not disturb, clear all).
// Click outside or Esc closes it.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import "../../config"
import "../../components"
import "../../services"
import "../notifications"

PanelWindow {
  id: window

  readonly property bool shown: Panels.clockPanelOpen
  readonly property string style: Config.animations.panelStyle

  screen: Panels.clockScreen
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-clockpanel"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  // Only anchored to the top (or bottom): the compositor centres it under the clock
  // Opens from the bar: at the top, or at the bottom when the bar is there
  readonly property bool fromBottom: Config.bar.position === "bottom"

  anchors.top: !window.fromBottom
  anchors.bottom: window.fromBottom
  margins.top: 6
  margins.bottom: 6
  implicitWidth: 720 + 24
  implicitHeight: card.implicitHeight + 24

  onShownChanged: if (shown && Panels.clockTab === "notifications") Notifications.markRead()

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.closeClockPanel()
  }

  GlassPanel {
    id: card

    x: 12
    width: 720
    implicitHeight: content.implicitHeight + 32
    height: implicitHeight
    focus: true
    transformOrigin: window.fromBottom ? Item.Bottom : Item.Top

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.94

    Behavior on opacity {
      NumberAnimation {
        duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut
        easing.type: Easing.BezierSpline
        easing.bezierCurve: window.shown ? Theme.anim.emphasized : Theme.anim.accelerate
      }
    }
    Behavior on y { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    Keys.onEscapePressed: Panels.closeClockPanel()

    ColumnLayout {
      id: content
      x: 16
      y: 16
      width: parent.width - 32
      spacing: 14

      // --- Tabs ---------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Segmented {
          model: ["Calendar", "Notifications" + (Notifications.count > 0 ? " · " + Notifications.count : "")]
          currentIndex: Panels.clockTab === "notifications" ? 1 : 0
          accessibleName: "Clock panel"
          onActivated: index => {
            Panels.clockTab = index === 1 ? "notifications" : "calendar";
            if (index === 1) Notifications.markRead();
          }
        }

        Item { Layout.fillWidth: true }

        Label {
          text: Qt.formatDate(Time.date, "dddd d MMMM")
          kind: "muted"
        }
      }

      // --- Calendar --------------------------------------------------------------
      RowLayout {
        visible: Panels.clockTab !== "notifications"
        Layout.fillWidth: true
        spacing: 20

        CalendarMonth {
          id: month
          Layout.preferredWidth: 360
          Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          spacing: 10

          Label {
            text: month.sameDay(month.selected, Time.date) ? "Today" : Qt.formatDate(month.selected, "dddd")
            kind: "label"
          }
          Label {
            text: Qt.formatDate(month.selected, "d MMMM yyyy")
            kind: "section"
          }

          readonly property var dayEvents: Calendar.eventsOn(month.selected)

          // That day's events
          Repeater {
            model: parent.dayEvents

            Rectangle {
              id: eventRow
              required property var modelData
              Layout.fillWidth: true
              implicitHeight: eventColumn.implicitHeight + 18
              radius: Theme.radiusCard
              color: Theme.item

              Rectangle { x: 8; y: 9; width: 4; height: parent.height - 18; radius: 2; color: eventRow.modelData.color }

              ColumnLayout {
                id: eventColumn
                x: 22
                y: 9
                width: parent.width - 32
                spacing: 2
                Label { text: eventRow.modelData.title; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                Label {
                  text: (eventRow.modelData.allDay ? "All day" : Qt.formatDateTime(new Date(eventRow.modelData.start), "HH:mm") + " – " + Qt.formatDateTime(new Date(eventRow.modelData.end), "HH:mm"))
                      + (eventRow.modelData.location !== "" ? " · " + eventRow.modelData.location : "")
                  kind: "muted"
                  font.pixelSize: Theme.font.small
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
                Label { text: eventRow.modelData.calendar; color: eventRow.modelData.color; font.pixelSize: Theme.font.label }
              }
            }
          }

          Card {
            visible: parent.dayEvents.length === 0
            Layout.fillWidth: true
            implicitHeight: noEvents.implicitHeight + 32

            ColumnLayout {
              id: noEvents
              anchors.centerIn: parent
              width: parent.width - 32
              spacing: 6

              Icon {
                name: "calendar"
                size: 22
                color: Theme.subtext
                Layout.alignment: Qt.AlignHCenter
              }
              Label {
                text: "No events"
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
              }
              Label {
                text: Config.calendar.sources.length === 0 ? "Add a calendar in Settings → Calendars and its events show here." : "Nothing on this day."
                kind: "muted"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                Layout.fillWidth: true
              }
              Button {
                visible: Config.calendar.sources.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "Add a calendar"
                variant: "ghost"
                size: Theme.size.buttonRow
                onClicked: {
                  Panels.closeClockPanel();
                  Panels.openSettings(null, "calendars");
                }
              }
            }
          }
        }
      }

      // --- Notifications -------------------------------------------------------
      ColumnLayout {
        visible: Panels.clockTab === "notifications"
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
    }
  }
}
