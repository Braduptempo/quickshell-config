// Notifications.qml
// The notification server for the whole shell (one, not one per monitor).
// Notifications stay "tracked" until you dismiss them or the app closes
// them, so their actions and inline replies keep working from the history.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../config"

Singleton {
  id: root

  // Do not disturb: everything still goes into the history, but only
  // critical notifications pop up
  property bool dnd: false
  // Do not disturb by hand, or the daily quiet hours from Settings
  readonly property bool quiet: dnd || inQuietHours
  readonly property bool inQuietHours: {
    const from = Config.notifications.quietFrom, to = Config.notifications.quietTo;
    if (from === "" || to === "") return false;
    const toMinutes = t => {
      const m = t.match(/^(\d{1,2}):(\d{2})$/);
      return m ? parseInt(m[1]) * 60 + parseInt(m[2]) : -1;
    };
    const a = toMinutes(from), b = toMinutes(to);
    if (a < 0 || b < 0 || a === b) return false;
    const d = Time.date;
    const now = d.getHours() * 60 + d.getMinutes();
    // "22:00" to "07:00" runs over midnight
    return a < b ? now >= a && now < b : now >= a || now < b;
  }

  function isMuted(app: string): bool {
    return Config.notifications.mutedApps.indexOf(app) >= 0;
  }

  function setMuted(app: string, muted: bool): void {
    const list = Config.notifications.mutedApps.filter(a => a !== app);
    Config.notifications.mutedApps = muted ? list.concat([app]) : list;
  }

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

      // Remember the app, for the per-app list in Settings
      const app = n.appName || "Unknown app";
      if (Config.notifications.knownApps.indexOf(app) < 0) {
        Config.notifications.knownApps = Config.notifications.knownApps.concat([app]).sort((a, b) => a.localeCompare(b));
      }

      // Critical always gets through; the rest only with pop-ups on, not
      // muted, and outside do not disturb
      const critical = n.urgency === NotificationUrgency.Critical;
      const show = critical || (Config.notifications.popups && !root.isMuted(app) && !root.quiet);
      if (show && Config.notifications.sound) {
        Quickshell.execDetached(["sh", "-c", "canberra-gtk-play -i \"$1\" 2>/dev/null || pw-play /usr/share/sounds/freedesktop/stereo/message.oga 2>/dev/null",
                                 "sh", critical ? "dialog-warning" : "message-new-instant"]);
      }
      // A replaced notification (same id) moves back to the top
      if (show) root.popups = [n].concat(root.popups.filter(p => p !== n));

      n.closed.connect(() => {
        root.popups = root.popups.filter(p => p !== n);
      });
    }
  }
}
