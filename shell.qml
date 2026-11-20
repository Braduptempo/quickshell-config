//shell.qml

import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./modules/quicksettings"
import "./services"
import "./widgets/notifications"
import "./dev"

Scope {

  Bar {}

  // Het popup venster. Luistert zelf naar de Notifications-singleton.
  ToastOverlay {}

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
