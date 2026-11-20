// Panels.qml
// Which panel is open, and on which monitor. Bar buttons and IPC use this
// instead of reaching into each other's windows.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
  id: root

  property bool quickSettingsOpen: false
  // "main", "network" (alias "wifi"), "bluetooth" or "audio"
  property string quickSettingsPage: "main"
  property ShellScreen screen: null

  // Clicking the bar button while the panel is open first closes it via the
  // focus grab, then the click would open it again. Ignore re-opens right after.
  property double closedAt: 0

  function focusedScreen(): ShellScreen {
    const name = Hyprland.focusedMonitor?.name ?? "";
    for (const s of Quickshell.screens) {
      if (s.name === name) return s;
    }
    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
  }

  function openQuickSettings(onScreen: ShellScreen, page: string): void {
    screen = onScreen ?? focusedScreen();
    quickSettingsPage = page !== "" ? page : "main";
    quickSettingsOpen = true;
  }

  function closeQuickSettings(): void {
    if (!quickSettingsOpen) return;
    quickSettingsOpen = false;
    closedAt = Date.now();
  }

  function toggleQuickSettings(onScreen: ShellScreen): void {
    if (quickSettingsOpen) {
      closeQuickSettings();
    } else if (Date.now() - closedAt > 250) {
      openQuickSettings(onScreen, "main");
    }
  }

  // --- Clock panel (calendar + notifications) ------------------------------
  property bool clockPanelOpen: false
  // "calendar" or "notifications"
  property string clockTab: "calendar"
  property ShellScreen clockScreen: null
  property double clockClosedAt: 0

  function openClockPanel(onScreen: ShellScreen, tab: string): void {
    clockScreen = onScreen ?? focusedScreen();
    clockTab = tab !== "" ? tab : "calendar";
    clockPanelOpen = true;
  }

  function closeClockPanel(): void {
    if (!clockPanelOpen) return;
    clockPanelOpen = false;
    clockClosedAt = Date.now();
  }

  function toggleClockPanel(onScreen: ShellScreen, tab: string): void {
    if (clockPanelOpen) {
      closeClockPanel();
    } else if (Date.now() - clockClosedAt > 250) {
      openClockPanel(onScreen, tab);
    }
  }
}
