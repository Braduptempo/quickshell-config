// NotificationWidget.qml
import QtQuick
import Quickshell.Services.Notifications

Item {
  id: root
  implicitWidth: 30
  implicitHeight: 30

  property var mainWindow: null
  signal newToast(var notification)

  ListModel {
    id: notifModel
  }

  NotificationServer {
    id: server
    onNotification: function(notification) {
      root.newToast(notification);
      notifModel.insert(0, {
          "appName": notification.appName || "Systeem",
          "summary": notification.summary || "",
          "body": notification.body || ""
      });
    }
  }

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: 15
    border.color: "blue"
    border.width: 2

    Text {
      anchors.centerIn: parent
      text: ""
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

  // Roep hier het nieuwe externe bestand aan!
  NotificationDropdown {
    id: dropdown
    visible: false
    listModel: notifModel // Geef het model door
    anchor.window: root.mainWindow
    anchor.edges: root.mainWindow ? root.mainWindow.Edges.Bottom : 0
  }
}
