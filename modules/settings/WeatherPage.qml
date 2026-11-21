// WeatherPage.qml
// The place for the weather (searched by name, never detected), units, and
// whether the lock screen shows it.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Weather"
  description: "Shown in the clock panel and on the lock screen. Only the coordinates of the place you choose are sent to Open-Meteo; your location is never detected."
  resetAction: () => {
    Config.weather.units = "celsius";
    Config.weather.showOnLock = true;
  }

  // --- Where ------------------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: placeColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: placeColumn
      x: 14
      y: 12
      width: parent.width - 28
      spacing: 8

      Label { text: "Place"; kind: "label" }

      RowLayout {
        visible: Weather.configured
        Layout.fillWidth: true
        spacing: 10
        Icon { name: Weather.current ? Weather.icon(Weather.current.code, Weather.current.isDay) : "cloud"; size: 18; color: Theme.accent }
        ColumnLayout {
          Layout.fillWidth: true
          spacing: 1
          Label { text: Config.weather.place; font.weight: Font.Bold }
          Label {
            text: Weather.error !== "" ? Weather.error
                : Weather.current ? Weather.degrees(Weather.current.temperature) + " · " + Weather.describe(Weather.current.code) + " · updated " + Qt.formatDateTime(new Date(Weather.updated), "HH:mm")
                : "Loading…"
            color: Weather.error !== "" ? Theme.error : Theme.subtext
            font.pixelSize: Theme.font.label
          }
        }
        Button { text: "Refresh"; variant: "ghost"; size: Theme.size.buttonRow; onClicked: Weather.refresh() }
        Button {
          text: "Remove"
          variant: "dangerSoft"
          size: Theme.size.buttonRow
          onClicked: {
            Config.weather.place = "";
            Config.weather.latitude = 0;
            Config.weather.longitude = 0;
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 38
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.crust, 0.5)
        border.width: search.activeFocus ? 1 : 0
        border.color: Theme.accent

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          spacing: 10
          Icon { name: "search"; size: 14; color: Theme.subtext }
          TextInput {
            id: search
            Layout.fillWidth: true
            color: Theme.text
            font.family: Theme.font.family
            font.pixelSize: Theme.font.body
            clip: true
            Accessible.role: Accessible.EditableText
            Accessible.name: "Search a city"
            onTextChanged: searchDelay.restart()
            Keys.onReturnPressed: Weather.search(text)
            Label {
              visible: search.text === ""
              anchors.verticalCenter: parent.verticalCenter
              text: Weather.configured ? "Search another city…" : "Search your city…"
              kind: "muted"
            }
          }
          Label { visible: Weather.searching; text: "Searching…"; kind: "muted"; font.pixelSize: Theme.font.label }
        }
      }

      Timer {
        id: searchDelay
        interval: 450
        onTriggered: Weather.search(search.text)
      }

      Repeater {
        model: Weather.places

        Rectangle {
          id: result
          required property var modelData
          Layout.fillWidth: true
          implicitHeight: 40
          radius: Theme.pill(height)
          color: resultMouse.containsMouse ? Theme.hover(Theme.item) : "transparent"

          Accessible.role: Accessible.Button
          Accessible.name: modelData.name + ", " + modelData.detail

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            Icon { name: "map"; size: 14; color: Theme.subtext }
            Label { text: result.modelData.name; font.weight: Font.Bold }
            Label { Layout.fillWidth: true; text: result.modelData.detail; kind: "muted"; font.pixelSize: Theme.font.small; elide: Text.ElideRight }
          }

          MouseArea {
            id: resultMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Weather.choose(result.modelData);
              search.text = "";
            }
          }
        }
      }
    }
  }

  // --- Options ------------------------------------------------------------------------------
  SettingRow {
    title: "Units"
    Segmented {
      model: ["°C, km/h", "°F, mph"]
      currentIndex: Config.weather.units === "fahrenheit" ? 1 : 0
      accessibleName: "Units"
      onActivated: index => Config.weather.units = index === 1 ? "fahrenheit" : "celsius"
    }
  }
  SettingRow {
    title: "On the lock screen"
    subtitle: "The temperature and sky under the clock."
    Toggle { checked: Config.weather.showOnLock; accessibleName: "Weather on the lock screen"; onToggled: value => Config.weather.showOnLock = value }
  }

  Label {
    Layout.fillWidth: true
    text: "Weather data by Open-Meteo.com (CC BY 4.0)"
    kind: "muted"
    font.pixelSize: Theme.font.label
  }
}
