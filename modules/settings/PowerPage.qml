// PowerPage.qml
// Locking when idle, and the power profile.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Power & idle"
  description: "Caffeine in quick settings keeps the screen awake for a while, whatever you set here."
  resetAction: () => Config.lock.idleMinutes = 10

  readonly property var minutes: [0, 5, 10, 15, 30, 60]

  SettingRow {
    title: "Lock after"
    subtitle: "Minutes without input before the screen locks."
    Segmented {
      model: ["Never", "5", "10", "15", "30", "60"]
      currentIndex: Math.max(0, page.minutes.indexOf(Config.lock.idleMinutes))
      accessibleName: "Lock after"
      onActivated: index => Config.lock.idleMinutes = page.minutes[index]
    }
  }

  SettingRow {
    visible: Session.profilesAvailable
    title: "Power profile"
    subtitle: "Saver is quieter and cooler; Performance is faster."
    Segmented {
      model: ["Saver", "Balanced", "Performance"]
      readonly property var values: ["power-saver", "balanced", "performance"]
      currentIndex: Math.max(0, values.indexOf(Session.profile))
      accessibleName: "Power profile"
      onActivated: index => Session.setProfile(values[index])
    }
  }

  SettingRow {
    title: "Suspend locks first"
    subtitle: "Always on: the power menu and the launcher lock the screen before the computer sleeps."
    Icon { name: "check"; size: 16; color: Theme.good }
  }

  SettingRow {
    title: "Power menu"
    subtitle: "Lock, suspend, log out, restart, shut down, or schedule them. Super + Esc."
    Button {
      text: "Open"
      variant: "ghost"
      size: Theme.size.buttonList
      onClicked: {
        Panels.settingsOpen = false;
        Power.toggle(null);
      }
    }
  }
}
