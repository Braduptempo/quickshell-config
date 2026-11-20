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

  anchors {
    top: true
    right: true
  }
  margins {
    top: 6
    right: 8
  }
  implicitWidth: 390 + 24
  implicitHeight: card.implicitHeight + 24

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

    x: 12
    width: 390
    implicitHeight: pages.implicitHeight + 28
    height: implicitHeight
    transformOrigin: Item.TopRight
    focus: true

    // Open: slide / fade / scale from Config; close a bit faster
    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : -14)
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
    Behavior on implicitHeight {
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
          case "wifi": return wifiPage;
          case "bluetooth": return bluetoothPage;
          case "audio": return audioPage;
          default: return mainPage;
          }
        }
        onLoaded: {
          item.opacity = 0;
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
  Component { id: wifiPage; WifiPage { network: networkManager } }
  Component { id: bluetoothPage; BluetoothPage {} }
  Component { id: audioPage; AudioPage {} }
}
