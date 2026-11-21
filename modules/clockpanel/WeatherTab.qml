// WeatherTab.qml
// The weather in full: now, the next 24 hours, and 7 days with rain, wind,
// UV and the sun. The place is set in Settings → Weather.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

ColumnLayout {
  id: root

  readonly property var now: Weather.current
  readonly property var today: Weather.days[0] ?? null

  spacing: 14

  // --- No place yet -----------------------------------------------------------------
  ColumnLayout {
    visible: !Weather.configured
    Layout.fillWidth: true
    Layout.topMargin: 24
    Layout.bottomMargin: 24
    spacing: 8
    Icon { name: "cloud-sun"; size: 28; color: Theme.subtext; Layout.alignment: Qt.AlignHCenter }
    Label { text: "No place chosen"; kind: "title"; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
    Label { text: "Pick your city and the weather shows here, in the bar and on the lock screen."; kind: "muted"; wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true }
    Button {
      Layout.alignment: Qt.AlignHCenter
      text: "Choose a place"
      variant: "ghost"
      size: Theme.size.buttonRow
      onClicked: {
        Panels.closeClockPanel();
        Panels.openSettings(null, "weather");
      }
    }
  }

  Label {
    visible: Weather.configured && root.now === null
    text: Weather.error !== "" ? Weather.error : "Loading the weather…"
    color: Weather.error !== "" ? Theme.error : Theme.subtext
  }

  // --- Now ----------------------------------------------------------------------------
  RowLayout {
    visible: root.now !== null
    Layout.fillWidth: true
    spacing: 16

    Icon { name: root.now ? Weather.icon(root.now.code, root.now.isDay) : "cloud"; size: 44; color: Theme.accent }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2
      Label { text: root.now ? Weather.degrees(root.now.temperature) + "  " + Weather.describe(root.now.code) : ""; kind: "section" }
      Label {
        text: root.now ? Config.weather.place + " · feels like " + Weather.degrees(root.now.feelsLike)
                         + (root.today ? " · " + Weather.degrees(root.today.max) + " / " + Weather.degrees(root.today.min) : "") : ""
        kind: "muted"
        font.pixelSize: Theme.font.small
        elide: Text.ElideRight
        Layout.fillWidth: true
      }
    }

    // Wind, humidity, UV, sun
    GridLayout {
      columns: 2
      columnSpacing: 14
      rowSpacing: 4
      component Fact: Row {
        property string icon
        property string text
        spacing: 6
        Icon { name: parent.icon; size: 13; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
        Label { text: parent.text; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter }
      }
      Fact { icon: "wind"; text: root.now ? root.now.wind + " " + Weather.windUnit + " " + Weather.compass(root.now.windDir) : "" }
      Fact { icon: "droplet"; text: root.now ? root.now.humidity + "% humidity" : "" }
      Fact { icon: "sun"; text: root.today ? "UV " + root.today.uv + " · " + Weather.uvLevel(root.today.uv) : "" }
      Fact {
        icon: "moon"
        text: root.today && root.today.sunrise ? Qt.formatTime(root.today.sunrise, "HH:mm") + " – " + Qt.formatTime(root.today.sunset, "HH:mm") : ""
      }
    }
  }

  Label {
    visible: Weather.rainNote !== ""
    text: Weather.rainNote
    color: Theme.accent
    font.pixelSize: Theme.font.small
    font.weight: Font.Bold
  }

  // --- The next 24 hours -------------------------------------------------------------
  Label { visible: Weather.hours.length > 0; text: "Next hours"; kind: "label" }

  Flickable {
    visible: Weather.hours.length > 0
    Layout.fillWidth: true
    implicitHeight: hourRow.implicitHeight
    contentWidth: hourRow.implicitWidth
    flickableDirection: Flickable.HorizontalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    // A mouse wheel scrolls it sideways
    WheelHandler {
      onWheel: event => parent.contentX = Math.max(0, Math.min(parent.contentWidth - parent.width, parent.contentX - event.angleDelta.y))
    }

    Row {
      id: hourRow
      spacing: 6
      Repeater {
        model: Weather.hours
        Rectangle {
          id: hour
          required property var modelData
          required property int index
          width: 52
          height: hourColumn.implicitHeight + 16
          radius: Theme.r(14)
          color: index === 0 ? Theme.alpha(Theme.accent, 0.14) : Theme.item
          Column {
            id: hourColumn
            anchors.centerIn: parent
            spacing: 4
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: hour.index === 0 ? "Now" : Qt.formatTime(hour.modelData.time, "HH"); kind: "muted"; font.pixelSize: Theme.font.label }
            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.icon(hour.modelData.code, hour.modelData.isDay); size: 16; color: Theme.text }
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: Weather.degrees(hour.modelData.temperature); font.pixelSize: Theme.font.small; font.weight: Font.Bold }
            Label {
              anchors.horizontalCenter: parent.horizontalCenter
              text: hour.modelData.rain >= 10 ? hour.modelData.rain + "%" : " "
              color: Theme.accent
              font.pixelSize: Theme.font.label
            }
          }
        }
      }
    }
  }

  // --- 7 days ------------------------------------------------------------------------
  Label { visible: Weather.days.length > 0; text: "7 days"; kind: "label" }

  Card {
    visible: Weather.days.length > 0
    Layout.fillWidth: true
    implicitHeight: dayList.implicitHeight + 8

    readonly property real low: Math.min(...Weather.days.map(d => d.min))
    readonly property real high: Math.max(...Weather.days.map(d => d.max))

    Column {
      id: dayList
      y: 4
      width: parent.width

      Repeater {
        model: Weather.days
        RowLayout {
          id: day
          required property var modelData
          required property int index
          readonly property var card: dayList.parent
          width: dayList.width - 28
          x: 14
          height: 36
          spacing: 12

          Label { text: day.index === 0 ? "Today" : Qt.formatDate(day.modelData.date, "ddd d"); Layout.preferredWidth: 64; font.pixelSize: Theme.font.small }
          Icon { name: Weather.icon(day.modelData.code, true); size: 16; color: Theme.text }
          Label { text: day.modelData.rain >= 10 ? day.modelData.rain + "%" : ""; color: Theme.accent; font.pixelSize: Theme.font.label; Layout.preferredWidth: 34 }
          Label { text: Weather.degrees(day.modelData.min); kind: "muted"; font.pixelSize: Theme.font.small; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignRight }

          // Where the day's range sits in the week's
          Rectangle {
            Layout.fillWidth: true
            implicitHeight: 6
            radius: Theme.r(3)
            color: Theme.alpha(Theme.text, 0.1)
            Rectangle {
              readonly property real span: Math.max(1, day.card.high - day.card.low)
              x: parent.width * (day.modelData.min - day.card.low) / span
              width: Math.max(6, parent.width * (day.modelData.max - day.modelData.min) / span)
              height: parent.height
              radius: Theme.r(3)
              color: Theme.accent
            }
          }

          Label { text: Weather.degrees(day.modelData.max); font.pixelSize: Theme.font.small; font.weight: Font.Bold; Layout.preferredWidth: 32 }
          Label { text: day.modelData.wind + " " + Weather.windUnit; kind: "muted"; font.pixelSize: Theme.font.label; Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
        }
      }
    }
  }

  Label {
    visible: Weather.configured
    text: "Open-Meteo.com · updated " + (Weather.updated > 0 ? Qt.formatTime(new Date(Weather.updated), "HH:mm") : "–")
    kind: "muted"
    font.pixelSize: Theme.font.label
  }
}
