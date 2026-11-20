// Windows.qml
// Open windows for the Alt + Tab switcher and the workspace overview.
// The list comes from `hyprctl clients` (most recently used first, with
// workspace and size) and is read again when windows open, close, move or
// get focus. Previews and actions use the window's Wayland handle
// (HyprlandToplevel.wayland): ScreencopyView shows it, activate() focuses
// it (and its workspace), close() closes it.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
  id: root

  // [{ address, title, app, workspace, x, y, width, height, floating, monitor }]
  property var windows: []

  // --- Switcher state ---------------------------------------------------------------
  property bool switcherOpen: false
  property int switcherIndex: 0
  // false: every workspace, true: only the current one
  property bool switcherCurrentOnly: false
  readonly property var switcherList: switcherCurrentOnly
    ? windows.filter(w => w.workspace === (Hyprland.focusedWorkspace?.id ?? -1)) : windows

  // --- Overview state -----------------------------------------------------------------
  property bool overviewOpen: false
  property ShellScreen screen: null

  function refresh(): void {
    clients.running = true;
  }

  Component.onCompleted: refresh()

  Connections {
    target: Hyprland
    function onRawEvent(event: HyprlandEvent): void {
      if (/^(openwindow|closewindow|movewindow|activewindowv2|windowtitle|changefloatingmode)/.test(event.name)) refreshDelay.restart();
    }
  }

  Timer {
    id: refreshDelay
    interval: 120
    onTriggered: root.refresh()
  }

  Process {
    id: clients
    command: ["hyprctl", "clients", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        let list = [];
        try {
          list = JSON.parse(text);
        } catch (e) {
          return;
        }
        root.windows = list
          .filter(c => c.mapped && !c.hidden && c.workspace && c.workspace.id > 0)
          .sort((a, b) => a.focusHistoryID - b.focusHistoryID)
          .map(c => ({
            address: c.address,
            title: c.title || c.initialTitle || c.class,
            app: c.initialClass || c.class || "App",
            workspace: c.workspace.id,
            x: c.at[0], y: c.at[1], width: c.size[0], height: c.size[1],
            floating: c.floating,
            monitor: c.monitor
          }));
      }
    }
  }

  // The live Hyprland object for an address, for previews and actions
  function toplevel(address: string): var {
    const bare = address.replace(/^0x/, "");
    return Hyprland.toplevels.values.find(t => t.address === address || t.address === bare || ("0x" + t.address) === address) ?? null;
  }

  function focus(address: string): void {
    const t = toplevel(address);
    if (t && t.wayland) t.wayland.activate();
    else Hypr.run("hl.dsp.focus({ window = \"address:" + address + "\" })", "focuswindow address:" + address);
  }

  function close(address: string): void {
    const t = toplevel(address);
    if (t && t.wayland) t.wayland.close();
    refreshDelay.restart();
  }

  // Focuses the window, then moves it (Hyprland moves the active window)
  function moveTo(address: string, workspace: int): void {
    focus(address);
    moveDelay.workspace = workspace;
    moveDelay.restart();
  }

  Timer {
    id: moveDelay
    property int workspace: 1
    interval: 120
    onTriggered: {
      Hypr.windowToWorkspace(workspace);
      root.refresh();
    }
  }

  // "firefox" -> "Firefox", "org.gnome.Nautilus" -> "Nautilus"
  function appName(app: string): string {
    const entry = DesktopEntries.heuristicLookup(app);
    if (entry) return entry.name;
    const last = app.split(".").pop();
    return last.charAt(0).toUpperCase() + last.slice(1);
  }

  function appIcon(app: string): string {
    const entry = DesktopEntries.heuristicLookup(app);
    return entry ? entry.icon : app.toLowerCase();
  }

  // --- Switcher -------------------------------------------------------------------------
  // Alt + Tab: open on the second window (the one you came from), or step on
  function switcherStep(step: int): void {
    if (!switcherOpen) {
      refresh();
      switcherIndex = switcherList.length > 1 ? (step > 0 ? 1 : switcherList.length - 1) : 0;
      switcherOpen = true;
      return;
    }
    const n = switcherList.length;
    if (n > 0) switcherIndex = (switcherIndex + step + n) % n;
  }

  // Alt released: go there
  function switcherCommit(): void {
    if (!switcherOpen) return;
    const w = switcherList[switcherIndex];
    switcherOpen = false;
    if (w) focus(w.address);
  }

  function switcherCancel(): void {
    switcherOpen = false;
  }

  function toggleOverview(onScreen: ShellScreen): void {
    if (overviewOpen) {
      overviewOpen = false;
    } else {
      refresh();
      screen = onScreen;
      overviewOpen = true;
    }
  }
}
