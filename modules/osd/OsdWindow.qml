// OsdWindow.qml
// The pop-up near the bottom of the focused monitor for volume, microphone,
// brightness, keyboard layout and Caps Lock. It never takes clicks or focus.
// It watches the system itself, so media keys, `wpctl` or another app
// changing the volume all show it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/sound"

PanelWindow {
  id: window

  // Changes during start-up are the initial values, not something to show
  property bool ready: false
  // While quick settings is open its own slider already shows the value
  readonly property bool quiet: !ready || Panels.quickSettingsOpen

  screen: Panels.focusedScreen()
  visible: Osd.shown || pill.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-osd"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Only the bottom edge: the compositor centres it horizontally
  anchors.bottom: true
  margins.bottom: 90
  implicitWidth: 320 + 24
  implicitHeight: 56 + 24

  // Clicks go straight through to whatever is underneath
  mask: Region {}

  Timer {
    interval: 2000
    running: true
    onTriggered: window.ready = true
  }

  // --- What to watch -----------------------------------------------------------
  function showVolume(): void {
    if (quiet) return;
    Osd.show({
      icon: Sound.isMuted ? "volume-off" : Sound.volume > 60 ? "volume-high" : "volume",
      title: Sound.isMuted ? "Muted" : "Volume",
      value: Sound.isMuted ? 0 : Sound.volume / 100,
      valueText: Sound.isMuted ? "" : Sound.volume + "%",
      tone: Sound.isMuted ? "error" : "accent"
    });
  }

  Connections {
    target: Sound
    function onVolumeChanged() { window.showVolume(); }
    function onIsMutedChanged() { window.showVolume(); }
    function onIsMicMutedChanged() {
      if (window.quiet) return;
      Osd.show({
        icon: Sound.isMicMuted ? "mic-off" : "mic",
        title: Sound.isMicMuted ? "Microphone muted" : "Microphone on",
        subtitle: Sound.isMicMuted ? "Nobody can hear you" : "",
        tone: Sound.isMicMuted ? "error" : "accent"
      });
    }
  }

  Connections {
    target: Session
    function onBrightnessChanged() {
      if (window.quiet || !Session.brightnessAvailable) return;
      Osd.show({
        icon: "sun",
        title: "Brightness",
        value: Session.brightness,
        valueText: Math.round(Session.brightness * 100) + "%",
        tone: "warn"
      });
    }
  }

  // Keyboard layout switched (e.g. Alt + Shift)
  Connections {
    target: Hyprland
    function onRawEvent(event: HyprlandEvent): void {
      if (event.name !== "activelayout" || window.quiet) return;
      const name = event.data.split(",").slice(1).join(",");
      Osd.show({
        badge: name.slice(0, 2).toUpperCase(),
        title: name,
        subtitle: "Keyboard layout"
      });
    }
  }

  // Caps Lock has no event of its own: a non-consuming Hyprland bind calls
  // `qs ipc call osd caps`, and this reads the state from the main keyboard
  function checkCaps(): void {
    capsProc.running = true;
  }

  Process {
    id: capsProc
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        let keyboards = [];
        try {
          keyboards = JSON.parse(text).keyboards ?? [];
        } catch (e) {
          return;
        }
        const main = keyboards.find(k => k.main) ?? keyboards[0];
        if (!main) return;
        Osd.show({
          icon: "chevron-up",
          title: main.capsLock ? "Caps Lock on" : "Caps Lock off",
          tone: main.capsLock ? "warn" : "accent"
        });
      }
    }
  }

  // The key is handled after the bind fires, so read the state a moment later
  Timer {
    id: capsDelay
    interval: 120
    onTriggered: window.checkCaps()
  }

  IpcHandler {
    target: "osd"
    function caps(): void {
      capsDelay.restart();
    }
    function brightness(): void {
      Session.refreshBrightness();
    }
  }

  // --- The pill ------------------------------------------------------------------
  Rectangle {
    id: pill

    readonly property color toneColor: Osd.tone === "error" ? Theme.error : Osd.tone === "warn" ? Theme.warn : Theme.accent

    x: 12
    width: 320
    height: 56
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.88))
    border.width: 1
    border.color: Theme.border

    opacity: Osd.shown ? 1 : 0
    y: 12 + (Osd.shown ? 0 : 12)
    scale: Osd.shown ? 1 : 0.96

    Behavior on opacity { NumberAnimation { duration: Osd.shown ? Theme.anim.osd : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.osd; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.osd } }

    Accessible.role: Accessible.StatusBar
    Accessible.name: Osd.title + (Osd.valueText !== "" ? " " + Osd.valueText : "") + (Osd.subtitle !== "" ? ", " + Osd.subtitle : "")

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 8
      anchors.rightMargin: 20
      spacing: 12

      Rectangle {
        implicitWidth: 40
        implicitHeight: 40
        radius: 20
        color: pill.toneColor

        Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

        Icon {
          visible: Osd.badge === ""
          anchors.centerIn: parent
          name: Osd.icon
          size: 18
          strokeWidth: 2.2
          color: Theme.onAccent
        }

        Label {
          visible: Osd.badge !== ""
          anchors.centerIn: parent
          text: Osd.badge
          kind: "title"
          font.pixelSize: Theme.font.body
          color: Theme.onAccent
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 5

        Label {
          text: Osd.title
          font.weight: Font.Bold
          Layout.fillWidth: true
        }

        // Value bar for volume and brightness
        Rectangle {
          visible: Osd.value >= 0
          Layout.fillWidth: true
          implicitHeight: 5
          radius: 3
          color: Theme.alpha(Theme.text, 0.15)

          Rectangle {
            width: parent.width * Math.max(0, Math.min(1, Osd.value))
            height: parent.height
            radius: 3
            color: pill.toneColor

            Behavior on width {
              NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
            }
          }
        }

        Label {
          visible: Osd.value < 0 && Osd.subtitle !== ""
          text: Osd.subtitle
          kind: "muted"
          font.pixelSize: Theme.font.label
          Layout.fillWidth: true
        }
      }

      Label {
        visible: Osd.valueText !== ""
        text: Osd.valueText
        font.weight: Font.Bold
      }
    }
  }
}
