// ClockPanel.qml
// Opens from the clock, with four tabs: Overview (today's events, the
// weather and the latest notifications), Calendar (month, the chosen day,
// new events), Weather (hours and 7 days) and Notifications.
// Click outside or Esc closes it.
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

  readonly property bool shown: Panels.clockPanelOpen
  readonly property string style: Config.animations.panelStyle

  screen: Panels.clockScreen
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-clockpanel"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  // Only anchored to the top (or bottom): the compositor centres it under the clock
  // Opens from the bar: at the top, or at the bottom when the bar is there
  readonly property bool fromBottom: Config.bar.position === "bottom"

  anchors.top: !window.fromBottom
  anchors.bottom: window.fromBottom
  margins.top: 6
  margins.bottom: 6
  implicitWidth: 720 + 24
  // The window never changes size: resizing a Wayland window makes the
  // content shake (every frame) or go blank (a frame or two after a jump).
  // It's as tall as the screen allows; only the card takes clicks (mask),
  // so clicks beside it reach the windows below and close the panel.
  implicitHeight: (screen ? screen.height : 1080) - Theme.size.bar - 24
  mask: Region { item: card }

  readonly property var tabs: ["overview", "calendar", "weather", "notifications"]

  // A new tab fades in instead of popping
  property real tabFade: 1
  NumberAnimation on tabFade { id: tabFadeIn; running: false; from: 0.35; to: 1; duration: Theme.anim.panelIn; easing.type: Easing.OutCubic }
  Connections {
    target: Panels
    function onClockTabChanged() { tabFadeIn.restart(); }
  }

  onShownChanged: if (shown && Panels.clockTab === "notifications") Notifications.markRead()

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.closeClockPanel()
  }

  GlassPanel {
    id: card
    color: Theme.panelSolid

    x: 12
    width: 720
    implicitHeight: content.implicitHeight + 32
    height: implicitHeight
    // Tabs have different heights: grow or shrink to the next one smoothly
    // (the card's height animates, the window around it holds still)
    Behavior on height { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard } }
    clip: true
    focus: true
    transformOrigin: window.fromBottom ? Item.Bottom : Item.Top

    opacity: window.shown ? 1 : 0
    // With the bar at the bottom the card hugs the bottom of the (held) window
    y: (window.fromBottom ? window.height - 24 - height : 0) + 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.94

    Behavior on opacity {
      NumberAnimation {
        duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut
        easing.type: Easing.BezierSpline
        easing.bezierCurve: window.shown ? Theme.anim.emphasized : Theme.anim.accelerate
      }
    }
    Behavior on y { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    Keys.onEscapePressed: Panels.closeClockPanel()

    ColumnLayout {
      id: content
      x: 16
      y: 16
      width: parent.width - 32
      spacing: 14

      // --- Tabs ---------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Segmented {
          model: ["Overview", "Calendar", "Weather", "Notifications" + (Notifications.count > 0 ? " · " + Notifications.count : "")]
          currentIndex: Math.max(0, window.tabs.indexOf(Panels.clockTab))
          accessibleName: "Clock panel"
          onActivated: index => {
            Panels.clockTab = window.tabs[index];
            if (Panels.clockTab === "notifications") Notifications.markRead();
          }
        }

        Item { Layout.fillWidth: true; visible: Panels.clockTab === "overview" }

        // The date (the overview's Today card has it already); shortens
        // rather than pushing out of the panel
        Label {
          visible: Panels.clockTab !== "overview"
          Layout.fillWidth: true
          Layout.minimumWidth: 0
          horizontalAlignment: Text.AlignRight
          text: Qt.formatDate(Time.date, "dddd d MMMM")
          kind: "muted"
          elide: Text.ElideLeft
        }
      }

      OverviewTab {
        opacity: window.tabFade
        visible: Panels.clockTab === "overview"
        Layout.fillWidth: true
      }

      CalendarTab {
        opacity: window.tabFade
        visible: Panels.clockTab === "calendar"
        Layout.fillWidth: true
      }

      WeatherTab {
        opacity: window.tabFade
        visible: Panels.clockTab === "weather"
        Layout.fillWidth: true
      }

      NotificationsTab {
        opacity: window.tabFade
        visible: Panels.clockTab === "notifications"
        Layout.fillWidth: true
      }
    }
  }
}
