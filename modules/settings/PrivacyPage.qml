// PrivacyPage.qml
// What the lock screen shows, and the clipboard history.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  title: "Privacy & lock"
  description: "The lock screen never shows notification text, only how many there are."
  resetAction: () => {
    Config.lock.showMedia = true;
    Config.lock.showNotifications = true;
  }

  SettingRow {
    title: "Show what's playing"
    subtitle: "Title, artist and controls on the lock screen."
    Toggle {
      checked: Config.lock.showMedia
      accessibleName: "Show what's playing on the lock screen"
      onToggled: value => Config.lock.showMedia = value
    }
  }

  SettingRow {
    title: "Show notification count"
    subtitle: "\"3 notifications\" under the clock."
    Toggle {
      checked: Config.lock.showNotifications
      accessibleName: "Show the notification count on the lock screen"
      onToggled: value => Config.lock.showNotifications = value
    }
  }

  SettingRow {
    title: "Preview the lock screen"
    subtitle: "Shows it without locking; \"demo\" unlocks the preview."
    Button {
      text: "Preview"
      variant: "ghost"
      size: Theme.size.buttonList
      onClicked: {
        Panels.settingsOpen = false;
        Lock.showPreview();
      }
    }
  }

  SettingRow {
    visible: Clipboard.available
    title: "Clipboard history"
    subtitle: Clipboard.items.length + " items. Passwords from password managers are never stored. Pinned items stay."
    Button {
      text: "Clear"
      variant: "dangerSoft"
      size: Theme.size.buttonList
      onClicked: Clipboard.clearUnpinned()
    }
  }
}
