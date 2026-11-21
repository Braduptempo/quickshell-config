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
  // "overview", "calendar", "weather" or "notifications"
  property string clockTab: "overview"
  property ShellScreen clockScreen: null
  property double clockClosedAt: 0

  function openClockPanel(onScreen: ShellScreen, tab: string): void {
    clockScreen = onScreen ?? focusedScreen();
    clockTab = tab !== "" ? tab : "overview";
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

  // --- Theme picker (Super + T) ------------------------------------------------
  property bool themePickerOpen: false
  property ShellScreen themeScreen: null
  property double themeClosedAt: 0

  onThemePickerOpenChanged: if (!themePickerOpen) themeClosedAt = Date.now()

  function toggleThemePicker(onScreen: ShellScreen): void {
    if (themePickerOpen) {
      themePickerOpen = false;
    } else if (Date.now() - themeClosedAt > 250) {
      themeScreen = onScreen ?? focusedScreen();
      themePickerOpen = true;
    }
  }

  // --- Settings (Super + ,) ------------------------------------------------------
  property bool settingsOpen: false
  property string settingsPage: "theme"
  property ShellScreen settingsScreen: null

  function openSettings(onScreen: ShellScreen, page: string): void {
    settingsScreen = onScreen ?? focusedScreen();
    if (page !== "") settingsPage = page;
    settingsOpen = true;
  }

  function toggleSettings(onScreen: ShellScreen): void {
    if (settingsOpen) settingsOpen = false;
    else openSettings(onScreen, "");
  }

  // --- Bar extras menu: "privacy", "updates" or "drives" ---------------------------
  property string extrasMenu: ""
  property ShellScreen extrasScreen: null
  // Right edge of the pill that opened it
  property real extrasRight: 0
  property double extrasClosedAt: 0

  onExtrasMenuChanged: if (extrasMenu === "") extrasClosedAt = Date.now()

  function toggleExtras(kind: string, onScreen: ShellScreen, right: real): void {
    if (extrasMenu === kind) {
      extrasMenu = "";
    } else if (extrasMenu !== "" || Date.now() - extrasClosedAt > 250) {
      extrasScreen = onScreen;
      extrasRight = right;
      extrasMenu = kind;
    }
  }

  // --- Main menu: the button at the far left of the bar (Super + X) ----------------
  property bool mainMenuOpen: false
  property ShellScreen mainMenuScreen: null
  property double mainMenuClosedAt: 0

  onMainMenuOpenChanged: if (!mainMenuOpen) mainMenuClosedAt = Date.now()

  function toggleMainMenu(onScreen: ShellScreen): void {
    if (mainMenuOpen) {
      mainMenuOpen = false;
    } else if (Date.now() - mainMenuClosedAt > 250) {
      mainMenuScreen = onScreen ?? focusedScreen();
      mainMenuOpen = true;
    }
  }
}
