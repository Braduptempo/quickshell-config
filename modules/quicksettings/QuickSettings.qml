// QuickSettings.qml
// The quick settings panel under the bar, on the monitor it was opened from.
// Opens with the configured panel animation; click outside or Esc closes it.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/network"

PanelWindow {
  id: window

  readonly property bool shown: Panels.quickSettingsOpen
  readonly property string style: Config.animations.panelStyle

  screen: Panels.screen
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-quicksettings"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  // Opens from the bar: at the top, or at the bottom when the bar is there
  readonly property bool fromBottom: Config.bar.position === "bottom"

  anchors {
    top: !window.fromBottom
    bottom: window.fromBottom
    right: true
  }
  margins {
    top: 6
    bottom: 6
    right: 8
  }
  implicitWidth: 390 + 24
  // The window never changes size: resizing a Wayland window makes the
  // content shake (every frame) or go blank (a frame or two after a jump).
  // It's as tall as the screen allows; only the card takes clicks (mask),
  // so clicks beside it reach the windows below and close the panel.
  implicitHeight: (screen ? screen.height : 1080) - Theme.size.bar - 24
  mask: Region { item: card }

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.closeQuickSettings()
  }

  NetworkManager {
    id: networkManager
  }

  GlassPanel {
    id: card
    color: Theme.panelSolid

    x: 12
    width: 390
    implicitHeight: pages.implicitHeight + 28
    height: implicitHeight
    transformOrigin: window.fromBottom ? Item.BottomRight : Item.TopRight
    focus: true

    // Open: slide / fade / scale from Config; close a bit faster
    opacity: window.shown ? 1 : 0
    // With the bar at the bottom the card hugs the bottom of the (held) window
    y: (window.fromBottom ? window.height - 24 - height : 0) + 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.92

    Behavior on opacity {
      NumberAnimation {
        duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut
        easing.type: Easing.BezierSpline
        easing.bezierCurve: window.shown ? Theme.anim.emphasized : Theme.anim.accelerate
      }
    }
    Behavior on y {
      NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
    }
    Behavior on scale {
      NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
    }
    // Pages have different heights; the card animates, the window holds still
    Behavior on height {
      NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
    }

    Keys.onEscapePressed: {
      if (Panels.quickSettingsPage !== "main") Panels.quickSettingsPage = "main";
      else Panels.closeQuickSettings();
    }

    Item {
      id: pages
      x: 14
      y: 14
      width: parent.width - 28
      implicitHeight: loader.item ? loader.item.implicitHeight : 0
      clip: true

      Loader {
        id: loader
        width: parent.width
        // Only the visible page exists, so detail pages stop scanning when closed
        sourceComponent: {
          switch (Panels.quickSettingsPage) {
          case "network":
          case "wifi": return networkPage;
          case "bluetooth": return bluetoothPage;
          case "audio": return audioPage;
          case "system": return systemPage;
          default: return mainPage;
          }
        }
        // Fades in from 35 %, so the panel never looks empty for a frame
        onLoaded: {
          item.opacity = 0.35;
          fadeIn.restart();
        }
      }

      NumberAnimation {
        id: fadeIn
        target: loader.item
        property: "opacity"
        to: 1
        duration: Theme.anim.panelIn
        easing.type: Easing.OutCubic
      }
    }
  }

  Component { id: mainPage; MainPage { network: networkManager } }
  Component { id: networkPage; NetworkPage { network: networkManager } }
  Component { id: bluetoothPage; BluetoothPage {} }
  Component { id: audioPage; AudioPage {} }
  Component { id: systemPage; SystemPage {} }
}
