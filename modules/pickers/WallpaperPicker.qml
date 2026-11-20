// WallpaperPicker.qml
// Quick wallpaper switch (Super + W): a carousel of ~/Pictures/wallpapers with
// a live preview while you browse, and how it is shown.
//   ← →         browse, live preview         type       search
//   Ctrl + F    favourite                    Ctrl + R   random
//   Enter       keep it                      Esc        back to what you had
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

  readonly property bool shown: Wallpapers.open
  // 0 all, 1 favourites
  property int filter: 0
  property var walls: []
  readonly property var selected: walls[carousel.currentIndex] ?? null

  screen: Wallpapers.screen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-wallpaper-picker"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore

  anchors.bottom: true
  margins.bottom: 28
  implicitWidth: 1060 + 24
  implicitHeight: card.implicitHeight + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: window.keep()
  }

  function refresh(keepPath: string): void {
    const q = search.text.trim().toLowerCase();
    walls = Wallpapers.items.filter(w => (filter === 0 || Wallpapers.isFavorite(w.path)) && (q === "" || w.name.toLowerCase().includes(q)));
    const want = keepPath !== "" ? keepPath : Wallpapers.currentPath;
    const index = walls.findIndex(w => w.path === want);
    carousel.currentIndex = index >= 0 ? index : 0;
  }

  function browse(step: int): void {
    if (walls.length === 0) return;
    carousel.currentIndex = Math.max(0, Math.min(walls.length - 1, carousel.currentIndex + step));
    Wallpapers.preview(walls[carousel.currentIndex].path);
  }

  function pick(path: string): void {
    const index = walls.findIndex(w => w.path === path);
    if (index < 0) return;
    carousel.currentIndex = index;
    Wallpapers.preview(path);
  }

  function keep(): void {
    if (Wallpapers.previewing && selected) Wallpapers.set(selected.path);
    Wallpapers.open = false;
  }

  function cancel(): void {
    Wallpapers.restore();
    Wallpapers.open = false;
  }

  onFilterChanged: refresh(selected?.path ?? "")

  Connections {
    target: Wallpapers
    function onItemsChanged() {
      if (window.shown) window.refresh(window.selected?.path ?? "");
    }
  }

  onShownChanged: {
    if (!shown) return;
    search.text = "";
    filter = 0;
    refresh("");
    carousel.positionViewAtIndex(carousel.currentIndex, ListView.Center);
    search.forceActiveFocus();
  }

  component Option: RowLayout {
    id: option
    property string title
    property var labels: []
    property int current: 0
    signal picked(int index)
    spacing: 8
    Label { text: option.title; kind: "label" }
    Segmented {
      model: option.labels
      currentIndex: option.current
      accessibleName: option.title
      onActivated: index => option.picked(index)
    }
  }

  GlassPanel {
    id: card

    x: 12
    width: 1060
    implicitHeight: column.implicitHeight + 28
    height: implicitHeight
    radius: 22
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.85))
    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown ? 0 : 10)

    Accessible.role: Accessible.Dialog
    Accessible.name: "Quick wallpaper switch"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    ColumnLayout {
      id: column
      x: 14
      y: 14
      width: parent.width - 28
      spacing: 10

      // --- Search and filter ---------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
          Layout.preferredWidth: 300
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
              Accessible.name: "Search wallpapers"

              onTextChanged: window.refresh(window.selected?.path ?? "")
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
              Keys.onTabPressed: window.filter = (window.filter + 1) % 2
              Keys.onPressed: event => {
                if (!(event.modifiers & Qt.ControlModifier)) return;
                if (event.key === Qt.Key_F && window.selected) {
                  Wallpapers.toggleFavorite(window.selected.path);
                  event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                  window.pick(Wallpapers.random());
                  event.accepted = true;
                }
              }

              Label {
                visible: search.text === ""
                text: "Search wallpapers…"
                kind: "muted"
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }
        }

        Segmented {
          model: ["All " + Wallpapers.items.length, "Favourites " + Wallpapers.favorites.length]
          currentIndex: window.filter
          accessibleName: "Show"
          onActivated: index => window.filter = index
        }

        Item { Layout.fillWidth: true }

        Label {
          text: window.selected ? window.selected.name : ""
          font.weight: Font.Bold
          elide: Text.ElideRight
          Layout.maximumWidth: 320
        }
      }

      // --- Carousel ---------------------------------------------------------------------------
      ListView {
        id: carousel
        Layout.fillWidth: true
        implicitHeight: 150
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        model: window.walls
        highlightRangeMode: ListView.StrictlyEnforceRange
        preferredHighlightBegin: (width - 192) / 2
        preferredHighlightEnd: (width + 192) / 2
        highlightMoveDuration: Theme.anim.stack
        boundsBehavior: Flickable.StopAtBounds
        interactive: false
        cacheBuffer: 1200

        Accessible.role: Accessible.List
        Accessible.name: "Wallpapers"

        delegate: Item {
          id: wall
          required property var modelData
          required property int index
          readonly property bool current: ListView.isCurrentItem
          readonly property bool inUse: modelData.path === Wallpapers.currentPath
          readonly property bool favourite: Wallpapers.isFavorite(modelData.path)
          readonly property int distance: Math.abs(index - carousel.currentIndex)

          width: 192
          height: carousel.height
          opacity: distance > 3 ? 0.35 : distance >= 2 ? 0.65 : 1

          Accessible.role: Accessible.RadioButton
          Accessible.name: modelData.name + (inUse ? ", in use" : "") + (favourite ? ", favourite" : "")
          Accessible.checked: current

          Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

          Rectangle {
            id: frame
            anchors.horizontalCenter: parent.horizontalCenter
            y: 10
            width: 192
            height: 108
            radius: 14
            color: Theme.surface
            border.width: wall.current ? 2 : 0
            border.color: Theme.accent
            scale: wall.current ? 1.06 : 1
            clip: true

            Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

            // The small thumbnail when it's there, otherwise the image itself
            Image {
              id: image
              anchors.fill: parent
              anchors.margins: wall.current ? 2 : 0
              source: "file://" + wall.modelData.thumb
              sourceSize.width: 384
              sourceSize.height: 216
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: true
              onStatusChanged: {
                if (status === Image.Error && source.toString().endsWith(".jpg") && source.toString().indexOf("/.cache/") >= 0) {
                  source = "file://" + wall.modelData.path;
                }
              }
            }

            Rectangle {
              visible: wall.favourite
              anchors.left: parent.left
              anchors.top: parent.top
              anchors.margins: 6
              width: 22
              height: 22
              radius: 11
              color: Theme.alpha(Theme.crust, 0.7)
              Icon { anchors.centerIn: parent; name: "star"; size: 12; color: Theme.warn }
            }

            Rectangle {
              visible: wall.inUse
              anchors.right: parent.right
              anchors.top: parent.top
              anchors.margins: 6
              implicitWidth: inUseLabel.implicitWidth + 14
              implicitHeight: 20
              radius: 10
              color: Theme.accent
              Label { id: inUseLabel; anchors.centerIn: parent; text: "In use"; color: Theme.onAccent; font.pixelSize: Theme.font.label; font.weight: Font.Bold }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (wall.current) window.keep();
                else window.pick(wall.modelData.path);
              }
            }
          }

          Label {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: frame.bottom
            anchors.topMargin: 8
            width: 186
            horizontalAlignment: Text.AlignHCenter
            text: wall.modelData.name
            elide: Text.ElideRight
            font.pixelSize: Theme.font.small
            font.weight: wall.current ? Font.Bold : Font.Normal
          }
        }

        Label {
          visible: window.walls.length === 0
          anchors.centerIn: parent
          text: !Wallpapers.available ? "Wallpapers need awww (or swww)"
              : Wallpapers.items.length === 0 ? "No images in ~/Pictures/wallpapers"
              : window.filter === 1 ? "No favourites yet · Ctrl + F marks one" : "Nothing matches"
          kind: "muted"
        }
      }

      // --- How it's shown ------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 18

        Option {
          title: "Screen"
          labels: ["All"].concat(Quickshell.screens.map(s => s.name))
          current: Math.max(0, ["", ...Quickshell.screens.map(s => s.name)].indexOf(Wallpapers.output))
          onPicked: index => Wallpapers.output = index === 0 ? "" : Quickshell.screens[index - 1].name
        }
        Option {
          title: "Fit"
          labels: ["Fill", "Fit"]
          current: Wallpapers.fit === "fit" ? 1 : 0
          onPicked: index => Wallpapers.fit = index === 1 ? "fit" : "crop"
        }
        Option {
          title: "Transition"
          labels: ["Fade", "Wipe", "Grow"]
          current: Math.max(0, ["fade", "wipe", "grow"].indexOf(Wallpapers.transition))
          onPicked: index => Wallpapers.transition = ["fade", "wipe", "grow"][index]
        }

        Item { Layout.fillWidth: true }

        Label { text: "Change every 30 min"; font.pixelSize: Theme.font.small }
        Toggle {
          checked: Wallpapers.rotate
          accessibleName: "Change every 30 minutes"
          onToggled: value => Wallpapers.rotate = value
        }
      }

      // --- Keys ---------------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 14

        Row { spacing: 6; Kbd { text: "← →" } Label { text: "browse, live preview"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Ctrl + F" } Label { text: "favourite"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Ctrl + R" } Label { text: "random"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Enter" } Label { text: "apply"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Esc" } Label { text: "back"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Item { Layout.fillWidth: true }
        Button {
          text: "Apply"
          variant: "primary"
          size: Theme.size.buttonList
          onClicked: {
            if (window.selected) Wallpapers.set(window.selected.path);
            Wallpapers.open = false;
          }
        }
      }
    }
  }
}
