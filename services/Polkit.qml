// Polkit.qml
// The polkit agent: when an app asks for administrator rights (pkexec,
// installing from a store, mounting a disk, changing system settings), the
// shell asks for your password. modules/polkit/PolkitDialog.qml draws it.
//
// Only one agent can run per session. If another one (polkit-gnome,
// hyprpolkitagent…) is started first, this one stays inactive; `registered`
// tells which.
//
// For development: `qs ipc call polkit preview` shows the dialog with a made-up
// request ("demo" is the password); nothing is asked of polkit.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Polkit

Singleton {
  id: root

  readonly property bool registered: agent.isRegistered
  readonly property var flow: agent.flow
  property bool preview: false

  readonly property bool shown: preview || (flow ? !flow.isCompleted : false) || state === "ok" || state === "cancelled"

  // "ask", "checking", "wrong", "ok" (shown briefly), "cancelled" (shown briefly)
  property string state: "ask"
  property int failures: 0

  // What the request is about
  readonly property string message: preview ? "\"Updates\" wants to install 12 package updates. This changes system files."
                                    : flow?.message ?? ""
  readonly property string actionId: preview ? "org.freedesktop.policykit.exec" : flow?.actionId ?? ""
  readonly property string prompt: preview ? "Password: " : flow?.inputPrompt ?? ""
  readonly property bool echo: preview ? false : flow?.responseVisible ?? false
  // Extra text from polkit or PAM, e.g. "Sorry, try again."
  readonly property string note: preview ? "" : flow?.supplementaryMessage ?? ""
  readonly property bool noteIsError: preview ? false : flow?.supplementaryIsError ?? false
  readonly property bool needsInput: preview ? state !== "ok" && state !== "cancelled" : flow?.isResponseRequired ?? false

  PolkitAgent {
    id: agent

    onAuthenticationRequestStarted: {
      root.state = "ask";
      root.failures = 0;
    }
  }

  Connections {
    target: root.flow
    ignoreUnknownSignals: true

    function onAuthenticationFailed() {
      root.state = "wrong";
      root.failures++;
    }
    function onAuthenticationSucceeded() {
      root.finish("ok");
    }
    function onAuthenticationRequestCancelled() {
      root.finish("cancelled");
    }
    function onIsResponseRequiredChanged() {
      // Ready for the next try after a wrong password
      if (root.flow && root.flow.isResponseRequired && root.state === "checking") root.state = "ask";
    }
  }

  function submit(password: string): void {
    if (password === "" || state === "checking") return;
    state = "checking";
    if (preview) {
      previewCheck.password = password;
      previewCheck.restart();
    } else if (flow) {
      flow.submit(password);
    }
  }

  function cancel(): void {
    if (preview) finish("cancelled");
    else if (flow) flow.cancelAuthenticationRequest();
  }

  function showPreview(): void {
    state = "ask";
    failures = 0;
    preview = true;
  }

  // Shows "Authenticated" or "Cancelled" for a moment, then closes
  function finish(result: string): void {
    state = result;
    closeTimer.restart();
  }

  Timer {
    id: closeTimer
    interval: 700
    onTriggered: {
      root.preview = false;
      root.state = "ask";
    }
  }

  Timer {
    id: previewCheck
    property string password: ""
    interval: 500
    onTriggered: {
      if (password === "demo") {
        root.finish("ok");
      } else {
        root.state = "wrong";
        root.failures++;
      }
      password = "";
    }
  }
}
