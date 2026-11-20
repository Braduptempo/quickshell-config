// Privacy.qml
// What's using the microphone, the camera or the screen right now:
// microphone and screen sharing from PipeWire streams, the camera from
// whoever has a /dev/video* device open (fuser, checked every few seconds).
// The bar shows a pill while anything is in use; also a screen recording.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property var nodes: Pipewire.nodes.values

  function appOf(node: PwNode): string {
    const p = node.properties;
    return p["application.name"] || p["node.description"] || p["node.name"] || "An app";
  }

  // Apps recording sound (not the shell's own splitters and monitors)
  readonly property var micApps: [...new Set(nodes.filter(n => n.properties["media.class"] === "Stream/Input/Audio").map(appOf))]
  // Apps receiving a screen-cast stream (browsers, OBS, Discord…)
  readonly property var screenApps: [...new Set(nodes.filter(n => n.properties["media.class"] === "Stream/Input/Video").map(appOf))]
  property var cameraApps: []

  readonly property bool micInUse: micApps.length > 0
  readonly property bool screenInUse: screenApps.length > 0 || Capture.recording
  readonly property bool cameraInUse: cameraApps.length > 0
  readonly property bool anyInUse: micInUse || screenInUse || cameraInUse

  // When each one started, for "Microphone · 42 min"
  property double micSince: 0
  property double screenSince: 0
  property double cameraSince: 0
  onMicInUseChanged: micSince = micInUse ? Date.now() : 0
  onScreenInUseChanged: screenSince = screenInUse ? Date.now() : 0
  onCameraInUseChanged: cameraSince = cameraInUse ? Date.now() : 0

  function since(ms: real): string {
    if (!ms) return "";
    const min = Math.floor((Date.now() - ms) / 60000);
    return min < 1 ? "just now" : min < 60 ? min + " min" : Math.floor(min / 60) + " h " + (min % 60) + " min";
  }

  // --- Camera ---------------------------------------------------------------------------
  Timer {
    interval: 4000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: camera.running = true
  }

  Process {
    id: camera
    // Process names that have a video device open
    command: ["sh", "-c", "ls /dev/video* >/dev/null 2>&1 || exit 0; for p in $(fuser /dev/video* 2>/dev/null); do cat /proc/$p/comm 2>/dev/null; done | sort -u"]
    stdout: StdioCollector {
      onStreamFinished: {
        const apps = text.split("\n").filter(a => a !== "" && a !== "pipewire" && a !== "wireplumber");
        if (JSON.stringify(apps) !== JSON.stringify(root.cameraApps)) root.cameraApps = apps;
      }
    }
  }
}
