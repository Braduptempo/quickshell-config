// LockScreen.qml
// The real lock (Wayland session lock: nothing else can show or take input
// until it unlocks) and a preview window for development.
// The state lives in services/Lock.qml.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../services"

Scope {
  WlSessionLock {
    locked: Lock.locked

    WlSessionLockSurface {
      id: surface
      color: Theme.crust

      LockContent {
        anchors.fill: parent
        screen: surface.screen
      }
    }
  }

  // `qs ipc call lock preview`: the same screen in an ordinary window,
  // without locking and without PAM
  LazyLoader {
    active: Lock.preview

    PanelWindow {
      id: previewWindow
      screen: Panels.focusedScreen()
      color: Theme.crust
      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "quickshell-lock-preview"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

      LockContent {
        anchors.fill: parent
        screen: previewWindow.screen
      }
    }
  }
}
