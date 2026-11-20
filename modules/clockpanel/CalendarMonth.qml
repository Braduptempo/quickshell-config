// CalendarMonth.qml
// Month grid with ISO week numbers, Monday first. Today is filled with the
// accent, the selected day gets a ring, days of other months are dimmed.
// Scroll over the grid or use the arrows to change month.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

ColumnLayout {
  id: root

  property date selected: Time.date
  // First day of the month that is shown
  property date month: new Date(Time.date.getFullYear(), Time.date.getMonth(), 1)

  function sameDay(a: date, b: date): bool {
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  function isoWeek(d: date): int {
    const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    const weekday = t.getUTCDay() || 7;
    t.setUTCDate(t.getUTCDate() + 4 - weekday);
    const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
    return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
  }

  function shift(months: int): void {
    month = new Date(month.getFullYear(), month.getMonth() + months, 1);
  }

  function goToday(): void {
    month = new Date(Time.date.getFullYear(), Time.date.getMonth(), 1);
    selected = Time.date;
  }

  // Monday on or before the 1st
  readonly property date gridStart: {
    const offset = (month.getDay() + 6) % 7;
    return new Date(month.getFullYear(), month.getMonth(), 1 - offset);
  }

  function dayAt(week: int, weekday: int): date {
    return new Date(gridStart.getFullYear(), gridStart.getMonth(), gridStart.getDate() + week * 7 + weekday);
  }

  spacing: 10

  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    Label {
      text: Qt.formatDate(root.month, "MMMM yyyy")
      kind: "title"
      Layout.fillWidth: true
    }

    Button {
      visible: root.month.getMonth() !== Time.date.getMonth() || root.month.getFullYear() !== Time.date.getFullYear()
      text: "Today"
      size: Theme.size.buttonList
      variant: "ghost"
      onClicked: root.goToday()
    }

    IconButton {
      icon: "chevron-left"
      size: 30
      accessibleName: "Previous month"
      onClicked: root.shift(-1)
    }

    IconButton {
      icon: "chevron-right"
      size: 30
      accessibleName: "Next month"
      onClicked: root.shift(1)
    }
  }

  Column {
    id: grid
    Layout.fillWidth: true
    spacing: 3

    WheelHandler {
      onWheel: event => root.shift(event.angleDelta.y > 0 ? -1 : 1)
    }

    // Header: week column + Mon…Sun
    Row {
      spacing: 3
      Label { width: 28; text: "Wk"; kind: "label"; font.capitalization: Font.MixedCase; horizontalAlignment: Text.AlignHCenter }
      Repeater {
        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
        Label {
          required property string modelData
          width: (grid.width - 28 - 7 * 3) / 7
          text: modelData
          kind: "label"
          font.capitalization: Font.MixedCase
          horizontalAlignment: Text.AlignHCenter
        }
      }
    }

    Repeater {
      model: 6

      Row {
        id: week
        required property int index
        spacing: 3

        Label {
          width: 28
          height: 36
          text: root.isoWeek(root.dayAt(week.index, 0))
          kind: "muted"
          font.pixelSize: Theme.font.label
          horizontalAlignment: Text.AlignHCenter
        }

        Repeater {
          model: 7

          Item {
            id: cell
            required property int index
            readonly property date day: root.dayAt(week.index, index)
            readonly property bool today: root.sameDay(day, Time.date)
            readonly property bool selected: root.sameDay(day, root.selected)
            readonly property bool otherMonth: day.getMonth() !== root.month.getMonth()

            width: (grid.width - 28 - 7 * 3) / 7
            height: 36

            Accessible.role: Accessible.Button
            Accessible.name: Qt.formatDate(day, "dddd d MMMM") + (today ? ", today" : "")

            Rectangle {
              anchors.centerIn: parent
              width: 34
              height: 34
              radius: 17
              color: cell.today ? Theme.accent : dayMouse.containsMouse ? Theme.item : "transparent"
              border.width: cell.selected && !cell.today ? 1 : 0
              border.color: Theme.accent

              Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
            }

            Label {
              anchors.centerIn: parent
              text: cell.day.getDate()
              color: cell.today ? Theme.onAccent : cell.otherMonth ? Theme.alpha(Theme.subtext, 0.6) : Theme.text
              font.weight: cell.today || cell.selected ? Font.Bold : Font.Normal
            }

            MouseArea {
              id: dayMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                root.selected = cell.day;
                if (cell.otherMonth) root.month = new Date(cell.day.getFullYear(), cell.day.getMonth(), 1);
              }
            }
          }
        }
      }
    }
  }
}
