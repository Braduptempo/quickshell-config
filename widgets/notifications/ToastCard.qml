// ToastCard.model
import QtQuick
import QtQuick.Layouts

Item {
  id: root

  // Omdat deze EXACT zo heten als in het ListModel, vult QML ze magisch in!
  required property string msgAppName
  required property string msgSummary
  required property string msgBody
  required property int index

  signal timeoutOrClose(int removeIndex)

  height: card.implicitHeight

  Rectangle {
    id: card
    width: parent.width
    implicitHeight: layout.implicitHeight + 16
    color: "#1e1e2e"
    radius: 8
    border.color: "#313244"
    border.width: 2

    ColumnLayout {
      id: layout
      anchors.fill: parent
      anchors.margins: 10

      Text {
        text: root.msgAppName
        color: "#89b4fa"
        font.pixelSize: 11
      }
      Text {
        text: root.msgSummary
        color: "white"
        font.bold: true
        font.pixelSize: 13
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
      Text {
        text: root.msgBody
        color: "lightgray"
        font.pixelSize: 12
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.timeoutOrClose(root.index)
    }

    Timer {
      running: true
      interval: 5000
      onTriggered: root.timeoutOrClose(root.index)
    }
  }
}
