// LauncherWindow.qml
// The launcher (Super + Space): type to search apps, do a sum, or start a
// line with ">" to run a command. ↑ ↓ to choose, Enter to open, Esc to close.
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

  function refresh(): void {
    results = Launcher.search(input.text);
    current = 0;
  }

  function move(step: int): void {
    if (results.length === 0) return;
    current = (current + step + results.length) % results.length;
    list.positionViewAtIndex(current, ListView.Contain);
  }

  onShownChanged: {
    if (shown) {
      input.text = Launcher.initialQuery;
      refresh();
      input.forceActiveFocus();
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
            name: input.text.trim().startsWith(">") ? "arrow-right" : "search"
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

            Accessible.role: Accessible.EditableText
            Accessible.name: "Search apps, sums and commands"

            onTextChanged: window.refresh()
            Keys.onUpPressed: window.move(-1)
            Keys.onDownPressed: window.move(1)
            Keys.onTabPressed: window.move(1)
            Keys.onBacktabPressed: window.move(-1)
            Keys.onEscapePressed: Launcher.open = false
            Keys.onReturnPressed: Launcher.activate(window.results[window.current])
            Keys.onEnterPressed: Launcher.activate(window.results[window.current])

            Label {
              visible: input.text === ""
              text: "Search apps, do a sum, or > run a command"
              kind: "muted"
              font.pixelSize: Theme.font.title + 2
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          Kbd { text: "Esc" }
        }
      }

      // --- Results -------------------------------------------------------------
      ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 8 * 50)
        visible: window.results.length > 0
        model: window.results
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        currentIndex: window.current
        highlightFollowsCurrentItem: false

        delegate: Item {
          id: row
          required property var modelData
          required property int index
          readonly property bool selected: index === window.current

          width: list.width
          height: 48

          Accessible.role: Accessible.ListItem
          Accessible.name: modelData.title + (modelData.subtitle !== "" ? ", " + modelData.subtitle : "")
          Accessible.selected: selected

          Rectangle {
            anchors.fill: parent
            radius: Theme.pill(height)
            color: row.selected ? Theme.alpha(Theme.accent, 0.16) : rowMouse.containsMouse ? Theme.item : "transparent"
            border.width: row.selected ? 1 : 0
            border.color: Theme.alpha(Theme.accent, 0.45)

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
                visible: row.modelData.kind === "app" && status === Image.Ready
                source: row.modelData.kind === "app" ? Quickshell.iconPath(row.modelData.icon, true) : ""
                asynchronous: true
              }

              Rectangle {
                anchors.fill: parent
                visible: !appIcon.visible
                radius: 16
                color: row.modelData.kind === "app" ? Theme.overlay : Theme.alpha(Theme.accent, 0.2)

                Icon {
                  anchors.centerIn: parent
                  name: row.modelData.kind === "app" ? "image" : row.modelData.icon
                  size: 16
                  color: row.modelData.kind === "app" ? Theme.subtext : Theme.accent
                }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 1

              Label {
                text: row.modelData.title
                font.weight: Font.Bold
                font.pixelSize: row.modelData.kind === "calc" ? Theme.font.title + 4 : Theme.font.body
                Layout.fillWidth: true
              }
              Label {
                visible: row.modelData.subtitle !== ""
                text: row.modelData.subtitle
                kind: "muted"
                font.pixelSize: Theme.font.label
                Layout.fillWidth: true
              }
            }

            Label {
              text: row.selected ? (row.modelData.kind === "calc" ? "Enter to copy" : "Enter")
                  : row.modelData.kind === "app" ? "Application"
                  : row.modelData.kind === "calc" ? "Calculator"
                  : row.modelData.kind === "command" ? "Command" : "Web"
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: window.current = row.index
            onClicked: Launcher.activate(row.modelData)
          }
        }
      }

      Label {
        visible: window.results.length === 0 && input.text !== ""
        text: "Nothing found"
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
        Row { spacing: 6; Kbd { text: ">" } Label { text: "command"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter } }
        Item { Layout.fillWidth: true }
        Label {
          text: window.results.filter(r => r.kind === "app").length + " apps"
          kind: "muted"
        }
      }
    }
  }
}
