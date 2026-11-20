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
    Config.bar.showMedia = true;
    Config.bar.showWindowTitle = false;
    Config.bar.showClipboard = true;
    Config.bar.collapseTray = true;
    Config.bar.showDate = false;
    Config.bar.otherMonitors = "full";
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
    subtitle: "A floating pill with a gap around it, or attached to the edge of the screen."
    Segmented {
      model: ["Floating pill", "Attached"]
      currentIndex: Config.bar.style === "attached" ? 1 : 0
      accessibleName: "Bar style"
      onActivated: index => Config.bar.style = index === 1 ? "attached" : "floating"
    }
  }

  SettingRow {
    visible: Quickshell.screens.length > 1
    title: "Other monitors"
    subtitle: "The main monitor (" + (Config.displays.primary || Quickshell.screens[0]?.name || "") + ", set in Displays) always has the full bar. Light: workspaces and the clock."
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
    title: "Date next to the clock"
    subtitle: "\"Fri 20 Nov\". Otherwise only in the clock panel."
    Toggle { checked: Config.bar.showDate; accessibleName: "Date next to the clock"; onToggled: value => Config.bar.showDate = value }
  }
}
