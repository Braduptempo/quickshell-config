// MediaMenu.qml
// The media menu below the media pill: album art, seek, shuffle and repeat,
// the player's own volume, the audio output and which player to control.
// Space plays/pauses, ← → seek 5 s, Esc closes.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/sound"

PanelWindow {
  id: window

  readonly property bool shown: Media.open && Media.player !== null
  readonly property string style: Config.animations.panelStyle
  readonly property MprisPlayer player: Media.player

  screen: Media.screen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-media"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  // Opens from the bar: at the top, or at the bottom when the bar is there
  readonly property bool fromBottom: Config.bar.position === "bottom"

  anchors {
    top: !window.fromBottom
    bottom: window.fromBottom
    left: true
  }
  margins {
    top: 6
    bottom: 6
    left: Math.max(0, Media.anchorX - 12)
  }
  implicitWidth: 400 + 24
  implicitHeight: card.implicitHeight + 24

  // The player went away while open
  onShownChanged: if (!shown) Media.open = false

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Media.open = false
  }

  // Mpris doesn't push the position; ask for it while visible
  Timer {
    running: window.shown && window.player !== null && window.player.isPlaying
    interval: 500
    repeat: true
    onTriggered: window.player.positionChanged()
  }

  function seekBy(seconds: real): void {
    if (!player || !player.canSeek) return;
    player.position = Math.max(0, Math.min(player.length, player.position + seconds));
  }

  GlassPanel {
    id: card

    x: 12
    width: 400
    implicitHeight: column.implicitHeight + 24
    height: implicitHeight
    transformOrigin: window.fromBottom ? Item.BottomLeft : Item.TopLeft
    focus: true
    clip: true

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.92

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: window.shown ? Theme.anim.emphasized : Theme.anim.accelerate } }
    Behavior on y { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard } }

    Accessible.role: Accessible.Pane
    Accessible.name: "Media player"

    Keys.onEscapePressed: Media.open = false
    Keys.onSpacePressed: if (window.player?.canTogglePlaying) window.player.togglePlaying()
    Keys.onLeftPressed: window.seekBy(-5)
    Keys.onRightPressed: window.seekBy(5)

    ColumnLayout {
      id: column
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 12

      // --- Album art and the track ------------------------------------------------------
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 144
        radius: 14
        color: Theme.alpha(Theme.crust, 0.35)
        clip: true

        // Glow in the colours of the album art
        MultiEffect {
          width: 260
          height: 260
          x: parent.width - 180
          y: -40
          source: art
          visible: art.status === Image.Ready
          blurEnabled: true
          blurMax: 64
          blur: 1
          opacity: 0.45
        }

        RowLayout {
          anchors.fill: parent
          anchors.margins: 14
          spacing: 14

          Rectangle {
            implicitWidth: 116
            implicitHeight: 116
            radius: 16
            color: Theme.accent
            clip: true

            Icon { anchors.centerIn: parent; visible: art.status !== Image.Ready; name: "music"; size: 40; color: Theme.onAccent }

            Image {
              id: art
              anchors.fill: parent
              source: window.player ? window.player.trackArtUrl : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              visible: false
            }
            MultiEffect {
              anchors.fill: art
              source: art
              visible: art.status === Image.Ready
              maskEnabled: true
              maskSource: artMask
            }
            Rectangle { id: artMask; anchors.fill: art; radius: 16; visible: false; layer.enabled: true }
          }

          ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            // Where the sound goes
            Rectangle {
              visible: outputLabel.text !== ""
              implicitHeight: 22
              implicitWidth: Math.min(outputRow.implicitWidth + 18, parent.width)
              radius: Theme.pill(height)
              color: Theme.alpha(Theme.crust, 0.5)

              Row {
                id: outputRow
                anchors.verticalCenter: parent.verticalCenter
                x: 9
                spacing: 6
                Icon { name: "headphones"; size: 11; color: Theme.subtext; anchors.verticalCenter: parent.verticalCenter }
                Label {
                  id: outputLabel
                  text: Sound.defaultSink?.description ?? ""
                  kind: "muted"
                  font.pixelSize: Theme.font.label
                  elide: Text.ElideRight
                  width: Math.min(implicitWidth, 190)
                  anchors.verticalCenter: parent.verticalCenter
                }
              }
            }

            Label {
              Layout.fillWidth: true
              Layout.topMargin: 6
              text: window.player?.trackTitle || "Nothing playing"
              font.pixelSize: Theme.font.title + 3
              font.weight: Font.Bold
              elide: Text.ElideRight
            }
            Label {
              Layout.fillWidth: true
              visible: text !== ""
              text: window.player?.trackArtist ?? ""
              color: Theme.subtext
              elide: Text.ElideRight
            }
            Label {
              Layout.fillWidth: true
              visible: text !== ""
              text: window.player?.trackAlbum ?? ""
              kind: "muted"
              font.pixelSize: Theme.font.label
              elide: Text.ElideRight
            }

            Item { Layout.fillHeight: true }

            Button {
              visible: window.player?.canRaise ?? false
              text: "Open " + Media.nameOf(window.player)
              size: Theme.size.buttonRow
              variant: "ghost"
              onClicked: {
                window.player.raise();
                Media.open = false;
              }
            }
          }
        }
      }

      // --- Seek ------------------------------------------------------------------------------
      ColumnLayout {
        visible: (window.player?.lengthSupported ?? false) && (window.player?.length ?? 0) > 0
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        spacing: 6

        Item {
          id: seek
          Layout.fillWidth: true
          implicitHeight: 14
          readonly property real progress: window.player && window.player.length > 0
                                           ? Math.min(1, (dragging ? dragValue : window.player.position) / window.player.length) : 0
          property bool dragging: false
          property real dragValue: 0

          Accessible.role: Accessible.Slider
          Accessible.name: "Position"

          Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            radius: 2
            color: Theme.alpha(Theme.text, 0.15)

            Rectangle {
              width: parent.width * seek.progress
              height: parent.height
              radius: 2
              color: Theme.accent
            }
          }

          Rectangle {
            visible: window.player?.canSeek ?? false
            x: seek.width * seek.progress - width / 2
            anchors.verticalCenter: parent.verticalCenter
            width: seekMouse.containsMouse || seek.dragging ? 14 : 10
            height: width
            radius: width / 2
            color: Theme.text
            Behavior on width { NumberAnimation { duration: Theme.anim.fast } }
          }

          MouseArea {
            id: seekMouse
            anchors.fill: parent
            anchors.topMargin: -6
            anchors.bottomMargin: -6
            enabled: window.player?.canSeek ?? false
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            function valueAt(x: real): real {
              return Math.max(0, Math.min(1, x / width)) * window.player.length;
            }
            onPressed: mouse => {
              seek.dragging = true;
              seek.dragValue = valueAt(mouse.x);
            }
            onPositionChanged: mouse => {
              if (seek.dragging) seek.dragValue = valueAt(mouse.x);
            }
            onReleased: {
              window.player.position = seek.dragValue;
              seek.dragging = false;
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          Label { text: Media.formatTime(seek.dragging ? seek.dragValue : window.player?.position ?? 0); kind: "muted"; font.pixelSize: Theme.font.label }
          Item { Layout.fillWidth: true }
          Label { text: Media.formatTime(window.player?.length ?? 0); kind: "muted"; font.pixelSize: Theme.font.label }
        }
      }

      // --- Controls -------------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 6
        Layout.rightMargin: 6

        IconButton {
          size: 40
          icon: "shuffle"
          variant: "plain"
          checked: window.player?.shuffle ?? false
          visible: window.player?.shuffleSupported ?? false
          accessibleName: "Shuffle"
          onClicked: window.player.shuffle = !window.player.shuffle
        }
        Item { Layout.fillWidth: true }
        IconButton {
          size: 48
          icon: "previous"
          accessibleName: "Previous"
          onClicked: {
            // Back to the start first, like most players
            if (window.player.position > 5 && window.player.canSeek) window.player.position = 0;
            else window.player.previous();
          }
        }
        IconButton {
          size: 62
          icon: window.player?.isPlaying ? "pause" : "play"
          variant: "primary"
          accessibleName: window.player?.isPlaying ? "Pause" : "Play"
          onClicked: window.player.togglePlaying()
        }
        IconButton {
          size: 48
          icon: "next"
          accessibleName: "Next"
          onClicked: window.player.next()
        }
        Item { Layout.fillWidth: true }
        IconButton {
          size: 40
          icon: "repeat"
          variant: "plain"
          visible: window.player?.loopSupported ?? false
          checked: (window.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
          accessibleName: window.player?.loopState === MprisLoopState.Track ? "Repeat one"
                        : window.player?.loopState === MprisLoopState.Playlist ? "Repeat all" : "Repeat off"
          onClicked: {
            const state = window.player.loopState;
            window.player.loopState = state === MprisLoopState.None ? MprisLoopState.Playlist
                                    : state === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
          }

          // "1" while repeating one track
          Rectangle {
            visible: window.player?.loopState === MprisLoopState.Track
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 4
            width: 13
            height: 13
            radius: 7
            color: Theme.onAccent
            Label { anchors.centerIn: parent; text: "1"; font.pixelSize: 8; font.weight: Font.Bold; color: Theme.accent }
          }
        }
      }

      // --- The player's own volume ----------------------------------------------------------------
      PillSlider {
        visible: window.player?.volumeSupported ?? false
        Layout.fillWidth: true
        icon: "volume"
        label: Media.nameOf(window.player)
        value: window.player?.volume ?? 0
        // Players apply volume over D-Bus; too many steps make the sound stutter
        throttle: 80
        onMoved: value => window.player.volume = value
      }

      // --- Which player -------------------------------------------------------------------------------
      ColumnLayout {
        visible: Media.players.length > 1
        Layout.fillWidth: true
        spacing: 6

        Label { text: "Players"; kind: "label"; Layout.leftMargin: 4 }

        Repeater {
          model: Media.players

          Rectangle {
            id: playerRow
            required property MprisPlayer modelData
            readonly property bool current: modelData === window.player

            Layout.fillWidth: true
            implicitHeight: 42
            radius: Theme.pill(height)
            color: current ? Theme.alpha(Theme.accent, 0.14) : playerMouse.containsMouse ? Theme.item : "transparent"
            border.width: 1
            border.color: current ? Theme.accent : Theme.border

            Accessible.role: Accessible.RadioButton
            Accessible.name: Media.nameOf(modelData) + ", " + Media.stateOf(modelData)
            Accessible.checked: current

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 6
              anchors.rightMargin: 14
              spacing: 10

              Rectangle {
                implicitWidth: 30
                implicitHeight: 30
                radius: 15
                color: playerRow.current ? Theme.accent : Theme.overlay
                Label {
                  anchors.centerIn: parent
                  text: Media.nameOf(playerRow.modelData).charAt(0).toUpperCase()
                  font.weight: Font.Bold
                  color: playerRow.current ? Theme.onAccent : Theme.text
                }
              }
              ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Label { text: Media.nameOf(playerRow.modelData); font.weight: Font.Bold; font.pixelSize: Theme.font.small }
                Label {
                  Layout.fillWidth: true
                  text: Media.stateOf(playerRow.modelData)
                  kind: "muted"
                  font.pixelSize: Theme.font.label
                  elide: Text.ElideRight
                }
              }
              Icon {
                visible: playerRow.modelData.isPlaying
                name: "music"
                size: 13
                color: Theme.accent
              }
            }

            MouseArea {
              id: playerMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Media.pick(playerRow.modelData)
            }
          }
        }
      }
    }
  }
}
