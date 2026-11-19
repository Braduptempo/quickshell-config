// NotificationWidget.qml
import QtQuick
import Quickshell

Item {
  id: root
  implicitWidth: 30
  implicitHeight: 30

  property var mainWindow: null

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: 15
    border.color: "blue"
    border.width: 2

    Text {
      anchors.centerIn: parent
      text: ""
      color: "white"
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        if (!dropdown.anchor.window && root.mainWindow) {
          dropdown.anchor.window = root.mainWindow;
        }

        let pos = root.mapToItem(null, 0, 0);
        dropdown.anchor.rect = Qt.rect(pos.x, pos.y, root.width, root.height);
        dropdown.anchor.margins.top = 35;
        dropdown.visible = !dropdown.visible;
      }
    }
  }

  // The server and history now live in the Notifications singleton,
  // so every monitor's bar shows the same list.
  NotificationDropdown {
    id: dropdown
    visible: false
    listModel: Notifications.model
    anchor.window: root.mainWindow
    // `Edges` is a global enum; `mainWindow.Edges` was undefined
    anchor.edges: Edges.Bottom
  }
}
