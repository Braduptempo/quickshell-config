//shell.qml

import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import "./modules/bar"
import "./modules/quicksettings"
import "./services"
import "./modules/notifications"
import "./modules/clockpanel"
import "./modules/osd"
import "./modules/launcher"
import "./modules/clipboard"
import "./modules/lock"
import "./modules/power"
import "./modules/polkit"
import "./modules/media"
import "./modules/capture"
import "./modules/pickers"
import "./modules/windows"
import "./modules/settings"
import "./modules/mainmenu"
import "./dev"

Scope {

  Bar {}

  // Notification pop-ups, and the clock panel (calendar + notifications)
  Toasts {}
  // Low-battery warnings (laptops); a singleton only starts when used
  readonly property int batteryStage: BatteryWarning.stage
  // Blur on or off (Settings → Theme)
  readonly property bool blurOn: Appearance.blur
  // The "Wallpaper" theme follows the wallpaper
  readonly property bool wallpaperTheme: WallpaperTheme.active

  ClockPanel {}

  // Volume, microphone, brightness, keyboard layout and Caps Lock pop-up
  OsdWindow {}

  // Super + Space
  LauncherWindow {}

  IpcHandler {
    target: "launcher"
    function toggle(): void {
      Launcher.toggle(Panels.focusedScreen());
    }
    // `qs ipc call launcher search "2*21"` opens with that text already typed
    function search(text: string): void {
      Launcher.openWith(Panels.focusedScreen(), text);
    }
  }

  // Super + L, and after Config.lock.idleMinutes without input
  LockScreen {}

  // `qs ipc call lock lock`; `preview` shows it without locking (development)
  IpcHandler {
    target: "lock"
    function lock(): void {
      Lock.lock();
    }
    function suspend(): void {
      Lock.suspend();
    }
    function preview(): void {
      Lock.showPreview();
    }
    // Only with QS_LOCK_TEST=1, for testing the real lock
    function unlock(): void {
      if (Lock.testMode) Lock.locked = false;
    }
    // Preview only: type text into the field, then try it
    function previewType(text: string): void {
      if (!Lock.preview) return;
      Lock.wake();
      Lock.typed = text;
    }
    function previewSubmit(): void {
      if (Lock.preview) Lock.submit(Lock.typed);
    }
  }

  // Password prompt when an app needs administrator rights (polkit agent)
  PolkitDialog {}

  // `qs ipc call polkit preview` (development), `cancel`
  IpcHandler {
    target: "polkit"
    function preview(): void {
      Polkit.showPreview();
    }
    function cancel(): void {
      Polkit.cancel();
    }
  }

  // Below the media pill
  MediaMenu {}

  // Under the privacy, updates and drives pills
  ExtrasMenu {}

  // Under a tray icon: the app's menu
  TrayMenu {}

  // `qs ipc call tray menu 0`: the menu of the first tray app; `close`
  IpcHandler {
    target: "tray"
    function menu(index: int): void {
      const item = SystemTray.items.values[index] ?? null;
      if (item && item.hasMenu) Panels.toggleTrayMenu(item, Panels.focusedScreen(), (Panels.focusedScreen()?.width ?? 1920) - 300);
    }
    function close(): void {
      Panels.trayMenuItem = null;
    }
  }

  // `qs ipc call extras open privacy|updates|drives`, `check` (updates now)
  IpcHandler {
    target: "extras"
    function open(kind: string): void {
      const screen = Panels.focusedScreen();
      Panels.toggleExtras(kind, screen, screen ? screen.width - 200 : 1700);
    }
    function check(): void {
      Updates.check();
    }
  }

  // `qs ipc call media toggle`
  IpcHandler {
    target: "media"
    function toggle(): void {
      Media.toggle(Panels.focusedScreen(), 180);
    }
  }

  // The button at the far left of the bar, and Super + X
  MainMenu {}

  // `qs ipc call mainmenu toggle`
  IpcHandler {
    target: "mainmenu"
    function toggle(): void {
      Panels.toggleMainMenu(Panels.focusedScreen());
    }
  }

  // Alt + Tab and Super + Tab
  WindowSwitcher {}
  Overview {}

  // `qs ipc call windows next|previous|commit|cancel` (Alt + Tab), `overview` (Super + Tab)
  IpcHandler {
    target: "windows"
    function next(): void {
      Windows.switcherStep(1);
    }
    function previous(): void {
      Windows.switcherStep(-1);
    }
    function commit(): void {
      Windows.switcherCommit();
    }
    function cancel(): void {
      Windows.switcherCancel();
    }
    function overview(): void {
      Windows.toggleOverview(Panels.focusedScreen());
    }
  }

  // Super + ,
  SettingsWindow {}

  // `qs ipc call settings toggle`, `open theme` (or wallpaper, font, animations, power, privacy, about)
  IpcHandler {
    target: "settings"
    function toggle(): void {
      Panels.toggleSettings(Panels.focusedScreen());
    }
    function open(page: string): void {
      Panels.openSettings(Panels.focusedScreen(), page);
    }
  }

  // Super + T and Super + W
  ThemePicker {}
  WallpaperPicker {}

  // `qs ipc call pickers theme`, `wallpaper`, `random` (a random wallpaper)
  IpcHandler {
    target: "pickers"
    function theme(): void {
      Panels.toggleThemePicker(Panels.focusedScreen());
    }
    function wallpaper(): void {
      Wallpapers.toggle(Panels.focusedScreen());
    }
    function random(): void {
      Wallpapers.set(Wallpapers.random());
    }
  }

  // Print: screenshot and recording toolbar
  CaptureToolbar {}

  // `qs ipc call capture toggle`, `shot region|window|screen`, `record …`, `stop`, `pause`
  IpcHandler {
    target: "capture"
    function toggle(): void {
      Capture.toggle(Panels.focusedScreen());
    }
    function shot(what: string): void {
      Capture.shoot(what);
    }
    function record(what: string): void {
      Capture.record(what);
    }
    function stop(): void {
      Capture.stop();
    }
    function pause(): void {
      Capture.pause();
    }
  }

  // Super + Esc
  PowerMenu {}

  // `qs ipc call power toggle`; `open R` opens with Restart chosen
  IpcHandler {
    target: "power"
    function toggle(): void {
      Power.toggle(Panels.focusedScreen());
    }
    function open(key: string): void {
      Power.openWith(Panels.focusedScreen(), key);
    }
    function cancel(): void {
      Power.cancelSchedule();
    }
  }

  // Super + Shift + V
  ClipboardWindow {}

  // `qs ipc call clipboard toggle`
  IpcHandler {
    target: "clipboard"
    function toggle(): void {
      Clipboard.toggle(Panels.focusedScreen());
    }
  }

  // `qs ipc call notifications toggle` (Super + N), `overview`, `calendar`,
  // `weather`, `dnd`, `clear`
  IpcHandler {
    target: "notifications"
    function toggle(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "notifications");
    }
    function calendar(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "calendar");
    }
    function overview(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "overview");
    }
    function weather(): void {
      Panels.toggleClockPanel(Panels.focusedScreen(), "weather");
    }
    function dnd(): void {
      Notifications.dnd = !Notifications.dnd;
    }
    function clear(): void {
      Notifications.clearAll();
    }
  }

  QuickSettings {}

  // `qs ipc call quicksettings toggle` (Super + A), or open a page directly:
  // `qs ipc call quicksettings open wifi`
  IpcHandler {
    target: "quicksettings"
    function toggle(): void {
      Panels.toggleQuickSettings(Panels.focusedScreen());
    }
    function open(page: string): void {
      Panels.openQuickSettings(Panels.focusedScreen(), page);
    }
  }

  // Component gallery for development. Open with QS_GALLERY=1 or
  // `qs ipc call gallery toggle`.
  LazyLoader {
    id: galleryLoader
    active: Quickshell.env("QS_GALLERY") === "1"
    Gallery {}
  }

  IpcHandler {
    target: "gallery"
    function toggle(): void {
      galleryLoader.active = !galleryLoader.active;
    }
  }
}
