// LauncherWindow.qml
// The launcher (Super + Space). Type to search apps, commands and more;
// see services/Launcher.qml for everything you can type.
//   ↑ ↓ / Tab   choose            Enter         open
//   Ctrl + K    actions for apps  Ctrl + Enter  alternative (force kill, edit script)
//   Esc         back / close
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Launcher.open
  property var results: []
  property int current: 0
  // Ctrl + K menu for the selected app
  property var actions: []
  property int actionCurrent: 0
  readonly property bool inActions: actions.length > 0
  // Key of a result waiting for a second Enter (shut down, log out…)
  property string pendingConfirm: ""

  readonly property var selected: results[current] ?? null
  readonly property var rows: inActions ? actions : results

  screen: Launcher.screen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-launcher"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // Top edge only: centred horizontally, a fifth down the screen
  anchors.top: true
  margins.top: Math.round(screen.height * 0.18)
  implicitWidth: 680 + 24
  implicitHeight: card.implicitHeight + 24

  function refresh(keepPosition: bool): void {
    const key = selected?.key ?? "";
    results = Launcher.search(input.text);
    pendingConfirm = "";
    const index = keepPosition ? results.findIndex(r => r.key === key) : -1;
    current = index >= 0 ? index : 0;
  }

  function move(step: int): void {
    const count = rows.length;
    if (count === 0) return;
    if (inActions) {
      actionCurrent = (actionCurrent + step + count) % count;
      list.positionViewAtIndex(actionCurrent, ListView.Contain);
    } else {
      current = (current + step + count) % count;
      pendingConfirm = "";
      list.positionViewAtIndex(current, ListView.Contain);
    }
  }

  function activate(alternative: bool): void {
    if (inActions) {
      const action = actions[actionCurrent];
      if (!action) return;
      action.run();
      actions = [];
      if (action.keepOpen) refresh(true);
      else Launcher.open = false;
      return;
    }
    const result = selected;
    if (!result) return;
    if (result.confirm && pendingConfirm !== result.key) {
      pendingConfirm = result.key;
      return;
    }
    if (alternative && result.runAlt) result.runAlt();
    else result.run();
    Launcher.open = false;
  }

  function openActions(): void {
    if (inActions) {
      actions = [];
      return;
    }
    const list = Launcher.actionsFor(selected);
    if (list.length === 0) return;
    actionCurrent = 0;
    actions = list;
  }

  onShownChanged: {
    if (shown) {
      actions = [];
      input.text = Launcher.initialQuery;
      refresh(false);
      input.forceActiveFocus();
    }
  }

  // Processes and scripts arrive a moment later
  Connections {
    target: Launcher
    function onRevisionChanged() {
      if (window.shown && !window.inActions) window.refresh(true);
    }
  }

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Launcher.open = false
  }

  GlassPanel {
    id: card

    x: 12
    width: 680
    implicitHeight: content.implicitHeight + 20
    height: implicitHeight
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.82))
    transformOrigin: Item.Top

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown ? 0 : -10)
    scale: window.shown ? 1 : 0.97

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    ColumnLayout {
      id: content
      x: 10
      y: 10
      width: parent.width - 20
      spacing: 8

      // --- Search field ------------------------------------------------------
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.pill(height)
        color: Theme.item

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 12
          spacing: 12

          Icon {
            name: window.inActions ? "settings" : input.text.trim().startsWith(">") ? "arrow-right" : "search"
            size: 18
            color: Theme.subtext
          }

          TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.font.family
            font.pixelSize: Theme.font.title + 2
            clip: true
            focus: true
            readOnly: window.inActions

            Accessible.role: Accessible.EditableText
            Accessible.name: "Search apps, commands, sums and more"

            onTextChanged: if (!window.inActions) window.refresh(false)
            Keys.onUpPressed: window.move(-1)
            Keys.onDownPressed: window.move(1)
            Keys.onTabPressed: window.move(1)
            Keys.onBacktabPressed: window.move(-1)
            Keys.onEscapePressed: {
              if (window.inActions) window.actions = [];
              else Launcher.open = false;
            }
            Keys.onPressed: event => {
              const ctrl = event.modifiers & Qt.ControlModifier;
              if (ctrl && event.key === Qt.Key_K) {
                window.openActions();
                event.accepted = true;
              } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                window.activate(ctrl);
                event.accepted = true;
              }
            }

            Label {
              visible: input.text === ""
              text: window.inActions ? "" : "Search apps and commands, or try yt, kill, window, >"
              kind: "muted"
              font.pixelSize: Theme.font.title + 2
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Label {
            visible: window.inActions
            text: "Actions for " + (window.selected?.title ?? "")
            kind: "muted"
          }

          Kbd { text: window.inActions ? "Esc back" : "Esc" }
        }
      }

      // --- Results / actions ---------------------------------------------------
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 440)
        visible: window.rows.length > 0
        model: window.rows
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        highlightFollowsCurrentItem: false

        section.property: window.inActions ? "" : "section"
        section.delegate: Item {
          required property string section
          width: list.width
          height: 26
          Label {
            text: parent.section
            kind: "label"
            x: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
          }
        }

        delegate: Item {
          id: row
          required property var modelData
          required property int index
          readonly property bool isSelected: window.inActions ? index === window.actionCurrent : index === window.current
          readonly property bool confirming: !window.inActions && window.pendingConfirm !== "" && window.pendingConfirm === modelData.key
          readonly property bool hasAppIcon: (modelData.appIcon ?? "") !== ""

          width: list.width
          height: 48

          Accessible.role: Accessible.ListItem
          Accessible.name: modelData.title + ((modelData.subtitle ?? "") !== "" ? ", " + modelData.subtitle : "")
          Accessible.selected: isSelected

          Rectangle {
            anchors.fill: parent
            radius: Theme.pill(height)
            color: row.confirming ? Theme.alpha(Theme.error, 0.16)
                 : row.isSelected ? Theme.alpha(Theme.accent, 0.16)
                 : rowMouse.containsMouse ? Theme.item : "transparent"
            border.width: row.isSelected ? 1 : 0
            border.color: row.confirming ? Theme.error : Theme.alpha(Theme.accent, 0.45)

            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
          }

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 14
            spacing: 12

            Item {
              implicitWidth: 32
              implicitHeight: 32

              IconImage {
                id: appIcon
                anchors.fill: parent
                visible: row.hasAppIcon && status === Image.Ready
                source: row.hasAppIcon ? Quickshell.iconPath(row.modelData.appIcon, true) : ""
                asynchronous: true
              }

              Rectangle {
                anchors.fill: parent
                visible: !appIcon.visible
                radius: 16
                color: row.hasAppIcon ? Theme.overlay : Theme.alpha(row.confirming ? Theme.error : Theme.accent, 0.2)

                Icon {
                  anchors.centerIn: parent
                  name: row.modelData.icon ?? "image"
                  size: 16
                  color: row.hasAppIcon ? Theme.subtext : row.confirming ? Theme.error : Theme.accent
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Label {
                text: row.modelData.title
                font.weight: Font.Bold
                font.pixelSize: row.modelData.big ? Theme.font.title + 4 : Theme.font.body
                Layout.fillWidth: true
              }
              Label {
                visible: text !== ""
                text: row.confirming ? row.modelData.confirm : (row.modelData.subtitle ?? "")
                kind: "muted"
                color: row.confirming ? Theme.error : Theme.subtext
                font.pixelSize: Theme.font.label
                Layout.fillWidth: true
              }
            }

            Label {
              text: !row.isSelected ? (row.modelData.hint ?? "")
                  : row.modelData.altHint ?? (row.modelData.app && !window.inActions ? "Enter · Ctrl + K actions" : "Enter")
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: {
              if (window.inActions) window.actionCurrent = row.index;
              else if (window.current !== row.index) {
                window.current = row.index;
                window.pendingConfirm = "";
              }
            }
            onClicked: window.activate(false)
          }
        }
      }

      Label {
        visible: window.rows.length === 0 && input.text !== ""
        text: input.text.trim().toLowerCase().startsWith("kill") ? "Looking for processes…" : "Nothing found"
        kind: "muted"
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.bottomMargin: 12
      }

      // --- Hints ----------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        Layout.bottomMargin: 2
        spacing: 12

        Row { spacing: 6; Kbd { text: "↑ ↓" } Label { text: "select"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Enter" } Label { text: "open"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Ctrl + K" } Label { text: "actions"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter } }
        Item { Layout.fillWidth: true }
        Label {
          text: "yt · aw · aur · gh · kill · window · >"
          kind: "muted"
        }
      }
    }
  }
}
