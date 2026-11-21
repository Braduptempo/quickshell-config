// CalendarTab.qml
// The month, and the chosen day: its weather (today) and events. "New event"
// adds one to the "This computer" calendar; those can be deleted here too.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

RowLayout {
  id: root
  Layout.fillWidth: true
  spacing: 20

  property bool adding: false
  property string formError: ""

  // "14:30", "14.30" or "9" -> minutes after midnight; -1 when it isn't a time
  function minutes(text: string): int {
    const m = text.trim().match(/^(\d{1,2})(?:[:.](\d{2}))?$/);
    if (!m) return -1;
    const h = parseInt(m[1]);
    const min = parseInt(m[2] ?? "0");
    return h < 24 && min < 60 ? h * 60 + min : -1;
  }

  // The form starts at the next whole hour, for an hour
  function hourText(offset: int): string {
    return String((Time.date.getHours() + offset) % 24).padStart(2, "0") + ":00";
  }

  function resetForm(): void {
    adding = false;
    formError = "";
    title.text = "";
    place.text = "";
    allDay.checked = false;
    from.text = hourText(1);
    to.text = hourText(2);
  }

  function saveEvent(what: string, whole: bool, fromText: string, toText: string, where: string): void {
    if (what.trim() === "") {
      formError = "Give it a name";
      return;
    }
    const d = month.selected;
    const day = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
    let start = day;
    let end = day + 86400000;
    if (!whole) {
      const a = minutes(fromText);
      const b = minutes(toText);
      if (a < 0 || b < 0) {
        formError = "Times like 14:00";
        return;
      }
      start = day + a * 60000;
      // Ending before it starts: it ends the next day
      end = day + (b > a ? b : b + 1440) * 60000;
    }
    Calendar.addLocal({ title: what.trim(), start: start, end: end, allDay: whole, location: where.trim() });
    resetForm();
  }

  Component.onCompleted: {
    from.text = hourText(1);
    to.text = hourText(2);
  }

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

    // --- That day's weather, when it's in the forecast (the Weather tab has more) ---
    readonly property var dayWeather: Weather.days.find(d => month.sameDay(d.date, month.selected)) ?? null

    Rectangle {
      id: dayWeatherRow
      readonly property var w: parent.dayWeather
      visible: w !== null
      Layout.fillWidth: true
      implicitHeight: 40
      radius: Theme.pill(height)
      color: dayWeatherMouse.containsMouse ? Theme.hover(Theme.item) : Theme.item

      Accessible.role: Accessible.Button
      Accessible.name: "Weather details"

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        spacing: 10
        Icon { name: dayWeatherRow.w ? Weather.icon(dayWeatherRow.w.code, true) : "cloud"; size: 18; color: Theme.accent }
        Label {
          Layout.fillWidth: true
          readonly property var w: dayWeatherRow.w
          text: w ? Weather.degrees(w.max) + " / " + Weather.degrees(w.min) + " · " + Weather.describe(w.code) + (w.rain >= 20 ? " · rain " + w.rain + "%" : "") : ""
          font.pixelSize: Theme.font.small
          elide: Text.ElideRight
        }
        Icon { name: "chevron-right"; size: 14; color: Theme.subtext }
      }
      MouseArea {
        id: dayWeatherMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Panels.clockTab = "weather"
      }
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
          width: parent.width - (eventRow.modelData.local ? 66 : 32)
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

        // Your own events can go again
        IconButton {
          visible: eventRow.modelData.local === true
          anchors.right: parent.right
          anchors.rightMargin: 8
          anchors.verticalCenter: parent.verticalCenter
          icon: "trash"
          size: 28
          variant: "plain"
          accessibleName: "Delete " + eventRow.modelData.title
          onClicked: Calendar.removeLocal(eventRow.modelData.id)
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
          text: Config.calendar.sources.length === 0 ? "Make one with New event, or add a calendar in Settings → Calendars." : "Nothing on this day."
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

    // --- New event, on the chosen day, in "This computer" -------------------------------
    Button {
      visible: !root.adding
      text: "New event"
      icon: "plus"
      variant: "ghost"
      size: Theme.size.buttonRow
      onClicked: {
        root.adding = true;
        title.focusInput();
      }
    }

    ColumnLayout {
      visible: root.adding
      Layout.fillWidth: true
      spacing: 6

      Label { text: "New event · " + Qt.formatDate(month.selected, "d MMMM"); kind: "label" }
      TextField { id: title; Layout.fillWidth: true; placeholder: "What"; onAccepted: save.clicked() }
      RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Label { text: "All day"; font.pixelSize: Theme.font.small; Layout.fillWidth: true }
        Toggle { id: allDay; accessibleName: "All day"; onToggled: value => checked = value }
      }
      RowLayout {
        visible: !allDay.checked
        Layout.fillWidth: true
        spacing: 6
        TextField { id: from; Layout.fillWidth: true; placeholder: "From, 14:00"; error: text !== "" && root.minutes(text) < 0 }
        TextField { id: to; Layout.fillWidth: true; placeholder: "To, 15:00"; error: text !== "" && root.minutes(text) < 0 }
      }
      TextField { id: place; Layout.fillWidth: true; placeholder: "Where (optional)" }
      Label {
        visible: root.formError !== ""
        text: root.formError
        color: Theme.error
        font.pixelSize: Theme.font.label
      }
      RowLayout {
        Layout.alignment: Qt.AlignRight
        spacing: 6
        Button { text: "Cancel"; variant: "ghost"; size: Theme.size.buttonRow; onClicked: root.resetForm() }
        Button {
          id: save
          text: "Save"
          variant: "primary"
          size: Theme.size.buttonRow
          onClicked: root.saveEvent(title.text, allDay.checked, from.text, to.text, place.text)
        }
      }
    }
  }
}
