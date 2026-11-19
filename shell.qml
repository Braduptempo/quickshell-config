//shell.qml

import Quickshell
import "."
import "./widgets/notifications"

Scope {

  Bar {}

  // Het popup venster. Luistert zelf naar de Notifications-singleton.
  ToastOverlay {}
}
