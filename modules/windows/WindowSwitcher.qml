// WindowSwitcher.qml
// Alt + Tab: the open windows with a live preview, most recently used first.
// Hold Alt and press Tab to step, release Alt to switch.
//   Alt + Tab / Alt + Shift + Tab   next / previous      Alt + Q   close it
//   ← →                             also step           Esc       cancel
// The Hyprland binds (hyprland/quickshell.lua) call `qs ipc call windows next`
// and, on releasing Alt, `commit`.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Windows.switcherOpen
  readonly property var list: Windows.switcherList
  readonly property var selected: list[Windows.switcherIndex] ?? null

  screen: Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-switcher"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // No anchors: the compositor centres it
  implicitWidth: Math.min(card.implicitWidth, (screen ? screen.width : 1920) - 80) + 24
  implicitHeight: card.implicitHeight + 24

  onShownChanged: if (shown) keys.forceActiveFocus()

  Item {
    id: keys
    focus: true
    Keys.onPressed: event => {
      const shift = event.modifiers & Qt.ShiftModifier;
      if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) Windows.switcherStep(event.key === Qt.Key_Backtab || shift ? -1 : 1);
      else if (event.key === Qt.Key_Right) Windows.switcherStep(1);
      else if (event.key === Qt.Key_Left) Windows.switcherStep(-1);
      else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) Windows.switcherCommit();
      else if (event.key === Qt.Key_Escape) Windows.switcherCancel();
      else if (event.key === Qt.Key_Q && window.selected) Windows.close(window.selected.address);
      else return;
      event.accepted = true;
    }
    // Letting go of Alt switches (the Hyprland release bind does too)
    Keys.onReleased: event => {
      if (event.key === Qt.Key_Alt || event.key === Qt.Key_Meta) {
        Windows.switcherCommit();
        event.accepted = true;
      }
    }
  }

  GlassPanel {
    id: card

    x: 12
    y: 12
    implicitWidth: column.implicitWidth + 32
    implicitHeight: column.implicitHeight + 32
    width: Math.min(implicitWidth, window.width - 24)
    height: implicitHeight
    radius: 18
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.88))
    opacity: window.shown ? 1 : 0
    scale: window.shown ? 1 : 0.96

    Accessible.role: Accessible.Dialog
    Accessible.name: "Switch window"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.fast : Theme.anim.panelOut } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

    ColumnLayout {
      id: column
      x: 16
      y: 16
      width: card.width - 32
      spacing: 14

      ListView {
        id: cards
        Layout.fillWidth: true
        implicitWidth: Math.max(1, window.list.length) * 178 - 10
        implicitHeight: 150
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: window.list
        currentIndex: Windows.switcherIndex
        highlightFollowsCurrentItem: false
        boundsBehavior: Flickable.StopAtBounds
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        Accessible.role: Accessible.List
        Accessible.name: "Open windows, most recent first"

        delegate: Rectangle {
          id: entry
          required property var modelData
          required property int index
          readonly property bool current: index === Windows.switcherIndex
          readonly property var toplevel: Windows.toplevel(modelData.address)

          width: 168
          height: cards.height
          radius: 16
          color: current ? Theme.alpha(Theme.text, 0.08) : entryMouse.containsMouse ? Theme.item : "transparent"
          border.width: 2
          border.color: current ? Theme.accent : "transparent"

          Accessible.role: Accessible.ListItem
          Accessible.name: Windows.appName(modelData.app) + ": " + modelData.title + ", workspace " + modelData.workspace
          Accessible.selected: current

          Rectangle {
            id: preview
            x: 6
            y: 6
            width: parent.width - 12
            height: 100
            radius: 10
            color: Theme.crust
            clip: true

            ScreencopyView {
              anchors.fill: parent
              captureSource: window.shown && entry.toplevel ? entry.toplevel.wayland : null
              live: entry.current
              constraintSize: Qt.size(320, 200)
            }

            Rectangle {
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 6
              implicitWidth: wsLabel.implicitWidth + 14
              implicitHeight: 18
              radius: 9
              color: Theme.alpha(Theme.crust, 0.75)
              Label { id: wsLabel; anchors.centerIn: parent; text: "WS " + entry.modelData.workspace; font.pixelSize: Theme.font.label; color: Theme.subtext }
            }
          }

          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: preview.bottom
            anchors.margins: 8
            anchors.topMargin: 8
            spacing: 8

            IconImage {
              implicitSize: 24
              source: Quickshell.iconPath(Windows.appIcon(entry.modelData.app), "application-x-executable")
            }
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1
              Label { text: Windows.appName(entry.modelData.app); font.weight: Font.Bold; font.pixelSize: Theme.font.small; elide: Text.ElideRight; Layout.fillWidth: true }
              Label { text: entry.modelData.title; kind: "muted"; font.pixelSize: Theme.font.label; elide: Text.ElideRight; Layout.fillWidth: true }
            }
          }

          MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              Windows.switcherIndex = entry.index;
              Windows.switcherCommit();
            }
          }
        }

        Label {
          visible: window.list.length === 0
          anchors.centerIn: parent
          text: "No windows open"
          kind: "muted"
        }
      }

      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Label {
          Layout.fillWidth: true
          text: window.selected ? "Release Alt to switch to " + Windows.appName(window.selected.app)
                                  + (Windows.switcherCurrentOnly ? "" : " on workspace " + window.selected.workspace) : ""
          color: Theme.subtext
          font.pixelSize: Theme.font.small
          elide: Text.ElideRight
        }
        Segmented {
          model: ["All workspaces", "This workspace"]
          currentIndex: Windows.switcherCurrentOnly ? 1 : 0
          accessibleName: "Show windows from"
          onActivated: index => {
            Windows.switcherCurrentOnly = index === 1;
            Windows.switcherIndex = Math.min(Windows.switcherIndex, Math.max(0, Windows.switcherList.length - 1));
          }
        }
        IconButton { icon: "chevron-left"; size: 34; accessibleName: "Previous window"; onClicked: Windows.switcherStep(-1) }
        IconButton { icon: "chevron-right"; size: 34; accessibleName: "Next window"; onClicked: Windows.switcherStep(1) }
      }
    }
  }
}
