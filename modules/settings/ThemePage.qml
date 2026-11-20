// ThemePage.qml
// Colour theme, accent and how see-through the panels are.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Theme"
  description: "Colours of the whole shell. Changes apply right away. Super + T switches quickly."
  resetAction: () => {
    Config.appearance.theme = "Mocha";
    Config.appearance.accent = "";
    Config.appearance.glass = 0.45;
  }

  readonly property var accents: ["", "#89b4fa", "#b4befe", "#cba6f7", "#f5c2e7", "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1"]

  GridLayout {
    Layout.fillWidth: true
    columns: 4
    columnSpacing: 10
    rowSpacing: 10

    Repeater {
      model: Palettes.list

      Rectangle {
        id: card
        required property var modelData
        readonly property bool chosen: Config.appearance.theme === modelData.name

        Layout.fillWidth: true
        implicitHeight: 96
        radius: Theme.radiusCard
        color: modelData.base
        border.width: chosen ? 2 : 1
        border.color: chosen ? Theme.accent : Qt.rgba(1, 1, 1, 0.12)

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData.name
        Accessible.checked: chosen

        Rectangle { x: 10; y: 10; width: parent.width - 20; height: 9; radius: 4; color: card.modelData.surface }
        Rectangle { x: 10; y: 26; width: parent.width * 0.4; height: 6; radius: 3; color: card.modelData.text }
        Rectangle { x: 10; y: 37; width: parent.width * 0.28; height: 6; radius: 3; color: card.modelData.subtext }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: 10; y: 26; width: parent.width * 0.3; height: 17; radius: 8; color: card.modelData.accent }

        Row {
          x: 10
          y: 52
          spacing: 3
          Repeater {
            model: card.modelData.dots
            Rectangle { required property string modelData; width: 9; height: 9; radius: 5; color: modelData }
          }
        }

        Text {
          x: 10
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          text: card.modelData.name
          color: card.modelData.text
          font.family: Theme.font.family
          font.pixelSize: Theme.font.small
          font.weight: card.chosen ? Font.Bold : Font.Normal
        }

        Icon {
          visible: card.chosen
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 8
          name: "check"
          size: 14
          strokeWidth: 3
          color: card.modelData.accent
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.appearance.theme = card.modelData.name
        }
      }
    }
  }

  SettingRow {
    title: "Accent"
    subtitle: "Buttons, sliders and highlights. The first one is the theme's own."

    Repeater {
      model: page.accents

      Rectangle {
        id: swatch
        required property string modelData
        width: 24
        height: 24
        radius: 12
        color: modelData !== "" ? modelData : Theme.palette.accent
        border.width: Config.appearance.accent === modelData ? 2 : 0
        border.color: Theme.text

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData !== "" ? modelData : "Theme default"
        Accessible.checked: Config.appearance.accent === modelData

        Rectangle { visible: swatch.modelData === ""; anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.base }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.appearance.accent = swatch.modelData
        }
      }
    }
  }

  SettingRow {
    title: "Glass"
    subtitle: "How much of what's behind shows through the bar and panels."

    PillSlider {
      width: 220
      icon: "image"
      label: "Glass"
      // 0.2 … 1 shown as 0 … 100%
      value: (Config.appearance.glass - 0.2) / 0.8
      throttle: 50
      onMoved: v => Config.appearance.glass = Math.round((0.2 + v * 0.8) * 100) / 100
    }
  }
}
