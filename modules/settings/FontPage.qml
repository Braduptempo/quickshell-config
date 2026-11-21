// FontPage.qml
// The font of the whole shell and its size.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

SettingsPage {
  id: page
  title: "Font"
  description: "Used everywhere in the shell. A monospace font keeps numbers lined up."
  resetAction: () => {
    Config.appearance.fontFamily = "JetBrains Mono";
    Config.appearance.fontScale = 1.0;
  }

  readonly property var scales: [0.9, 1.0, 1.1, 1.25]
  property string query: ""
  readonly property var families: Qt.fontFamilies().filter(f => !f.startsWith(".") && (query === "" || f.toLowerCase().includes(query.toLowerCase())))

  SettingRow {
    title: "Size"
    subtitle: "Scales all text."
    Segmented {
      model: ["90%", "100%", "110%", "125%"]
      currentIndex: Math.max(0, page.scales.indexOf(Config.appearance.fontScale))
      accessibleName: "Font size"
      onActivated: index => Config.appearance.fontScale = page.scales[index]
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 38
    radius: Theme.pill(height)
    color: Theme.item

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
        onTextChanged: page.query = text
        Accessible.role: Accessible.EditableText
        Accessible.name: "Search fonts"
        Label { visible: search.text === ""; text: "Search " + page.families.length + " fonts…"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 320
    radius: Theme.radiusCard
    color: Theme.item

    ListView {
      id: fontList
      anchors.fill: parent
      anchors.margins: 6
      clip: true
      model: page.families
      spacing: 2
      boundsBehavior: Flickable.StopAtBounds

      delegate: Rectangle {
        id: fontRow
        required property string modelData
        readonly property bool chosen: modelData === Config.appearance.fontFamily

        width: fontList.width
        height: 40
        radius: Theme.pill(height)
        color: chosen ? Theme.alpha(Theme.accent, 0.16) : rowMouse.containsMouse ? Theme.item : "transparent"
        border.width: chosen ? 1 : 0
        border.color: Theme.alpha(Theme.accent, 0.5)

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData
        Accessible.checked: chosen

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          Text {
            Layout.fillWidth: true
            text: fontRow.modelData
            color: Theme.text
            font.family: fontRow.modelData
            font.pixelSize: Theme.font.body + 1
            elide: Text.ElideRight
          }
          Text {
            text: "0123 Aa"
            color: Theme.subtext
            font.family: fontRow.modelData
            font.pixelSize: Theme.font.body
          }
        }

        MouseArea {
          id: rowMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.appearance.fontFamily = fontRow.modelData
        }
      }
    }
  }
}
