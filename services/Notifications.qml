// Notifications.qml
// The notification server for the whole shell (one, not one per monitor).
// Notifications stay "tracked" until you dismiss them or the app closes
// them, so their actions and inline replies keep working from the history.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  // Do not disturb: everything still goes into the history, but only
  // critical notifications pop up
  property bool dnd: false

  // Red dot on the clock until the history is opened
  property int unread: 0

  // History, newest first
  readonly property var history: server.trackedNotifications.values.slice().reverse()
  readonly property int count: server.trackedNotifications.values.length

  // Notifications currently shown as pop-ups, newest first
  property var popups: []

  // When each notification arrived (id -> ms), for "5 min ago"
  property var receivedAt: ({})

  // Ticks every 30 s so relative times update
  property double now: Date.now()

  function markRead(): void {
    unread = 0;
  }

  function hidePopup(n: Notification): void {
    popups = popups.filter(p => p !== n);
    // Transient notifications don't belong in the history
    if (n && n.transient) n.expire();
  }

  function dismiss(n: Notification): void {
    hidePopup(n);
    n.dismiss();
  }

  function clearAll(): void {
    for (const n of server.trackedNotifications.values.slice()) n.dismiss();
    popups = [];
    unread = 0;
  }

  // Runs the "default" action (clicking the notification itself), if any
  function activate(n: Notification): bool {
    for (const a of n.actions) {
      if (a.identifier === "default") {
        a.invoke();
        return true;
      }
    }
    return false;
  }

  function timeOf(n: Notification): string {
    const at = receivedAt[n.id] ?? now;
    const minutes = Math.floor((now - at) / 60000);
    if (minutes < 1) return "now";
    if (minutes < 60) return minutes + " min";
    return Qt.formatTime(new Date(at), "HH:mm");
  }

  Timer {
    interval: 30000
    running: root.count > 0
    repeat: true
    onTriggered: root.now = Date.now()
  }

  NotificationServer {
    id: server

    keepOnReload: false
    actionsSupported: true
    imageSupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    persistenceSupported: true
    inlineReplySupported: true

    onNotification: n => {
      n.tracked = true;
      root.now = Date.now();

      const times = Object.assign({}, root.receivedAt);
      times[n.id] = root.now;
      root.receivedAt = times;
      root.unread++;

      const show = !root.dnd || n.urgency === NotificationUrgency.Critical;
      // A replaced notification (same id) moves back to the top
      if (show) root.popups = [n].concat(root.popups.filter(p => p !== n));

      n.closed.connect(() => {
        root.popups = root.popups.filter(p => p !== n);
      });
    }
  }
}
