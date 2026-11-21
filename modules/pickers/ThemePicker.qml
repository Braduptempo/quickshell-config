// ThemePicker.qml
// Quick theme switch (Super + T): a carousel of the colour themes, with a
// live preview while you browse, and the accent colour below.
//   ← →     browse (the shell follows right away)    type   search
//   Enter   keep it                                   Esc    back to what you had
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

  readonly property bool shown: Panels.themePickerOpen
  // 0 all, 1 dark, 2 light
  property int kind: 0
  property var themes: []
  // What was in use when the picker opened, for Esc
  property string startTheme: ""
  property string startAccent: ""

  readonly property var accents: [
    { label: "Theme default", color: "" },
    { label: "Blue", color: "#89b4fa" }, { label: "Lavender", color: "#b4befe" },
    { label: "Purple", color: "#cba6f7" }, { label: "Pink", color: "#f5c2e7" },
    { label: "Red", color: "#f38ba8" }, { label: "Peach", color: "#fab387" },
    { label: "Yellow", color: "#f9e2af" }, { label: "Green", color: "#a6e3a1" }
  ]

  screen: Panels.themeScreen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-theme-picker"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  anchors.top: true
  margins.top: Theme.size.bar + 20
  implicitWidth: 760 + 24
  implicitHeight: card.implicitHeight + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: window.keep()
  }

  function refresh(): void {
    const q = search.text.trim().toLowerCase();
    themes = Palettes.list.filter(p => (kind === 0 || (kind === 1) !== p.light) && (q === "" || p.name.toLowerCase().includes(q)));
    const index = themes.findIndex(p => p.name === Config.appearance.theme);
    carousel.currentIndex = index >= 0 ? index : 0;
  }

  function browse(step: int): void {
    if (themes.length === 0) return;
    carousel.currentIndex = Math.max(0, Math.min(themes.length - 1, carousel.currentIndex + step));
    Config.appearance.theme = themes[carousel.currentIndex].name;
  }

  function keep(): void {
    Panels.themePickerOpen = false;
  }

  function cancel(): void {
    Config.appearance.theme = startTheme;
    Config.appearance.accent = startAccent;
    Panels.themePickerOpen = false;
  }

  onKindChanged: refresh()

  onShownChanged: {
    if (!shown) return;
    startTheme = Config.appearance.theme;
    startAccent = Config.appearance.accent;
    search.text = "";
    kind = 0;
    refresh();
    carousel.positionViewAtIndex(carousel.currentIndex, ListView.Center);
    search.forceActiveFocus();
  }

  GlassPanel {
    id: card

    x: 12
    width: 760
    implicitHeight: column.implicitHeight + 28
    height: implicitHeight
    radius: Theme.r(22)
    color: Theme.panelSolid
    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown ? 0 : -10)

    Accessible.role: Accessible.Dialog
    Accessible.name: "Quick theme switch"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on color { ColorAnimation { duration: Theme.anim.toggle } }

    ColumnLayout {
      id: column
      x: 14
      y: 14
      width: parent.width - 28
      spacing: 10

      // --- Search and filter ------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 38
          radius: Theme.pill(height)
          color: Theme.item

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10
            Icon { name: "search"; size: 14; color: Theme.subtext }
            TextInput {
              id: search
              Layout.fillWidth: true
              color: Theme.text
              font.family: Theme.font.family
              font.pixelSize: Theme.font.body
              clip: true
              focus: true

              Accessible.role: Accessible.EditableText
              Accessible.name: "Search themes"

              onTextChanged: window.refresh()
              Keys.onLeftPressed: event => {
                if (search.text === "" || search.cursorPosition === 0) window.browse(-1);
                else event.accepted = false;
              }
              Keys.onRightPressed: event => {
                if (search.text === "" || search.cursorPosition === search.text.length) window.browse(1);
                else event.accepted = false;
              }
              Keys.onReturnPressed: window.keep()
              Keys.onEnterPressed: window.keep()
              Keys.onEscapePressed: window.cancel()
              Keys.onTabPressed: window.kind = (window.kind + 1) % 3

              Label {
                visible: search.text === ""
                text: "Search themes…"
                kind: "muted"
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }

        Segmented {
          model: ["All", "Dark", "Light"]
          currentIndex: window.kind
          accessibleName: "Filter themes"
          onActivated: index => window.kind = index
        }
      }

      // --- Carousel ---------------------------------------------------------------------
      ListView {
        id: carousel
        Layout.fillWidth: true
        implicitHeight: 130
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        model: window.themes
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 140) / 2
        preferredHighlightEnd: (width + 140) / 2
        highlightMoveDuration: Theme.anim.stack
        boundsBehavior: Flickable.StopAtBounds
        interactive: false

        Accessible.role: Accessible.List
        Accessible.name: "Themes"

        delegate: Item {
          id: themeCard
          required property var modelData
          required property int index
          readonly property bool current: ListView.isCurrentItem
          readonly property bool inUse: modelData.name === window.startTheme
          readonly property int distance: Math.abs(index - carousel.currentIndex)

          width: 140
          height: carousel.height
          opacity: distance > 2 ? 0.35 : distance === 2 ? 0.6 : 1

          Accessible.role: Accessible.RadioButton
          Accessible.name: modelData.name + (modelData.light ? ", light" : ", dark") + (inUse ? ", in use" : "")
          Accessible.checked: current

          Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

          Rectangle {
            id: preview
            anchors.horizontalCenter: parent.horizontalCenter
            y: 8
            width: 140
            height: 92
            radius: Theme.r(14)
            color: themeCard.modelData.base
            border.width: themeCard.current ? 2 : 1
            border.color: themeCard.current ? (Config.appearance.accent !== "" ? Config.appearance.accent : themeCard.modelData.accent)
                                            : Qt.rgba(1, 1, 1, 0.12)
            scale: themeCard.current ? 1.06 : 1
            clip: true

            Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

            // A tiny bar and panel in the theme's own colours
            Rectangle { x: 8; y: 8; width: parent.width - 16; height: 10; radius: Theme.r(5); color: themeCard.modelData.surface }
            Rectangle { x: 8; y: 24; width: 58; height: 38; radius: Theme.r(8); color: themeCard.modelData.surface }
            Rectangle { x: 14; y: 32; width: 36; height: 5; radius: Theme.r(2); color: themeCard.modelData.text }
            Rectangle { x: 14; y: 42; width: 26; height: 5; radius: Theme.r(2); color: themeCard.modelData.subtext }
            Rectangle { x: 72; y: 24; width: 60; height: 18; radius: Theme.r(9); color: themeCard.modelData.accent }

            Row {
              x: 8
              anchors.bottom: parent.bottom
              anchors.bottomMargin: 8
              spacing: 4
              Repeater {
                model: themeCard.modelData.dots
                Rectangle {
                  required property string modelData
                  width: 10
                  height: 10
                  radius: Theme.r(5)
                  color: modelData
                }
              }
            }

            // In use
            Rectangle {
              visible: themeCard.inUse
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.margins: 6
              width: 18
              height: 18
              radius: Theme.r(9)
              color: themeCard.modelData.accent
              Icon { anchors.centerIn: parent; name: "check"; size: 11; strokeWidth: 3; color: themeCard.modelData.base }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (themeCard.current) {
                  window.keep();
                } else {
                  carousel.currentIndex = themeCard.index;
                  Config.appearance.theme = themeCard.modelData.name;
                }
              }
            }
          }

          Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: preview.bottom
            anchors.topMargin: 6
            text: themeCard.modelData.name
            font.pixelSize: Theme.font.small
            font.weight: themeCard.current ? Font.Bold : Font.Normal
          }
        }

        Label {
          visible: window.themes.length === 0
          anchors.centerIn: parent
          text: "No theme matches"
          kind: "muted"
        }
      }

      // --- Accent ------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Label { text: "Accent"; kind: "label" }

        Row {
          spacing: 6

          Repeater {
            model: window.accents

            Rectangle {
              id: swatch
              required property var modelData
              readonly property bool chosen: Config.appearance.accent === modelData.color

              width: 26
              height: 26
              radius: Theme.r(13)
              color: modelData.color !== "" ? modelData.color : Theme.palette.accent
              border.width: chosen ? 2 : 0
              border.color: Theme.text

              Accessible.role: Accessible.RadioButton
              Accessible.name: modelData.label
              Accessible.checked: chosen

              // "Theme default": the theme's own accent, marked with a dot
              Rectangle {
                visible: swatch.modelData.color === ""
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: Theme.r(4)
                color: Theme.base
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Config.appearance.accent = swatch.modelData.color
              }
            }
          }
        }

        Item { Layout.fillWidth: true }

        Row { spacing: 6; Kbd { text: "← →" } Label { text: "browse"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Enter" } Label { text: "keep"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Esc" } Label { text: "back to " + window.startTheme; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      }
    }
  }
}
