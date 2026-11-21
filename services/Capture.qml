// Capture.qml
// Screenshots and screen recording. The work is done by scripts/capture.sh
// (grim + slurp, gpu-screen-recorder); this keeps the toolbar's choices and
// follows a running recording.
//   Capture.toggle(screen)    the toolbar (Print, or Super + Shift + R)
//   Capture.shoot("region")   a screenshot with the saved options
//   Capture.stop() / pause()  the recording
// A recording keeps running when the shell reloads: its state is a file in
// $XDG_RUNTIME_DIR.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  property double closedAt: 0

  onOpenChanged: if (!open) closedAt = Date.now()

  function toggle(onScreen: ShellScreen): void {
    if (open) {
      open = false;
    } else if (Date.now() - closedAt > 250) {
      screen = onScreen;
      open = true;
    }
  }

  readonly property string script: Quickshell.shellPath("scripts/capture.sh")

  // --- Saved choices -------------------------------------------------------------------
  FileView {
    path: Quickshell.statePath("capture.json")
    watchChanges: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: options
      // "region", "window" or "screen"
      property string target: "region"
      // "shot" or "record"
      property string mode: "shot"
      property bool delay: false
      property bool copy: true
      // Open the drawing editor right after a screenshot
      property bool edit: false
      property bool cursor: false
      property bool mic: false
      property bool audio: true
      property bool recordCursor: true
      property bool countdown: true
    }
  }

  property alias target: options.target
  property alias mode: options.mode
  property alias delay: options.delay
  property alias copy: options.copy
  property alias edit: options.edit
  property alias cursor: options.cursor
  property alias mic: options.mic
  property alias audio: options.audio
  property alias recordCursor: options.recordCursor
  property alias countdown: options.countdown

  property bool hasRecorder: false

  Process {
    running: true
    command: ["sh", "-c", "command -v gpu-screen-recorder >/dev/null && echo yes"]
    stdout: StdioCollector {
      onStreamFinished: root.hasRecorder = text.trim() === "yes"
    }
  }

  // --- Doing it --------------------------------------------------------------------------
  // The toolbar closes first, so it isn't in the picture
  function start(): void {
    open = false;
    startDelay.restart();
  }

  Timer {
    id: startDelay
    interval: 250
    onTriggered: {
      if (root.mode === "record") root.record(root.target);
      else root.shoot(root.target);
    }
  }

  function shoot(what: string): void {
    const args = [root.script, "shot", what];
    if (delay) args.push("--delay", "3");
    if (copy) args.push("--copy");
    if (cursor) args.push("--cursor");
    if (edit) args.push("--edit");
    Quickshell.execDetached(args);
  }

  function record(what: string): void {
    if (recording) return;
    const args = [root.script, "record", what];
    if (mic) args.push("--mic");
    if (audio) args.push("--audio");
    if (recordCursor) args.push("--cursor");
    if (countdown) args.push("--countdown");
    Quickshell.execDetached(args);
  }

  function stop(): void {
    Quickshell.execDetached([root.script, "stop"]);
  }

  function pause(): void {
    Quickshell.execDetached([root.script, "pause"]);
  }

  // --- A running recording -----------------------------------------------------------------
  property bool recording: false
  property bool paused: false
  property double startedAt: 0
  // Finished pauses, in seconds, and when the current pause began
  property int pausedTotal: 0
  property double pausedAt: 0
  property int elapsed: 0

  FileView {
    id: stateFile
    path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-recording"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseState(text())
    onLoadFailed: root.parseState("")
  }

  function parseState(text: string): void {
    // pid start paused pausedAt pausedTotal file
    const parts = text.trim().split(" ");
    if (parts.length < 6) {
      recording = false;
      paused = false;
      return;
    }
    startedAt = parseInt(parts[1]) * 1000;
    paused = parts[2] === "1";
    pausedAt = parseInt(parts[3]) * 1000;
    pausedTotal = parseInt(parts[4]);
    recording = true;
    tick();
  }

  function tick(): void {
    const now = Date.now();
    const pausing = paused ? (now - pausedAt) / 1000 : 0;
    elapsed = Math.max(0, Math.floor((now - startedAt) / 1000 - pausedTotal - pausing));
  }

  // Counts up, and notices when the recorder stopped by itself
  Timer {
    running: root.recording
    interval: 1000
    repeat: true
    onTriggered: {
      root.tick();
      statusCheck.running = true;
    }
  }

  Process {
    id: statusCheck
    command: [root.script, "status"]
    stdout: StdioCollector {
      onStreamFinished: if (text.trim() === "idle") root.parseState("")
    }
  }

  // Start the file watch again when the recording starts after a reload
  Timer {
    running: !root.recording
    interval: 2000
    repeat: true
    onTriggered: stateFile.reload()
  }

  // "2:14"
  readonly property string elapsedText: Math.floor(elapsed / 60) + ":" + String(elapsed % 60).padStart(2, "0")
}
