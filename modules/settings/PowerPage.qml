// PowerPage.qml
// Locking when idle, the power profile, and low-battery warnings.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/battery"

SettingsPage {
  id: page
  title: "Power & idle"
  description: "Caffeine in quick settings keeps the screen awake for a while, whatever you set here."
  resetAction: () => {
    Config.lock.idleMinutes = 10;
    Config.battery.warnAt = 15;
    Config.battery.criticalAt = 5;
    Config.battery.criticalAction = "none";
  }

  readonly property var minutes: [0, 5, 10, 15, 30, 60]
  readonly property var warnLevels: [0, 10, 15, 20, 30]
  readonly property var criticalLevels: [0, 3, 5, 8, 10]
  readonly property var criticalActions: ["none", "suspend", "hibernate"]

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

  // --- Battery (laptops) ------------------------------------------------------------
  SettingRow {
    visible: Battery.hasBattery
    title: "Low battery warning"
    subtitle: "A notification when the battery gets this low and isn't charging."
    Segmented {
      model: ["Off", "10%", "15%", "20%", "30%"]
      currentIndex: Math.max(0, page.warnLevels.indexOf(Config.battery.warnAt))
      accessibleName: "Low battery warning at"
      onActivated: index => Config.battery.warnAt = page.warnLevels[index]
    }
  }

  SettingRow {
    visible: Battery.hasBattery
    title: "Critical battery"
    subtitle: "An urgent notification that stays until you close it."
    Segmented {
      model: ["Off", "3%", "5%", "8%", "10%"]
      currentIndex: Math.max(0, page.criticalLevels.indexOf(Config.battery.criticalAt))
      accessibleName: "Critical battery at"
      onActivated: index => Config.battery.criticalAt = page.criticalLevels[index]
    }
  }

  SettingRow {
    visible: Battery.hasBattery && Config.battery.criticalAt > 0
    title: "When critical"
    subtitle: "After a one-minute warning. Plugging in the charger cancels it. Hibernate needs swap set up for it."
    Segmented {
      model: ["Nothing", "Suspend", "Hibernate"]
      currentIndex: Math.max(0, page.criticalActions.indexOf(Config.battery.criticalAction))
      accessibleName: "When the battery is critical"
      onActivated: index => Config.battery.criticalAction = page.criticalActions[index]
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
