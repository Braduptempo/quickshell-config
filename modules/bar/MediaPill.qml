// MediaPill.qml
// What's playing. Only visible while a player is active.
// Left: play/pause (the media menu comes later), right: next, scroll: volume.
import QtQuick
import Quickshell.Services.Mpris
import "../../config"
import "../../components"

BarItem {
  id: root

  // Prefer the player that is playing, otherwise the first one
  readonly property MprisPlayer player: {
    const players = Mpris.players.values;
    for (let i = 0; i < players.length; i++) {
      if (players[i].isPlaying) return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }

  visible: player !== null && player.trackTitle !== ""
  accessibleName: player ? "Media: " + player.trackTitle + " by " + player.trackArtist + (player.isPlaying ? ", playing" : ", paused") : ""

  onClicked: mouse => {
    if (!player) return;
    if (mouse.button === Qt.RightButton && player.canGoNext) player.next();
    else if (player.canTogglePlaying) player.togglePlaying();
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
    anchors.verticalCenter: parent.verticalCenter
  }
}
