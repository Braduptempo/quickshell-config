import QtQuick
import QtQuick.Layouts

Rectangle {
  id: root

  // We definiëren de teksten nu direct, geen complexe objecten meer!
  property string appName: "Systeem"
  property string summary: ""
  property string body: ""

  // Een signaal zodat we het kruisje veilig kunnen gebruiken
  signal closeClicked()

  implicitHeight: layout.implicitHeight + 16
  color: "#181825"
  radius: 6
  border.color: "#45475a"
  border.width: 1

  ColumnLayout {
    id: layout
    anchors.fill: parent
    anchors.margins: 8
    spacing: 4

    RowLayout {
      Layout.fillWidth: true

      Text {
        text: root.appName
        color: "#89b4fa"
        font.pixelSize: 11
        Layout.fillWidth: true
      }

      Text {
        text: "✕"
        color: "#6c7086"
        font.pixelSize: 12

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor

          // Roep het signaal aan als je op het kruisje klikt
          onClicked: root.closeClicked()
        }
      }
    }

    Text {
      text: root.summary
      color: "#cdd6f4"
      font.bold: true
      font.pixelSize: 13
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }

    Text {
      text: root.body
      color: "#a6adc8"
      font.pixelSize: 12
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }
  }
}
