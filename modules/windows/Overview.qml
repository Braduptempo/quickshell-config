// Overview.qml
// Workspace overview (Super + Tab): your workspaces as a strip with their
// windows drawn to scale, and the chosen workspace's windows as live
// previews. Drag a window onto a workspace in the strip to move it there.
//   ← →        workspace          Tab     next window       type    filter all windows
//   Enter      focus              Ctrl+W  close             Esc     back
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Windows.overviewOpen
  property int workspace: 1
  property int current: 0
  property string query: ""

  // Workspaces to show: the first five, plus any with windows, plus the
  // active one. With workspaces per screen (the default) only this screen's:
  // its block (11…15 on the second screen) and what is on it.
  readonly property var workspaces: {
    const perScreen = Config.bar.workspacesPerScreen;
    const here = screen ? screen.name : "";
    const onThisScreen = id => !perScreen || (Hyprland.workspaces.values.find(w => w.id === id)?.monitor?.name ?? here) === here;
    const ids = new Set();
    for (const w of Windows.windows) if (onThisScreen(w.workspace)) ids.add(w.workspace);
    const focused = Hyprland.focusedWorkspace?.id ?? 1;
    if (onThisScreen(focused)) ids.add(focused);
    // The empty first five, unless one with the same number is already here
    const base = perScreen ? Windows.blockOf(here) : 0;
    const labels = new Set([...ids].map(i => Windows.workspaceLabel(i)));
    for (let n = 1; n <= 5; n++) if (!labels.has(n)) ids.add(base + n);
    return [...ids].filter(i => i > 0).sort((a, b) => Windows.workspaceLabel(a) - Windows.workspaceLabel(b) || a - b);
  }

  readonly property var shownWindows: query.trim() !== ""
    ? Windows.windows.filter(w => (Windows.appName(w.app) + " " + w.title).toLowerCase().includes(query.trim().toLowerCase()))
    : Windows.windows.filter(w => w.workspace === workspace)
  readonly property var selected: shownWindows[current] ?? null

  // The monitor a workspace is on, for drawing it to scale
  readonly property var monitorSize: ({ width: screen ? screen.width : 1920, height: screen ? screen.height : 1080 })

  screen: Windows.screen ?? Panels.focusedScreen()
  visible: shown || backdrop.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-overview"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  onShownChanged: {
    if (!shown) return;
    workspace = Hyprland.focusedWorkspace?.id ?? 1;
    current = 0;
    search.text = "";
    search.forceActiveFocus();
  }

  function focusSelected(): void {
    if (!selected) return;
    Windows.overviewOpen = false;
    Windows.focus(selected.address);
  }

  function goToWorkspace(id: int): void {
    Windows.overviewOpen = false;
    Hypr.focusWorkspace(id);
  }

  function stepWorkspace(step: int): void {
    const i = workspaces.indexOf(workspace);
    workspace = workspaces[Math.max(0, Math.min(workspaces.length - 1, (i < 0 ? 0 : i) + step))];
    current = 0;
  }

  // Dim and blur what's behind (Hyprland blurs the layer); clicking it closes
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.alpha(Theme.crust, 0.8)
    opacity: window.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }

    MouseArea {
      anchors.fill: parent
      onClicked: Windows.overviewOpen = false
    }
  }

  ColumnLayout {
    id: content
    anchors.fill: parent
    anchors.topMargin: Theme.size.bar + 32
    anchors.leftMargin: 80
    anchors.rightMargin: 80
    anchors.bottomMargin: 28
    spacing: 22
    opacity: backdrop.opacity

    // --- Search ---------------------------------------------------------------------
    GlassPanel {
      Layout.alignment: Qt.AlignHCenter
      implicitWidth: 520
      implicitHeight: 44
      radius: Theme.pill(height)

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 6
        spacing: 10
        Icon { name: "search"; size: 15; color: Theme.subtext }
        TextInput {
          id: search
          Layout.fillWidth: true
          color: Theme.text
          font.family: Theme.font.family
          font.pixelSize: Theme.font.body
          clip: true
          focus: true
          onTextChanged: {
            window.query = text;
            window.current = 0;
          }
          Accessible.role: Accessible.EditableText
          Accessible.name: "Search windows"
          Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Escape) {
              if (search.text !== "") search.text = "";
              else Windows.overviewOpen = false;
            } else if ((event.key === Qt.Key_Left && search.text === "") || (ctrl && event.key === Qt.Key_H)) window.stepWorkspace(-1);
            else if ((event.key === Qt.Key_Right && search.text === "") || (ctrl && event.key === Qt.Key_L)) window.stepWorkspace(1);
            // Vim keys with Ctrl (plain letters go to the search): J / K step through the windows
            else if (ctrl && event.key === Qt.Key_J) window.current = window.shownWindows.length > 0 ? (window.current + 1) % window.shownWindows.length : 0;
            else if (ctrl && event.key === Qt.Key_K) window.current = window.shownWindows.length > 0 ? (window.current + window.shownWindows.length - 1) % window.shownWindows.length : 0;
            else if (event.key === Qt.Key_Tab) window.current = window.shownWindows.length > 0 ? (window.current + 1) % window.shownWindows.length : 0;
            else if (event.key === Qt.Key_Backtab) window.current = window.shownWindows.length > 0 ? (window.current + window.shownWindows.length - 1) % window.shownWindows.length : 0;
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              if (window.selected) window.focusSelected();
              else window.goToWorkspace(window.workspace);
            } else if (ctrl && event.key === Qt.Key_W && window.selected) Windows.close(window.selected.address);
            else return;
            event.accepted = true;
          }
          Label { visible: search.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Type to filter windows on all workspaces"; kind: "muted" }
        }
        Kbd { text: "Super + Tab" }
      }
    }

    // --- Workspace strip --------------------------------------------------------------
    Row {
      Layout.alignment: Qt.AlignHCenter
      spacing: 12

      Repeater {
        model: window.workspaces

        Rectangle {
          id: ws
          required property int modelData
          readonly property bool chosen: modelData === window.workspace && window.query === ""
          readonly property bool active: modelData === (Hyprland.focusedWorkspace?.id ?? -1)
          readonly property var windowsHere: Windows.windows.filter(w => w.workspace === modelData)

          width: 176
          height: 124
          radius: Theme.r(16)
          color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.7))
          border.width: 2
          border.color: drop.containsDrag ? Theme.good : chosen ? Theme.accent : Theme.border

          Accessible.role: Accessible.Button
          Accessible.name: "Workspace " + Windows.workspaceLabel(modelData) + ", " + windowsHere.length + " windows"

          // The workspace to scale, with its windows as blocks
          Rectangle {
            id: mini
            x: 6
            y: 6
            width: parent.width - 12
            height: 88
            radius: Theme.r(10)
            color: Theme.alpha(Theme.accent, 0.12)
            clip: true

            Repeater {
              model: ws.windowsHere

              Rectangle {
                id: block
                required property var modelData
                readonly property real sx: mini.width / window.monitorSize.width
                readonly property real sy: mini.height / window.monitorSize.height
                // Positions are global; make them relative to the monitor
                x: Math.max(0, (modelData.x % window.monitorSize.width) * sx)
                y: Math.max(0, (modelData.y % window.monitorSize.height) * sy)
                width: Math.max(10, modelData.width * sx)
                height: Math.max(8, modelData.height * sy)
                radius: Theme.r(4)
                color: Theme.surface
                border.width: 1
                border.color: Theme.border

                IconImage {
                  anchors.centerIn: parent
                  implicitSize: Math.min(16, parent.height - 4)
                  source: Quickshell.iconPath(Windows.appIcon(block.modelData.app), "application-x-executable")
                }
              }
            }
          }

          RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            anchors.bottomMargin: 6
            Label { text: Windows.workspaceLabel(ws.modelData); font.weight: Font.Bold; font.pixelSize: Theme.font.small }
            Rectangle { visible: ws.active; width: 6; height: 6; radius: Theme.r(3); color: Theme.accent }
            Item { Layout.fillWidth: true }
            Label {
              text: ws.windowsHere.length === 0 ? "Empty" : ws.windowsHere.length + (ws.windowsHere.length === 1 ? " window" : " windows")
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              window.workspace = ws.modelData;
              window.current = 0;
              search.text = "";
            }
            onDoubleClicked: window.goToWorkspace(ws.modelData)
          }

          // Drop a window here to move it
          DropArea {
            id: drop
            anchors.fill: parent
            keys: ["window"]
            onDropped: event => {
              // The source is a window tile, which carries its address
              Windows.moveTo(event.source["address"], ws.modelData);
              event.accept();
            }
          }
        }
      }
    }

    // --- Windows ------------------------------------------------------------------------
    RowLayout {
      Layout.fillWidth: true
      spacing: 12
      Label {
        text: window.query !== "" ? "Results" : "Workspace " + Windows.workspaceLabel(window.workspace)
        kind: "title"
        font.pixelSize: Theme.font.title + 2
      }
      Label {
        text: window.query !== "" ? window.shownWindows.length + " windows match" : window.shownWindows.length + " windows · click to focus, drag onto a workspace to move"
        kind: "muted"
        font.pixelSize: Theme.font.small
      }
      Item { Layout.fillWidth: true }
      Button {
        visible: window.query === ""
        text: "Go to workspace " + window.workspace
        variant: "ghost"
        size: Theme.size.buttonList
        onClicked: window.goToWorkspace(window.workspace)
      }
    }

    GridView {
      id: grid
      Layout.fillWidth: true
      Layout.fillHeight: true
      cellWidth: Math.floor(width / 3)
      cellHeight: 250
      clip: true
      model: window.shownWindows
      boundsBehavior: Flickable.StopAtBounds

      delegate: Item {
        id: tile
        required property var modelData
        required property int index
        readonly property bool chosen: index === window.current
        readonly property var toplevel: Windows.toplevel(modelData.address)
        // For dragging onto a workspace
        readonly property string address: modelData.address

        width: grid.cellWidth
        height: grid.cellHeight

        // Not anchored, so it can be dragged; snaps back when not dropped
        Rectangle {
          id: frame
          x: 8
          y: 8
          width: tile.width - 16
          height: tile.height - 16
          z: tileMouse.drag.active ? 10 : 0
          radius: Theme.r(18)
          color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.8))
          border.width: 2
          border.color: tile.chosen ? Theme.accent : Theme.border
          scale: tileMouse.containsMouse && !tileMouse.drag.active ? 1.02 : 1

          Drag.active: tileMouse.drag.active
          Drag.keys: ["window"]
          Drag.source: tile
          Drag.hotSpot.x: width / 2
          Drag.hotSpot.y: height / 2

          Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

          Accessible.role: Accessible.Button
          Accessible.name: "Focus " + Windows.appName(tile.modelData.app) + ": " + tile.modelData.title

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: Theme.r(12)
              color: Theme.crust
              clip: true

              ScreencopyView {
                anchors.fill: parent
                captureSource: window.shown && tile.toplevel ? tile.toplevel.wayland : null
                live: tile.chosen
                constraintSize: Qt.size(480, 300)
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 10
              IconImage {
                implicitSize: 26
                source: Quickshell.iconPath(Windows.appIcon(tile.modelData.app), "application-x-executable")
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label { text: Windows.appName(tile.modelData.app); font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
                Label {
                  text: (window.query !== "" ? "Workspace " + Windows.workspaceLabel(tile.modelData.workspace) + " · " : "") + tile.modelData.title
                  kind: "muted"
                  font.pixelSize: Theme.font.label
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                }
              }
              IconButton {
                icon: "close"
                size: 28
                variant: "dangerSoft"
                accessibleName: "Close " + Windows.appName(tile.modelData.app)
                onClicked: Windows.close(tile.modelData.address)
              }
            }
          }

          MouseArea {
            id: tileMouse
            anchors.fill: parent
            anchors.bottomMargin: 44
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor
            drag.target: frame
            onReleased: {
              // Not dropped on a workspace: back in place
              if (frame.Drag.drop() !== Qt.IgnoreAction) return;
              frame.x = 8;
              frame.y = 8;
            }
            onClicked: {
              window.current = tile.index;
              window.focusSelected();
            }
          }
        }
      }

      Label {
        visible: window.shownWindows.length === 0
        anchors.centerIn: parent
        text: window.query !== "" ? "No windows match \"" + window.query + "\"" : "No windows on this workspace · drag one here from another, or open an app with Super + Space"
        kind: "muted"
      }
    }

    Row {
      Layout.alignment: Qt.AlignHCenter
      spacing: 14
      Row { spacing: 6; Kbd { text: "← → / Ctrl H L" } Label { text: "workspace"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      Row { spacing: 6; Kbd { text: "Tab / Ctrl J K" } Label { text: "window"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      Row { spacing: 6; Kbd { text: "Enter" } Label { text: "focus"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      Row { spacing: 6; Kbd { text: "Ctrl + W" } Label { text: "close"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      Row { spacing: 6; Kbd { text: "Esc" } Label { text: "back"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
    }
  }
}
