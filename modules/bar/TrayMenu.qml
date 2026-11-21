// TrayMenu.qml
// A tray app's menu, drawn by the shell in its own style (Panels.trayMenuItem):
// the app at the top, its entries with icons, check marks and separators, and
// submenus that open in place with a back arrow. QsMenuOpener reads the
// entries; entry.triggered() runs one. Esc or a click outside closes it.
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

  readonly property var item: Panels.trayMenuItem
  readonly property bool shown: item !== null
  readonly property bool fromBottom: Config.bar.position === "bottom"
  readonly property string style: Config.animations.panelStyle
  readonly property int cardWidth: 280

  // Open submenus, deepest last
  property var stack: []
  readonly property var current: stack.length > 0 ? stack[stack.length - 1] : (item?.menu ?? null)

  onItemChanged: stack = []

  // How many entries the shown menu has (empty while it loads)
  readonly property var entryModel: opener.children
  readonly property int entryCount: entryModel ? entryModel.values.length : 0

  screen: Panels.trayMenuScreen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-traymenu"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: !window.fromBottom
    bottom: window.fromBottom
    left: true
  }
  margins {
    top: 6
    bottom: 6
    // Centred under the icon, kept on the screen
    left: Math.max(0, Math.min(Panels.trayMenuX - (window.cardWidth + 24) / 2, (window.screen ? window.screen.width : 1920) - window.cardWidth - 24))
  }
  implicitWidth: cardWidth + 24
  implicitHeight: card.implicitHeight + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.trayMenuItem = null
  }

  // "_Open" -> "Open"; "__" is a real underscore (DBusMenu mnemonics)
  function clean(text: string): string {
    return (text ?? "").replace(/__/g, "\u0001").replace(/_/g, "").replace(/\u0001/g, "_");
  }

  function close(): void {
    Panels.trayMenuItem = null;
  }

  QsMenuOpener {
    id: opener
    menu: window.current
  }

  GlassPanel {
    id: card
    color: Theme.panelSolid

    x: 12
    width: window.cardWidth
    implicitHeight: column.implicitHeight + 20
    height: implicitHeight
    focus: true
    transformOrigin: window.fromBottom ? Item.Bottom : Item.Top

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 10 : -10)
    scale: window.shown || window.style !== "scale" ? 1 : 0.94

    Accessible.role: Accessible.PopupMenu
    Accessible.name: (window.item?.tooltipTitle || window.item?.title || "App") + " menu"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.fast : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.anim.fast } }

    Keys.onEscapePressed: {
      if (window.stack.length > 0) window.stack = window.stack.slice(0, -1);
      else window.close();
    }

    ColumnLayout {
      id: column
      x: 10
      y: 10
      width: parent.width - 20
      spacing: 4

      // --- The app, or the submenu with a way back ---------------------------------------
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.bottomMargin: 2
        spacing: 8

        IconButton {
          visible: window.stack.length > 0
          icon: "chevron-left"
          size: 26
          variant: "plain"
          accessibleName: "Back"
          onClicked: window.stack = window.stack.slice(0, -1)
        }
        IconImage {
          visible: window.stack.length === 0 && source !== ""
          implicitSize: 18
          source: window.item?.icon ?? ""
        }
        Label {
          Layout.fillWidth: true
          text: window.stack.length > 0 ? window.clean(window.current?.text ?? "")
                                        : (window.item?.tooltipTitle || window.item?.title || window.item?.id || "App")
          font.weight: Font.Bold
          font.pixelSize: Theme.font.small
          elide: Text.ElideRight
        }
      }

      Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairline }

      Label {
        visible: window.entryCount === 0
        Layout.margins: 8
        text: "This menu is empty"
        kind: "muted"
        font.pixelSize: Theme.font.small
      }

      // --- The entries ----------------------------------------------------------------------
      Flickable {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(entries.implicitHeight, (window.screen ? window.screen.height : 1080) * 0.6)
        contentHeight: entries.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: entries
          width: parent.width
          spacing: 1

          Repeater {
            model: opener.children

            Item {
              id: entry
              required property QsMenuEntry modelData
              readonly property bool checkable: modelData.buttonType !== QsMenuButtonType.None
              readonly property bool checked: modelData.checkState === Qt.Checked

              width: entries.width
              height: modelData.isSeparator ? 9 : 34

              // A separator
              Rectangle {
                visible: entry.modelData.isSeparator
                anchors.verticalCenter: parent.verticalCenter
                x: 8
                width: parent.width - 16
                height: 1
                color: Theme.hairline
              }

              Rectangle {
                visible: !entry.modelData.isSeparator
                anchors.fill: parent
                radius: Theme.pill(height)
                color: entryMouse.containsMouse && entry.modelData.enabled ? Theme.item : "transparent"
                opacity: entry.modelData.enabled ? 1 : 0.4

                Accessible.role: entry.checkable ? (entry.modelData.buttonType === QsMenuButtonType.RadioButton ? Accessible.RadioButton : Accessible.CheckBox) : Accessible.MenuItem
                Accessible.name: window.clean(entry.modelData.text)
                Accessible.checked: entry.checked

                RowLayout {
                  anchors.fill: parent
                  anchors.leftMargin: 10
                  anchors.rightMargin: 10
                  spacing: 10

                  // Check box or radio
                  Rectangle {
                    visible: entry.checkable
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: entry.modelData.buttonType === QsMenuButtonType.RadioButton ? 8 : 5
                    color: entry.checked ? Theme.accent : "transparent"
                    border.width: entry.checked ? 0 : 1.5
                    border.color: Theme.overlay
                    Icon { visible: entry.checked; anchors.centerIn: parent; name: "check"; size: 11; strokeWidth: 3; color: Theme.onAccent }
                  }
                  IconImage {
                    visible: !entry.checkable && entry.modelData.icon !== ""
                    implicitSize: 16
                    source: entry.modelData.icon
                  }
                  Label {
                    Layout.fillWidth: true
                    text: window.clean(entry.modelData.text)
                    font.pixelSize: Theme.font.small
                    elide: Text.ElideRight
                  }
                  Icon { visible: entry.modelData.hasChildren; name: "chevron-right"; size: 13; color: Theme.subtext }
                }

                MouseArea {
                  id: entryMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: entry.modelData.enabled
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (entry.modelData.hasChildren) {
                      window.stack = window.stack.concat([entry.modelData]);
                    } else {
                      entry.modelData.triggered();
                      window.close();
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
