// Notifications.qml
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One notification server for the whole shell.
// It used to live inside NotificationWidget, which the bar creates once per
// monitor. With two monitors that meant two servers fighting over the same
// D-Bus name, which caused the duplicate toasts.
Singleton {
  id: root

  // History shown in the dropdown, newest first
  property ListModel model: ListModel {}

  // Emitted for every incoming notification, used by ToastOverlay
  signal toast(var notification)

  // Shown as a red dot on the clock until the history is opened
  property int unread: 0

  function markRead(): void {
    unread = 0;
  }

  NotificationServer {
    id: server
    onNotification: function(notification) {
      root.unread++;
      root.toast(notification);
      root.model.insert(0, {
        "appName": notification.appName || "Systeem",
        "summary": notification.summary || "",
        "body": notification.body || ""
      });
    }
  }
}
