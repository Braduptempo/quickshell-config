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

  onPausedChanged: paused ? video.pause() : video.play()
  onFileChanged: if (file !== "" && !paused) video.play()

  Video {
    id: video
    anchors.fill: parent
    source: root.file !== "" ? "file://" + root.file : ""
    loops: MediaPlayer.Infinite
    muted: true
    fillMode: root.crop ? VideoOutput.PreserveAspectCrop : VideoOutput.PreserveAspectFit
    autoPlay: !root.paused
    opacity: video.playbackState === MediaPlayer.StoppedState ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: Theme.anim.wallpaper } }
  }
}
