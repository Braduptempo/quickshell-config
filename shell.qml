//shell.qml

import Quickshell
import "."
import "./widgets/notifications"

Scope {

  Bar{
    // Vang het op en stuur naar de overlay
    onNewToast: function(notification) {
      toasts.showToast(notification)
    }
  }

  // Het popup venster
  ToastOverlay {
    id: toasts
  }
}
