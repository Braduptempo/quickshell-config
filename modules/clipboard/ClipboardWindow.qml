// ClipboardWindow.qml
// Clipboard history (Super + Shift + V, or "clipboard" in the launcher).
// The list is on the left, a preview of the chosen item on the right.
//   ↑ ↓          choose          Tab        next filter
//   Enter        paste           Ctrl+Enter copy only
//   Ctrl + P     pin / unpin     Del        remove (at the end of the search text)
//   Esc          close
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

  readonly property bool shown: Clipboard.open
  readonly property var filters: [
    { key: "all", label: "All" },
    { key: "text", label: "Text" },
    { key: "image", label: "Images" },
    { key: "link", label: "Links" },
    { key: "color", label: "Colors" }
  ]
  property string filter: "all"
  property var rows: []
  property int current: 0
  // "Clear all" asks for a second click
  property bool confirmClear: false

  readonly property var selected: rows[current] ?? null

  screen: Clipboard.screen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-clipboard"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  // No anchors: the compositor centres it
  implicitWidth: 980 + 24
  implicitHeight: 620 + 24

  function refresh(): void {
    const id = selected?.id ?? "";
    rows = Clipboard.filtered(filter, input.text.trim());
    const index = rows.findIndex(r => r.id === id);
    current = index >= 0 ? index : 0;
    Clipboard.loadPreview(selected);
  }

  function move(step: int): void {
    if (rows.length === 0) return;
    current = Math.max(0, Math.min(rows.length - 1, current + step));
    list.positionViewAtIndex(current, ListView.Contain);
    Clipboard.loadPreview(selected);
  }

  function nextFilter(step: int): void {
    const i = filters.findIndex(f => f.key === filter);
    filter = filters[(i + step + filters.length) % filters.length].key;
  }

  function paste(copyOnly: bool): void {
    const item = selected;
    if (!item) return;
    Clipboard.open = false;
    if (copyOnly) Clipboard.copy(item);
    else Clipboard.paste(item);
  }

  onFilterChanged: refresh()

  onShownChanged: {
    if (shown) {
      input.text = "";
      filter = "all";
      confirmClear = false;
      current = 0;
      refresh();
      input.forceActiveFocus();
    }
  }

  Connections {
    target: Clipboard
    function onRevisionChanged() {
      if (window.shown) window.refresh();
    }
  }

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Clipboard.open = false
  }

  GlassPanel {
    id: card

    x: 12
    width: 980
    height: 620
    radius: 20
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.82))
    clip: true

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown ? 0 : 10)
    scale: window.shown ? 1 : 0.97

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      // --- Search and filters ---------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 60
        Layout.leftMargin: 18
        Layout.rightMargin: 14
        spacing: 12

        Icon { name: "search"; size: 16; color: Theme.subtext }

        TextInput {
          id: input
          Layout.fillWidth: true
          color: Theme.text
          selectionColor: Theme.alpha(Theme.accent, 0.4)
          font.family: Theme.font.family
          font.pixelSize: Theme.font.title + 1
          clip: true
          focus: true

          Accessible.role: Accessible.EditableText
          Accessible.name: "Search clipboard"

          onTextChanged: window.refresh()
          Keys.onUpPressed: window.move(-1)
          Keys.onDownPressed: window.move(1)
          Keys.onTabPressed: window.nextFilter(1)
          Keys.onBacktabPressed: window.nextFilter(-1)
          Keys.onEscapePressed: Clipboard.open = false
          Keys.onPressed: event => {
            const ctrl = event.modifiers & Qt.ControlModifier;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              window.paste(ctrl);
              event.accepted = true;
            } else if (ctrl && event.key === Qt.Key_P) {
              if (window.selected) Clipboard.togglePin(window.selected);
              event.accepted = true;
            } else if (event.key === Qt.Key_Delete && input.cursorPosition === input.text.length) {
              if (window.selected) Clipboard.remove(window.selected);
              event.accepted = true;
            } else if (event.key === Qt.Key_PageDown) {
              window.move(8);
              event.accepted = true;
            } else if (event.key === Qt.Key_PageUp) {
              window.move(-8);
              event.accepted = true;
            }
          }

          Label {
            visible: input.text === ""
            text: "Search clipboard…"
            kind: "muted"
            font.pixelSize: Theme.font.title + 1
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        Row {
          spacing: 4

          Repeater {
            model: window.filters

            Rectangle {
              id: chip
              required property var modelData
              readonly property bool active: window.filter === modelData.key

              width: chipRow.implicitWidth + 24
              height: 30
              radius: Theme.pill(height)
              color: active ? Theme.alpha(Theme.accent, 0.18) : chipMouse.containsMouse ? Theme.item : "transparent"
              border.width: 1
              border.color: active ? Theme.accent : Theme.border

              Accessible.role: Accessible.RadioButton
              Accessible.name: modelData.label
              Accessible.checked: active

              Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

              Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: 5
                Label { text: chip.modelData.label; font.pixelSize: Theme.font.small; font.weight: chip.active ? Font.Bold : Font.Normal }
                Label {
                  // Re-evaluated on every refresh
                  text: Clipboard.revision >= 0 ? Clipboard.count(chip.modelData.key) : ""
                  kind: "muted"
                  font.pixelSize: Theme.font.small
                }
              }

              MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: window.filter = chip.modelData.key
              }
            }
          }
        }
      }

      Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairline }

      // --- List and preview ---------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 0

        Item {
          Layout.preferredWidth: 400
          Layout.fillHeight: true

          ListView {
            id: list
            anchors.fill: parent
            anchors.margins: 8
            model: window.rows
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds

            section.property: "pinned"
            section.delegate: Item {
              required property string section
              width: list.width
              height: 26
              Label {
                text: parent.section === "true" ? "Pinned" : "Recent"
                kind: "label"
                x: 10
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 4
              }
            }

            delegate: Item {
              id: row
              required property var modelData
              required property int index
              readonly property bool isSelected: index === window.current

              width: list.width
              height: 46

              Accessible.role: Accessible.ListItem
              Accessible.name: Clipboard.kindLabel(modelData.kind) + ": " + modelData.preview
              Accessible.selected: isSelected

              Rectangle {
                anchors.fill: parent
                radius: Theme.pill(height)
                color: row.isSelected ? Theme.alpha(Theme.accent, 0.16) : rowMouse.containsMouse ? Theme.item : "transparent"
                border.width: row.isSelected ? 1 : 0
                border.color: Theme.alpha(Theme.accent, 0.45)
                Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
              }

              RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 14
                spacing: 10

                Rectangle {
                  implicitWidth: 30
                  implicitHeight: 30
                  radius: 8
                  color: row.modelData.kind === "color" ? row.modelData.preview : Theme.overlay
                  border.width: row.modelData.kind === "color" ? 1 : 0
                  border.color: Theme.border

                  Icon {
                    visible: row.modelData.kind !== "color"
                    anchors.centerIn: parent
                    size: 14
                    strokeWidth: 2.2
                    name: ({ text: "text", code: "code", link: "link", image: "image" })[row.modelData.kind] ?? "text"
                    color: row.modelData.kind === "code" ? Theme.good : row.modelData.kind === "text" ? Theme.text : Theme.accent
                  }
                }

                ColumnLayout {
                  Layout.fillWidth: true
                  spacing: 2
                  Label {
                    text: row.modelData.kind === "image" ? Clipboard.imageTitle(row.modelData) : row.modelData.preview
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    Layout.fillWidth: true
                  }
                  Label {
                    text: Clipboard.meta(row.modelData)
                    kind: "muted"
                    font.pixelSize: Theme.font.label
                    Layout.fillWidth: true
                  }
                }

                Icon {
                  visible: row.modelData.pinned
                  name: "pin"
                  size: 12
                  strokeWidth: 2.4
                  color: Theme.accent
                }
              }

              MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  window.current = row.index;
                  Clipboard.loadPreview(window.selected);
                  input.forceActiveFocus();
                }
                onDoubleClicked: window.paste(false)
              }
            }
          }

          // Empty states
          ColumnLayout {
            visible: window.rows.length === 0
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 6

            Icon { name: "clipboard"; size: 28; color: Theme.subtext; Layout.alignment: Qt.AlignHCenter }
            Label {
              text: !Clipboard.available ? "Clipboard history needs cliphist"
                  : Clipboard.items.length === 0 ? "Nothing copied yet" : "Nothing matches"
              font.weight: Font.Bold
              Layout.alignment: Qt.AlignHCenter
            }
            Label {
              text: !Clipboard.available ? "Install it with: sudo pacman -S cliphist"
                  : Clipboard.items.length === 0 ? "Copy something and it shows up here" : "Try another word or filter"
              kind: "muted"
              horizontalAlignment: Text.AlignHCenter
              wrapMode: Text.Wrap
              Layout.fillWidth: true
            }
          }
        }

        Rectangle { implicitWidth: 1; Layout.fillHeight: true; color: Theme.hairline }

        // Preview
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.margins: 18
          spacing: 14
          visible: window.selected !== null

          RowLayout {
            Layout.fillWidth: true
            Label { text: Clipboard.kindLabel(window.selected?.kind ?? ""); kind: "title"; Layout.fillWidth: true }
            Label { text: window.selected ? Clipboard.meta(window.selected) : ""; kind: "muted"; font.pixelSize: Theme.font.label }
          }

          // Image
          Rectangle {
            visible: window.selected?.kind === "image"
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Theme.crust
            border.width: 1
            border.color: Theme.border
            clip: true

            Image {
              anchors.fill: parent
              anchors.margins: 8
              source: window.selected?.kind === "image" ? Clipboard.previewImage : ""
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
            }
          }

          // Colour
          RowLayout {
            visible: window.selected?.kind === "color"
            spacing: 14
            Rectangle {
              implicitWidth: 120
              implicitHeight: 120
              radius: 16
              color: window.selected?.kind === "color" ? window.selected.preview : "transparent"
              border.width: 1
              border.color: Theme.border
            }
            Label { text: window.selected?.preview ?? ""; font.pixelSize: 22; font.weight: Font.Bold }
          }

          // Text, code, links
          Rectangle {
            visible: window.selected !== null && window.selected.kind !== "image"
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: Theme.item
            clip: true

            Flickable {
              id: textFlick
              anchors.fill: parent
              anchors.margins: 14
              contentHeight: body.implicitHeight
              boundsBehavior: Flickable.StopAtBounds
              clip: true

              Text {
                id: body
                width: textFlick.width
                text: Clipboard.previewText !== "" ? Clipboard.previewText : (window.selected?.preview ?? "")
                color: Theme.subtext
                font.family: Theme.font.family
                font.pixelSize: Theme.font.body
                lineHeight: 1.5
                wrapMode: Text.WrapAnywhere
                textFormat: Text.PlainText
              }
            }
          }

          RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button { text: LauncherTools.hasWtype ? "Paste ↵" : "Copy ↵"; variant: "primary"; onClicked: window.paste(false) }
            Button { visible: LauncherTools.hasWtype; text: "Copy"; variant: "ghost"; onClicked: window.paste(true) }
            Button {
              text: window.selected?.pinned ? "Unpin" : "Pin"
              icon: "pin"
              variant: "ghost"
              onClicked: Clipboard.togglePin(window.selected)
            }
            Button {
              visible: window.selected?.kind === "image"
              text: "Save as file"
              variant: "ghost"
              onClicked: Clipboard.saveImage(window.selected)
            }
            Item { Layout.fillWidth: true }
            Button { text: "Delete"; icon: "trash"; variant: "dangerSoft"; onClicked: Clipboard.remove(window.selected) }
          }
        }
      }

      // --- Footer --------------------------------------------------------------------
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 42
        color: Theme.alpha(Theme.crust, 0.35)

        Rectangle { width: parent.width; height: 1; color: Theme.hairline }

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 12
          spacing: 12

          Label {
            text: Clipboard.items.length + (Clipboard.items.length === 1 ? " item" : " items") + " · passwords from password managers are never stored"
            kind: "muted"
            font.pixelSize: Theme.font.label
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
          Row { spacing: 5; Kbd { text: "↑ ↓" } Label { text: "choose"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
          Row { spacing: 5; Kbd { text: "Ctrl + P" } Label { text: "pin"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
          Row { spacing: 5; Kbd { text: "Del" } Label { text: "remove"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
          Row { spacing: 5; Kbd { text: "Esc" } Label { text: "close"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
          Button {
            text: window.confirmClear ? "Click again to clear" : "Clear all"
            variant: window.confirmClear ? "dangerSoft" : "outline"
            size: Theme.size.buttonRow
            onClicked: {
              if (!window.confirmClear) {
                window.confirmClear = true;
                clearReset.restart();
              } else {
                window.confirmClear = false;
                Clipboard.clearUnpinned();
              }
            }
          }
        }
      }
    }
  }

  Timer {
    id: clearReset
    interval: 3000
    onTriggered: window.confirmClear = false
  }
}
