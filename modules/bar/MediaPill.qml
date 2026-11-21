// MediaPill.qml
// What's playing: title · artist. Only visible while a player is active.
// Click: the media menu. Middle click: play/pause. Right click: next.
// Scroll: the player's volume. Follows the player chosen in the media menu.
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import "../../config"
import "../../components"
import "../../services"

BarItem {
  id: root

  required property ShellScreen screen

  readonly property MprisPlayer player: Media.player

  visible: player !== null && player.trackTitle !== ""
  active: Media.open && Media.screen === screen
  accessibleName: player ? "Media: " + player.trackTitle + " by " + player.trackArtist + (player.isPlaying ? ", playing" : ", paused") : ""

  onClicked: mouse => {
    if (!player) return;
    if (mouse.button === Qt.RightButton) {
      if (player.canGoNext) player.next();
    } else if (mouse.button === Qt.MiddleButton) {
      if (player.canTogglePlaying) player.togglePlaying();
    } else {
      Media.toggle(root.screen, root.mapToItem(null, 0, 0).x);
    }
  }
  onScrolled: wheel => {
    if (player && player.volumeSupported) {
      player.volume = Math.max(0, Math.min(1, player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
    }
  }

  // The cover, else the app's icon, else a note; dimmed while paused
  Item {
    readonly property string appIcon: Media.iconOf(root.player)
    readonly property bool playing: root.player?.isPlaying ?? false
    width: 18
    height: 18
    anchors.verticalCenter: parent.verticalCenter
    opacity: playing ? 1 : 0.55

    ClippingRectangle {
      id: cover
      anchors.fill: parent
      radius: 5
      color: "transparent"
      visible: coverImage.status === Image.Ready
      Image {
        id: coverImage
        anchors.fill: parent
        source: root.player?.trackArtUrl ?? ""
        sourceSize: Qt.size(36, 36)
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
      }
    }
    IconImage {
      anchors.fill: parent
      visible: !cover.visible && parent.appIcon !== ""
      source: parent.appIcon !== "" ? Quickshell.iconPath(parent.appIcon, true) : ""
    }
    Icon {
      anchors.centerIn: parent
      visible: !cover.visible && parent.appIcon === ""
      name: parent.playing ? "music" : "pause"
      size: 14
      color: Theme.accent
    }
  }

  Label {
    text: root.player ? root.player.trackTitle : ""
    width: Math.min(implicitWidth, 220)
    elide: Text.ElideRight
    anchors.verticalCenter: parent.verticalCenter
  }

  // The artist (or channel), dimmer, when the player tells it
  Label {
    visible: text !== ""
    text: root.player ? root.player.trackArtist : ""
    kind: "muted"
    width: Math.min(implicitWidth, 160)
    elide: Text.ElideRight
    anchors.verticalCenter: parent.verticalCenter
  }
}
