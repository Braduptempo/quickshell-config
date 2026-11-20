// Toasts.qml
// Notification pop-ups, top right by default (Settings → Notifications:
// top right, top centre or bottom right). More than one stacks into a pile
// (unless stacking is off); hover the pile to fan it out. Critical
// notifications sit on top and stay until you dismiss them. Hovering pauses
// the timers.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property var critical: Notifications.popups.filter(n => n.urgency === NotificationUrgency.Critical)
  readonly property var normal: Notifications.popups.filter(n => n.urgency !== NotificationUrgency.Critical)
  readonly property bool expanded: hover.hovered || normal.length <= 1 || !Config.notifications.stack
  readonly property string position: Config.notifications.position

  screen: Panels.focusedScreen()
  visible: Notifications.popups.length > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-toasts"
  WlrLayershell.layer: WlrLayer.Overlay
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: window.position !== "bottom-right"
    bottom: window.position === "bottom-right"
    // Top centre: no side anchor, the compositor centres it
    right: window.position !== "top-center"
  }
  margins {
    top: 6
    bottom: 6
    right: 8
  }
  implicitWidth: 380 + 24
  implicitHeight: column.implicitHeight + 24

  Column {
    id: column
    x: 12
    y: 12
    width: 380
    spacing: 8

    HoverHandler {
      id: hover
    }

    // Critical: always fully shown, no timeout
    Repeater {
      model: window.critical

      NotificationCard {
        required property Notification modelData
        notification: modelData
        width: column.width
        fill: Math.max(Theme.glass, 0.88)
        onActivated: {
          if (!Notifications.activate(modelData)) Panels.openClockPanel(null, "notifications");
          Notifications.dismiss(modelData);
        }
      }
    }

    // Normal: a pile that fans out on hover
    Repeater {
      model: window.normal

      Item {
        id: slot

        required property Notification modelData
        required property int index

        readonly property bool shownInPile: index < 3
        // Collapsed: the first card in full, the next two peek out 10 px below
        // (the slot is only 2 px high, the card hangs above it behind the previous one)
        height: window.expanded || index === 0 ? card.implicitHeight : 10 - column.spacing
        width: column.width
        z: -index
        visible: window.expanded || shownInPile

        Behavior on height {
          NumberAnimation { duration: Theme.anim.stack; easing.type: Easing.BezierSpline; easing.bezierCurve: window.expanded ? [0.34, 1.4, 0.64, 1, 1, 1] : Theme.anim.standard }
        }

        NotificationCard {
          id: card
          notification: slot.modelData
          width: parent.width
          maxLines: 3
          fill: Math.max(Theme.glass, 0.88)
          contentVisible: window.expanded || slot.index === 0
          y: window.expanded || slot.index === 0 ? 0 : slot.height - height
          scale: window.expanded || slot.index === 0 ? 1 : 1 - slot.index * 0.04
          opacity: window.expanded || slot.index === 0 ? 1 : 0.85

          Behavior on y { NumberAnimation { duration: Theme.anim.stack; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard } }
          Behavior on scale { NumberAnimation { duration: Theme.anim.stack } }

          onActivated: {
            if (!Notifications.activate(slot.modelData)) Panels.openClockPanel(null, "notifications");
            Notifications.hidePopup(slot.modelData);
          }

          // Slide in from the right when it appears
          Component.onCompleted: {
            x = 40;
            opacity = 0;
            enter.start();
          }

          ParallelAnimation {
            id: enter
            NumberAnimation { target: card; property: "x"; to: 0; duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized }
            NumberAnimation { target: card; property: "opacity"; to: 1; duration: Theme.anim.panelIn }
          }
        }

        // Settings → Notifications (5 s by default), or the app's own timeout;
        // paused while hovered
        Timer {
          interval: slot.modelData.expireTimeout > 0 ? slot.modelData.expireTimeout * 1000 : Config.notifications.duration * 1000
          running: !hover.hovered
          onTriggered: Notifications.hidePopup(slot.modelData)
        }

        // "+3 more" on the pile
        Rectangle {
          visible: !window.expanded && slot.index === 0 && window.normal.length > 1
          anchors.right: parent.right
          anchors.rightMargin: 14
          y: card.height - height - 12
          z: 2
          implicitWidth: more.implicitWidth + 14
          implicitHeight: 20
          radius: 10
          color: Theme.overlay

          Label {
            id: more
            anchors.centerIn: parent
            text: "+" + (window.normal.length - 1)
            kind: "label"
            font.capitalization: Font.MixedCase
            color: Theme.text
          }
        }
      }
    }
  }
}
