// BarPage.qml
// Where the bar sits, how it looks, and what's in it.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"

SettingsPage {
  title: "Bar & panels"
  description: "Panels that open from the bar follow it to the top or the bottom."
  resetAction: () => {
    Config.bar.position = "top";
    Config.bar.style = "floating";
    Config.bar.size = "normal";
    Config.bar.showMedia = true;
    Config.bar.showWindowTitle = false;
    Config.bar.showClipboard = true;
    Config.bar.collapseTray = true;
    Config.bar.trayClick = "menu";
    Config.bar.showDate = false;
    Config.bar.otherMonitors = "full";
    Config.bar.showPrivacy = true;
    Config.bar.showUpdates = true;
    Config.bar.showDrives = true;
    Config.bar.showLoad = true;
  }

  SettingRow {
    title: "Position"
    Segmented {
      model: ["Top", "Bottom"]
      currentIndex: Config.bar.position === "bottom" ? 1 : 0
      accessibleName: "Bar position"
      onActivated: index => Config.bar.position = index === 1 ? "bottom" : "top"
    }
  }

  SettingRow {
    title: "Style"
    subtitle: "A floating pill with a gap around it, attached to the edge of the screen, or only the pills with the wallpaper between them."
    Segmented {
      readonly property var styles: ["floating", "attached", "pills"]
      model: ["Floating", "Attached", "Pills only"]
      currentIndex: Math.max(0, styles.indexOf(Config.bar.style))
      accessibleName: "Bar style"
      onActivated: index => Config.bar.style = styles[index]
    }
  }

  SettingRow {
    title: "Size"
    subtitle: "How tall the bar and its pills are."
    Segmented {
      readonly property var sizes: ["compact", "normal", "large"]
      model: ["Compact", "Normal", "Large"]
      currentIndex: Math.max(0, sizes.indexOf(Config.bar.size))
      accessibleName: "Bar size"
      onActivated: index => Config.bar.size = sizes[index]
    }
  }

  SettingRow {
    visible: Quickshell.screens.length > 1
    title: "Other monitors"
    subtitle: "The main monitor (" + (Config.displays.primary || Quickshell.screens[0]?.name || "") + ", set in Displays) always has the full bar. Light: workspaces, the window on that screen and the clock."
    Segmented {
      model: ["Full bar", "Light bar", "No bar"]
      currentIndex: Math.max(0, ["full", "light", "none"].indexOf(Config.bar.otherMonitors))
      accessibleName: "Bar on other monitors"
      onActivated: index => Config.bar.otherMonitors = ["full", "light", "none"][index]
    }
  }

  Label { text: "Show in the bar"; kind: "label"; Layout.topMargin: 8 }

  SettingRow {
    title: "Media"
    subtitle: "Only while something plays."
    Toggle { checked: Config.bar.showMedia; accessibleName: "Media"; onToggled: value => Config.bar.showMedia = value }
  }
  SettingRow {
    title: "Window title"
    subtitle: "The focused window, next to the workspaces."
    Toggle { checked: Config.bar.showWindowTitle; accessibleName: "Window title"; onToggled: value => Config.bar.showWindowTitle = value }
  }
  SettingRow {
    title: "Clipboard button"
    subtitle: "Opens the clipboard history (Super + Shift + V works either way)."
    Toggle { checked: Config.bar.showClipboard; accessibleName: "Clipboard button"; onToggled: value => Config.bar.showClipboard = value }
  }
  SettingRow {
    title: "Tray behind an arrow"
    subtitle: "App icons stay hidden until you click the arrow. Off: always shown."
    Toggle { checked: Config.bar.collapseTray; accessibleName: "Tray behind an arrow"; onToggled: value => Config.bar.collapseTray = value }
  }
  SettingRow {
    title: "Tray click"
    subtitle: "What a left click on a tray icon does. Many apps (Spotify, Electron apps) only answer with their menu. Right click is always the menu."
    Segmented {
      model: ["Menu", "Open the app"]
      currentIndex: Config.bar.trayClick === "open" ? 1 : 0
      accessibleName: "Tray click"
      onActivated: index => Config.bar.trayClick = index === 1 ? "open" : "menu"
    }
  }
  SettingRow {
    title: "Privacy"
    subtitle: "A red pill while an app uses the microphone, camera or your screen."
    Toggle { checked: Config.bar.showPrivacy; accessibleName: "Privacy"; onToggled: value => Config.bar.showPrivacy = value }
  }
  SettingRow {
    title: "High load"
    subtitle: "A yellow pill while the CPU or GPU runs at 90 % or more, or at 85 °C. Click it for the system page."
    Toggle { checked: Config.bar.showLoad; accessibleName: "High load"; onToggled: value => Config.bar.showLoad = value }
  }
  SettingRow {
    title: "Updates"
    subtitle: "How many package updates are waiting (pacman and AUR), checked every hour."
    Toggle { checked: Config.bar.showUpdates; accessibleName: "Updates"; onToggled: value => Config.bar.showUpdates = value }
  }
  SettingRow {
    title: "Drives"
    subtitle: "USB sticks and other removable drives, to open and eject."
    Toggle { checked: Config.bar.showDrives; accessibleName: "Drives"; onToggled: value => Config.bar.showDrives = value }
  }
  SettingRow {
    title: "Date next to the clock"
    subtitle: "\"Fri 20 Nov\". Otherwise only in the clock panel."
    Toggle { checked: Config.bar.showDate; accessibleName: "Date next to the clock"; onToggled: value => Config.bar.showDate = value }
  }
}
