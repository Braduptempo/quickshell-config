// VideoWallpaper.qml
// A video as wallpaper, played by the shell (Qt Multimedia, FFmpeg): one
// window per screen that has a video in Wallpapers.videos, under all other
// windows, muted and looping. It pauses when nobody can see it: a fullscreen
// window on that screen, the lock screen, and (Settings → Wallpaper) on
// battery. Clicks go straight through to the desktop. The player itself is
// VideoPlayer.qml, loaded only when needed (so a missing qt6-multimedia only
// costs the video wallpapers).
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../services"
import "../../widgets/battery"

Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property ShellScreen modelData
    readonly property string file: Wallpapers.videoFor(modelData.name)
    readonly property bool hidden: Lock.locked
      || (Hyprland.monitorFor(modelData)?.activeWorkspace?.hasFullscreen ?? false)
      || (Config.appearance.videoPauseOnBattery && Battery.hasBattery && !Battery.charging)

    screen: modelData
    visible: file !== ""
    color: "black"

    // Not "quickshell…": the glass blur rule shouldn't blur behind a video
    WlrLayershell.namespace: "qs-video-wallpaper"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    mask: Region {}

    // Qt Multimedia only gets loaded here, when there is a video
    Loader {
      anchors.fill: parent
      active: window.file !== ""
      source: "VideoPlayer.qml"
      onLoaded: {
        item["file"] = Qt.binding(() => window.file);
        item["crop"] = Qt.binding(() => Wallpapers.fit !== "fit");
        item["paused"] = Qt.binding(() => window.hidden);
      }
    }
  }
}
