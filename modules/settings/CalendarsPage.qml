// CalendarsPage.qml
// Calendars by ICS link, how often they sync, and the first day of the week.
// Their events show in the clock panel (services/Calendar.qml).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Calendars"
  description: "Add a calendar by its ICS link; its events show in the clock panel. The links are kept in settings.json, so treat that file as private."

  readonly property var colors: ["#89b4fa", "#cba6f7", "#f5c2e7", "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1", "#94e2d5"]
  readonly property var intervals: [5, 15, 60, 0]
  property string newColor: colors[0]

  function setSources(list: var): void {
    Config.calendar.sources = list;
  }

  function add(name: string, url: string, color: string): void {
    if (url.trim() === "") return;
    setSources(Config.calendar.sources.concat([{ name: name.trim() || "Calendar", url: url.trim(), color, enabled: true }]));
  }

  // --- The calendars ---------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: listColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: listColumn
      x: 14
      y: 12
      width: parent.width - 28
      spacing: 4

      RowLayout {
        Layout.fillWidth: true
        Label { text: "Your calendars"; kind: "label"; Layout.fillWidth: true }
        Label {
          text: Calendar.syncing ? "Syncing…" : Calendar.lastSync > 0 ? "Synced " + Qt.formatDateTime(new Date(Calendar.lastSync), "HH:mm") + " · " + Calendar.events.length + " events" : ""
          kind: "muted"
          font.pixelSize: Theme.font.label
        }
        Button { text: "Sync now"; variant: "ghost"; size: Theme.size.buttonRow; onClicked: Calendar.sync() }
      }

      Label {
        visible: Config.calendar.sources.length === 0
        text: "None yet. Add one below."
        kind: "muted"
      }

      Repeater {
        model: Config.calendar.sources

        RowLayout {
          id: source
          required property var modelData
          required property int index
          readonly property string error: Calendar.errors[modelData.name] ?? ""

          Layout.fillWidth: true
          implicitHeight: 46
          spacing: 10

          Rectangle { implicitWidth: 12; implicitHeight: 12; radius: Theme.r(6); color: source.modelData.color }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label { text: source.modelData.name; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
            Label {
              // The link is secret: only the host
              text: source.error !== "" ? source.error : (source.modelData.url.match(/^\w+:\/\/([^/]+)/)?.[1] ?? source.modelData.url)
              color: source.error !== "" ? Theme.error : Theme.subtext
              font.pixelSize: Theme.font.label
              elide: Text.ElideRight
              Layout.fillWidth: true
            }
          }
          Toggle {
            checked: source.modelData.enabled !== false
            accessibleName: "Show " + source.modelData.name
            onToggled: value => {
              const list = Config.calendar.sources.slice();
              list[source.index] = Object.assign({}, list[source.index], { enabled: value });
              page.setSources(list);
            }
          }
          IconButton {
            size: 30
            icon: "trash"
            variant: "plain"
            accessibleName: "Remove " + source.modelData.name
            onClicked: page.setSources(Config.calendar.sources.filter((s, i) => i !== source.index))
          }
        }
      }
    }
  }

  // --- Adding one -----------------------------------------------------------------------------
  component Field: Rectangle {
    id: field
    property alias text: input.text
    property string placeholder
    Layout.fillWidth: true
    implicitHeight: 36
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.crust, 0.5)
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent

    TextInput {
      id: input
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      verticalAlignment: TextInput.AlignVCenter
      color: Theme.text
      font.family: Theme.font.family
      font.pixelSize: Theme.font.small
      clip: true
      Accessible.role: Accessible.EditableText
      Accessible.name: field.placeholder
      Label { visible: input.text === ""; anchors.verticalCenter: parent.verticalCenter; text: field.placeholder; kind: "muted"; font.pixelSize: Theme.font.small }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: addColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: addColumn
      x: 14
      y: 12
      width: parent.width - 28
      spacing: 8

      Label { text: "Add a calendar"; kind: "label" }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Field { id: nameField; Layout.preferredWidth: 180; Layout.fillWidth: false; placeholder: "Name (e.g. Work)" }
        Field { id: urlField; placeholder: "ICS link: https://… or webcal://…" }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Label { text: "Colour"; kind: "muted"; font.pixelSize: Theme.font.small }
        Repeater {
          model: page.colors
          Rectangle {
            id: swatch
            required property string modelData
            width: 22
            height: 22
            radius: Theme.r(11)
            color: modelData
            border.width: page.newColor === modelData ? 2 : 0
            border.color: Theme.text
            Accessible.role: Accessible.RadioButton
            Accessible.name: modelData
            Accessible.checked: page.newColor === modelData
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: page.newColor = swatch.modelData }
          }
        }
        Item { Layout.fillWidth: true }
        Button {
          text: "Add"
          variant: "primary"
          size: Theme.size.buttonList
          onClicked: {
            page.add(nameField.text, urlField.text, page.newColor);
            nameField.text = "";
            urlField.text = "";
          }
        }
      }

      Label {
        Layout.fillWidth: true
        wrapMode: Text.Wrap
        kind: "muted"
        font.pixelSize: Theme.font.label
        lineHeight: 1.3
        text: "Where to find the link:\n"
            + "· Google: Calendar settings → your calendar → \"Secret address in iCal format\"\n"
            + "· Nextcloud: Calendar → ⋯ next to the calendar → \"Copy subscription link\"\n"
            + "· Outlook: Settings → Calendar → Shared calendars → \"Publish a calendar\" → ICS"
      }

      RowLayout {
        spacing: 8
        Label { text: "Or add"; kind: "muted"; font.pixelSize: Theme.font.small }
        Button {
          text: "Dutch holidays"
          variant: "ghost"
          size: Theme.size.buttonRow
          onClicked: page.add("Holidays NL", "https://calendar.google.com/calendar/ical/nl.dutch%23holiday%40group.v.calendar.google.com/public/basic.ics", "#a6e3a1")
        }
      }
    }
  }

  // --- Options ----------------------------------------------------------------------------------
  SettingRow {
    title: "Sync"
    subtitle: "How often the calendars are fetched again."
    Segmented {
      model: ["5 min", "15 min", "1 hour", "By hand"]
      currentIndex: Math.max(0, page.intervals.indexOf(Config.calendar.refreshMinutes))
      accessibleName: "Sync interval"
      onActivated: index => Config.calendar.refreshMinutes = page.intervals[index]
    }
  }
  SettingRow {
    title: "Week starts on"
    Segmented {
      model: ["Monday", "Sunday"]
      currentIndex: Config.calendar.weekStart === "sunday" ? 1 : 0
      accessibleName: "Week starts on"
      onActivated: index => Config.calendar.weekStart = index === 1 ? "sunday" : "monday"
    }
  }
}
