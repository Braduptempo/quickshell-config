//shell.qml

import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/quicksettings"
import "./services"
import "./modules/notifications"
import "./modules/clockpanel"
import "./modules/osd"
import "./modules/launcher"
import "./modules/clipboard"
import "./modules/lock"
import "./modules/power"
import "./modules/media"
import "./dev"

Scope {

  Bar {}

  // Notification pop-ups, and the clock panel (calendar + notifications)
  Toasts {}

  ClockPanel {}

  // Volume, microphone, brightness, keyboard layout and Caps Lock pop-up
  OsdWindow {}

  // Super + Space
  LauncherWindow {}

  IpcHandler {
    target: "launcher"
    function toggle(): void {
      Launcher.toggle(Panels.focusedScreen());
    }
    // `qs ipc call launcher search "2*21"` opens with that text already typed
    function search(text: string): void {
      Launcher.openWith(Panels.focusedScreen(), text);
    }
  }

  // Super + L, and after Config.lock.idleMinutes without input
  LockScreen {}

  // `qs ipc call lock lock`; `preview` shows it without locking (development)
  IpcHandler {
    target: "lock"
    function lock(): void {
      Lock.lock();
    }
    function suspend(): void {
      Lock.suspend();
    }
    function preview(): void {
      Lock.showPreview();
    }
    // Only with QS_LOCK_TEST=1, for testing the real lock
    function unlock(): void {
      if (Lock.testMode) Lock.locked = false;
    }
    // Preview only: type text into the field, then try it
    function previewType(text: string): void {
      if (!Lock.preview) return;
      Lock.wake();
      Lock.typed = text;
    }
    function previewSubmit(): void {
      if (Lock.preview) Lock.submit(Lock.typed);
    }
  }

  // Below the media pill
  MediaMenu {}

  // `qs ipc call media toggle`
  IpcHandler {
    target: "media"
    function toggle(): void {
      Media.toggle(Panels.focusedScreen(), 180);
    }
  }

  // Super + Esc
  PowerMenu {}

  // `qs ipc call power toggle`; `open R` opens with Restart chosen
  IpcHandler {
    target: "power"
    function toggle(): void {
      Power.toggle(Panels.focusedScreen());
    }
    function open(key: string): void {
      Power.openWith(Panels.focusedScreen(), key);
    }
    function cancel(): void {
      Power.cancelSchedule();
    }
  }

  // Super + Shift + V
  ClipboardWindow {}

  // `qs ipc call clipboard toggle`
  IpcHandler {
    target: "clipboard"
    function toggle(): void {
      Clipboard.toggle(Panels.focusedScreen());
    }
  }

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
