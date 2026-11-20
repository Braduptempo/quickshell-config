//shell.qml

import Quickshell
import Quickshell.Io
import "./modules/bar"
import "./widgets/notifications"
import "./dev"

Scope {

  Bar {}

  // Het popup venster. Luistert zelf naar de Notifications-singleton.
  ToastOverlay {}

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
