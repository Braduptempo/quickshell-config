// Lock.qml
// The lock screen's state. modules/lock/LockScreen.qml draws it.
//   Lock.lock()       lock now (Super + L, `qs ipc call lock lock`)
//   Lock.suspend()    lock, then suspend
// Locks by itself after Config.lock.idleMinutes without input; caffeine
// (an idle inhibitor) keeps it unlocked.
//
// The password is checked with PAM using the system's "login" config, the
// same as a TTY login. Its rules apply here too: with pam_faillock, a few
// wrong passwords in a row lock the account for a while.
//
// For development:
//   `qs ipc call lock preview`  shows the lock screen in a normal window,
//                               without locking and without PAM ("demo" unlocks)
//   QS_LOCK_TEST=1              really locks, but unlocks by itself after 20 s
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../config"

Singleton {
  id: root

  property bool locked: false
  property bool preview: false
  readonly property bool shown: locked || preview
  property date lockedAt: new Date()

  // "rest" (clock only), "input", "checking", "wrong", "ok"
  property string state: "rest"
  // Text from PAM, e.g. why the account is locked
  property string message: ""
  // Raised on every wrong password, so the field can shake
  property int failures: 0
  // The password as typed, shared by every monitor; cleared on lock and unlock
  property string typed: ""
  // Show the password instead of dots
  property bool reveal: false

  readonly property bool testMode: Quickshell.env("QS_LOCK_TEST") === "1"

  function lock(): void {
    if (locked) return;
    reset();
    lockedAt = new Date();
    locked = true;
    refreshKeyboard();
  }

  function suspend(): void {
    lock();
    suspendDelay.restart();
  }

  // Give the lock surface a moment to show before the machine sleeps
  Timer {
    id: suspendDelay
    interval: 600
    onTriggered: Quickshell.execDetached(["systemctl", "suspend"])
  }

  function showPreview(): void {
    reset();
    lockedAt = new Date();
    preview = !preview;
    refreshKeyboard();
  }

  function reset(): void {
    if (pam.active) pam.abort();
    state = "rest";
    message = "";
    typed = "";
    reveal = false;
  }

  // Back to the clock after a while without typing
  function wake(): void {
    if (state === "rest") state = "input";
    restTimer.restart();
    refreshKeyboard();
  }

  Timer {
    id: restTimer
    interval: 30000
    onTriggered: {
      if (root.state !== "input" && root.state !== "wrong") return;
      root.state = "rest";
      root.typed = "";
    }
  }

  // --- Checking the password -----------------------------------------------------
  property string pending: ""

  function submit(password: string): void {
    if (password === "" || state === "checking" || state === "ok") return;
    restTimer.restart();
    state = "checking";
    message = "";
    if (preview) {
      previewCheck.password = password;
      previewCheck.restart();
      return;
    }
    pending = password;
    pam.start();
  }

  PamContext {
    id: pam

    onPamMessage: {
      if (pam.responseRequired) {
        pam.respond(root.pending);
        root.pending = "";
      } else if (pam.messageIsError) {
        root.message = pam.message;
      }
    }

    onCompleted: result => {
      root.pending = "";
      if (result === PamResult.Success) {
        root.succeeded();
      } else {
        if (result === PamResult.MaxTries) root.message = "Too many attempts, wait a moment";
        root.failed();
      }
    }

    onError: {
      root.pending = "";
      root.message = "Could not check the password";
      root.failed();
    }
  }

  // Preview: never asks PAM, "demo" is the password
  Timer {
    id: previewCheck
    property string password: ""
    interval: 500
    onTriggered: {
      if (password === "demo") root.succeeded();
      else root.failed();
      password = "";
    }
  }

  function failed(): void {
    state = "wrong";
    failures++;
  }

  function succeeded(): void {
    state = "ok";
    unlockDelay.restart();
  }

  // Shows "Welcome back" briefly, then unlocks
  Timer {
    id: unlockDelay
    interval: 700
    onTriggered: {
      root.locked = false;
      root.preview = false;
      root.reset();
    }
  }

  Timer {
    running: root.testMode && root.locked
    interval: 20000
    onTriggered: root.locked = false
  }

  // --- Idle ----------------------------------------------------------------------
  IdleMonitor {
    enabled: Config.lock.idleMinutes > 0 && !root.locked
    timeout: Math.max(1, Config.lock.idleMinutes) * 60
    respectInhibitors: true
    onIsIdleChanged: if (isIdle) root.lock()
  }

  // --- Who is logged in ------------------------------------------------------------
  readonly property string userName: Quickshell.env("USER") ?? ""
  property string displayName: userName.charAt(0).toUpperCase() + userName.slice(1)
  property string avatar: ""

  Process {
    running: true
    command: ["sh", "-c", "getent passwd \"$USER\" | cut -d: -f5 | cut -d, -f1; for f in \"$HOME/.face\" \"/var/lib/AccountsService/icons/$USER\"; do [ -f \"$f\" ] && echo \"$f\" && break; done"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n");
        if ((lines[0] ?? "").trim() !== "") root.displayName = lines[0].trim();
        if ((lines[1] ?? "").trim() !== "") root.avatar = "file://" + lines[1].trim();
      }
    }
  }

  // --- Wallpaper (awww / swww), per output -----------------------------------------
  property var wallpapers: ({})

  Process {
    id: wallpaperProc
    command: ["sh", "-c", "(awww query || swww query) 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const map = {};
        for (const line of text.split("\n")) {
          const m = line.match(/^:?\s*([^:]+):.*image:\s*(.+)$/);
          if (m) map[m[1].trim()] = "file://" + m[2].trim();
        }
        root.wallpapers = map;
      }
    }
  }

  onShownChanged: if (shown) wallpaperProc.running = true

  // --- Keyboard: layout and Caps Lock ------------------------------------------------
  property string layout: ""
  property string keyboard: ""
  property bool capsLock: false

  function refreshKeyboard(): void {
    keyboardProc.running = true;
  }

  function nextLayout(): void {
    if (keyboard === "") return;
    Quickshell.execDetached(["sh", "-c", "hyprctl switchxkblayout \"$1\" next", "sh", keyboard]);
    keyboardDelay.restart();
  }

  Timer {
    id: keyboardDelay
    interval: 150
    onTriggered: root.refreshKeyboard()
  }

  Process {
    id: keyboardProc
    command: ["hyprctl", "devices", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        let keyboards = [];
        try {
          keyboards = JSON.parse(text).keyboards ?? [];
        } catch (e) {
          return;
        }
        const main = keyboards.find(k => k.main) ?? keyboards[0];
        if (!main) return;
        root.keyboard = main.name;
        root.capsLock = main.capsLock;
        // "English (US)" -> "US", "Dutch" -> "DU"
        const keymap = main.active_keymap ?? "";
        const inner = keymap.match(/\(([^)]+)\)/);
        root.layout = (inner ? inner[1] : keymap.slice(0, 2)).toUpperCase();
      }
    }
  }

  // Caps Lock: read it again a moment after the key. The Caps Lock bind
  // (`qs ipc call osd caps`) calls this too, so Lock.capsLock is always
  // current for the bar and every password field
  function capsChanged(): void {
    keyboardDelay.restart();
  }

  Component.onCompleted: refreshKeyboard()
}
