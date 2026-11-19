//NotificationDropdown.qml
import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
  id: root

  // Deze verwachten we vanuit de Widget
  property ListModel listModel

  implicitWidth: 350
  implicitHeight: 400
  grabFocus: true

  Rectangle {
    anchors.fill: parent
    color: "#1e1e2e"
    border.color: "#313244"
    border.width: 2
    radius: 8

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 10
      spacing: 10

      RowLayout {
        Layout.fillWidth: true

        Text {
          text: "Notificaties"
          color: "white"
          font.bold: true
          Layout.fillWidth: true
        }

        Rectangle {
          implicitWidth: 60
          implicitHeight: 25
          color: "royalblue"
          radius: 4

          Text {
            anchors.centerIn: parent
            text: "Wissen"
            color: "white"
            font.pixelSize: 12
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.listModel.clear()
          }
        }
      }

      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ListView {
          id: listView
          anchors.fill: parent
          spacing: 8
          clip: true

          // Koppel de lijst hier
          model: root.listModel

          delegate: NotificationCard {
            width: listView.width
            appName: model.appName
            summary: model.summary
            body: model.body

            onCloseClicked: {
              root.listModel.remove(index);
            }
          }
        }

        Text {
          anchors.centerIn: parent
          visible: root.listModel.count === 0
          text: "Geen nieuwe notificaties"
          color: "gray"
        }
      }
    }
  }
}
