//shell.qml

import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/quicksettings"
import "./services"
import "./modules/notifications"
import "./modules/clockpanel"
import "./dev"

Scope {

  Bar {}

  // Notification pop-ups, and the clock panel (calendar + notifications)
  Toasts {}

  ClockPanel {}

  // `qs ipc call notifications toggle` (Super + N), `dnd`, `clear`
  IpcHandler {
    target: "notifications"
    function toggle(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "notifications");
    }
    function calendar(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "calendar");
    }
    function dnd(): void {
      Notifications.dnd = !Notifications.dnd;
    }
    function clear(): void {
      Notifications.clearAll();
    }
  }

  QuickSettings {}

  // `qs ipc call quicksettings toggle` (Super + A), or open a page directly:
  // `qs ipc call quicksettings open wifi`
  IpcHandler {
    target: "quicksettings"
    function toggle(): void {
      Panels.toggleQuickSettings(Panels.focusedScreen());
    }
    function open(page: string): void {
      Panels.openQuickSettings(Panels.focusedScreen(), page);
    }
  }

  // Component gallery for development. Open with QS_GALLERY=1 or
  // `qs ipc call gallery toggle`.
  LazyLoader {
    id: galleryLoader
    active: Quickshell.env("QS_GALLERY") === "1"
    Gallery {}
  }

  IpcHandler {
    target: "gallery"
    function toggle(): void {
      galleryLoader.active = !galleryLoader.active;
    }
  }
}
