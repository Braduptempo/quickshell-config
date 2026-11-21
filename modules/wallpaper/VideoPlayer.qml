// VideoPlayer.qml
// The video itself, for VideoWallpaper.qml. In its own file, loaded with a
// Loader: without Qt Multimedia (qt6-multimedia) only video wallpapers are
// missing, the rest of the shell loads as usual.
import QtQuick
import QtMultimedia
import "../../config"

Item {
  id: root

  property string file: ""
  property bool crop: true
  property bool paused: false

  // readonly: whether a frame is on screen (the window stays see-through
  // until then, so the still under it shows instead of black)
  readonly property bool showing: video.playbackState !== MediaPlayer.StoppedState && video.hasVideo

  onPausedChanged: paused ? video.pause() : video.play()
  onFileChanged: start()
  Component.onCompleted: start()

  // autoPlay only works when the player is made; a file chosen later (the
  // picker) has to be set and started by hand, after the binding settles
  function start(): void {
    Qt.callLater(() => {
      if (root.file === "") {
        video.stop();
        return;
      }
      const url = "file://" + root.file;
      if (video.source.toString() !== url) video.source = url;
      if (!root.paused) video.play();
    });
  }

  Video {
    id: video
    anchors.fill: parent
    loops: MediaPlayer.Infinite
    muted: true
    fillMode: root.crop ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
    opacity: root.showing ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.anim.wallpaper } }
  }
}
