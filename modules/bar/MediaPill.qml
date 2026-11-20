// MediaPill.qml
// What's playing. Only visible while a player is active.
// Click: the media menu. Middle click: play/pause. Right click: next.
// Scroll: the player's volume. Follows the player chosen in the media menu.
import QtQuick
import Quickshell
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

  Icon {
    name: root.player && root.player.isPlaying ? "music" : "pause"
    size: 14
    color: Theme.accent
    anchors.verticalCenter: parent.verticalCenter
  }

  Label {
    text: root.player ? root.player.trackTitle : ""
    width: Math.min(implicitWidth, 220)
    elide: Text.ElideRight
    anchors.verticalCenter: parent.verticalCenter
  }
}
