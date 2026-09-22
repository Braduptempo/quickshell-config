// ToastOverlay.qml
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: root

  anchors { top: true; right: true }
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay

  implicitWidth: 350
  implicitHeight: listView.contentHeight

  ListModel {
    id: toastModel
  }

  function showToast(notification) {
    let incomingApp = notification.appName || "Systeem";
    let incomingSummary = notification.summary || "";
    let incomingBody = notification.body || "";

    for (let i = 0; i < toastModel.count; i++) {
      let existingToast = toastModel.get(i);
      if (existingToast.msgAppName === incomingApp &&
          existingToast.msgSummary === incomingSummary &&
          existingToast.msgBody === incomingBody) {
        return;
      }
    }

    toastModel.append({
        "msgAppName": incomingApp,
        "msgSummary": incomingSummary,
        "msgBody": incomingBody
    })
  }

  ListView {
    id: listView
    width: parent.width
    implicitHeight: contentHeight
    spacing: 10
    model: toastModel
    interactive: false

    delegate: ToastCard {
      // 1. Zeg alleen hoe breed hij moet zijn
      width: ListView.view.width
      
      // 2. GEEN model.appName OF index MEER HIER! QML injecteert ze nu zelf.

      // 3. Vang de klik (of timer) op
      onTimeoutOrClose: function(removeIndex) {
        if (removeIndex !== -1 && removeIndex < toastModel.count) {
          toastModel.remove(removeIndex);
        }
      }
    }
  }
}
