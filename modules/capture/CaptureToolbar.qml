// CaptureToolbar.qml
// The capture toolbar at the bottom of the screen (Print, or Super + Shift + R
// on keyboards without Print): what to capture,
// screenshot or recording, a few options, and go.
//   R W S        region, window, screen       Tab     screenshot / record
//   Enter        capture / start recording    Esc     close
// The choices are remembered (services/Capture.qml).
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Capture.open
  readonly property bool recordMode: Capture.mode === "record"

  readonly property var targets: [
    { key: "region", label: "Region", icon: "region", letter: "R" },
    { key: "window", label: "Window", icon: "window", letter: "W" },
    { key: "screen", label: "Screen", icon: "monitor", letter: "S" }
  ]
  readonly property var modes: [
    { key: "shot", label: "Screenshot", icon: "photo" },
    { key: "record", label: "Record", icon: "record" }
  ]
  // The toggles for the chosen mode: [option name, short label, icon, long name]
  readonly property var toggles: recordMode
    ? [["mic", "Mic", "mic", "Record microphone"], ["audio", "Audio", "volume", "Record system audio"],
       ["recordCursor", "Cursor", "cursor", "Show cursor"], ["countdown", "3 s", "clock", "3 second countdown"]]
    : [["delay", "3 s", "clock", "3 second timer"], ["copy", "Copy", "clipboard", "Copy to clipboard"],
       ["cursor", "Cursor", "cursor", "Show cursor"]]

  screen: Capture.screen ?? Panels.focusedScreen()
  visible: shown || bar.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-capture"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  anchors.bottom: true
  margins.bottom: 48
  implicitWidth: Math.max(bar.implicitWidth, hint.implicitWidth) + 24
  implicitHeight: bar.implicitHeight + hint.implicitHeight + 40

  component ChoiceButton: Rectangle {
    id: choice
    property string icon
    property string text
    property bool active: false
    property color activeColor: Theme.accent
    signal clicked()

    implicitHeight: 40
    implicitWidth: choiceRow.implicitWidth + 26
    radius: Theme.pill(height)
    color: active ? Theme.alpha(activeColor, 0.18) : choiceMouse.containsMouse ? Theme.item : "transparent"
    border.width: active ? 1 : 0
    border.color: activeColor

    Accessible.role: Accessible.Button
    Accessible.name: text
    Accessible.checked: active

    Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

    Row {
      id: choiceRow
      anchors.centerIn: parent
      spacing: 7
      Icon { name: choice.icon; size: 15; color: choice.active ? choice.activeColor : Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Label { text: choice.text; font.weight: choice.active ? Font.Bold : Font.Normal; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea {
      id: choiceMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: choice.clicked()
    }
  }

  component Divider: Rectangle {
    implicitWidth: 1
    implicitHeight: 26
    color: Theme.border
  }

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Capture.open = false
  }

  onShownChanged: if (shown) keys.forceActiveFocus()

  Item {
    id: keys
    focus: true
    Keys.onPressed: event => {
      const letter = event.text.toUpperCase();
      const target = window.targets.find(t => t.letter === letter);
      if (target) {
        Capture.target = target.key;
      } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
        Capture.mode = window.recordMode ? "shot" : "record";
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        window.go();
      } else if (event.key === Qt.Key_Escape) {
        Capture.open = false;
      } else {
        return;
      }
      event.accepted = true;
    }
  }

  readonly property bool canGo: !recordMode || (Capture.hasRecorder && !Capture.recording)

  function go(): void {
    if (canGo) Capture.start();
  }

  // What happens next
  Rectangle {
    id: hint
    anchors.horizontalCenter: parent.horizontalCenter
    y: 6
    implicitHeight: 28
    implicitWidth: hintLabel.implicitWidth + 24
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.crust, 0.75)
    opacity: bar.opacity

    Label {
      id: hintLabel
      anchors.centerIn: parent
      font.pixelSize: Theme.font.small
      text: window.recordMode && !Capture.hasRecorder ? "Recording needs gpu-screen-recorder: sudo pacman -S gpu-screen-recorder"
          : window.recordMode && Capture.recording ? "A recording is running; stop it in the bar first"
          : Capture.target === "region" ? "Drag to choose an area · Esc cancels"
          : Capture.target === "window" ? "Click a window · Esc cancels"
          : "The whole screen this toolbar is on"
    }
  }

  GlassPanel {
    id: bar
    anchors.horizontalCenter: parent.horizontalCenter
    y: hint.height + 16 + (window.shown ? 0 : 12)
    implicitWidth: row.implicitWidth + 16
    implicitHeight: 56
    width: implicitWidth
    height: implicitHeight
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.88))
    opacity: window.shown ? 1 : 0

    Accessible.role: Accessible.ToolBar
    Accessible.name: "Capture tools"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.anim.fast } }

    RowLayout {
      id: row
      anchors.verticalCenter: parent.verticalCenter
      x: 8
      spacing: 4

      Repeater {
        model: window.targets
        ChoiceButton {
          required property var modelData
          icon: modelData.icon
          text: modelData.label
          active: Capture.target === modelData.key
          onClicked: Capture.target = modelData.key
        }
      }

      Divider { Layout.leftMargin: 6; Layout.rightMargin: 6 }

      Repeater {
        model: window.modes
        ChoiceButton {
          required property var modelData
          icon: modelData.icon
          text: modelData.label
          active: Capture.mode === modelData.key
          activeColor: modelData.key === "record" ? Theme.error : Theme.accent
          onClicked: Capture.mode = modelData.key
        }
      }

      Divider { Layout.leftMargin: 6; Layout.rightMargin: 6 }

      Repeater {
        model: window.toggles
        ChoiceButton {
          required property var modelData
          icon: modelData[2]
          text: modelData[1]
          active: Capture[modelData[0]] === true
          Accessible.name: modelData[3]
          onClicked: Capture[modelData[0]] = !Capture[modelData[0]]
        }
      }

      Item { implicitWidth: 6 }

      // Go
      Rectangle {
        implicitHeight: 40
        implicitWidth: goRow.implicitWidth + 32
        radius: Theme.pill(height)
        color: !window.canGo ? Theme.overlay : window.recordMode ? Theme.error : Theme.accent
        opacity: window.canGo ? 1 : 0.6

        Accessible.role: Accessible.Button
        Accessible.name: goLabel.text

        Row {
          id: goRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: window.recordMode ? "record" : "photo"; size: 15; color: Theme.onAccent; anchors.verticalCenter: parent.verticalCenter }
          Label { id: goLabel; text: window.recordMode ? "Start recording" : "Capture"; font.weight: Font.Bold; color: Theme.onAccent; anchors.verticalCenter: parent.verticalCenter }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: window.canGo ? Qt.PointingHandCursor : Qt.ArrowCursor
          onClicked: window.go()
        }
      }

      IconButton {
        Layout.leftMargin: 4
        icon: "close"
        size: 36
        variant: "plain"
        accessibleName: "Close"
        onClicked: Capture.open = false
      }
    }
  }
}
