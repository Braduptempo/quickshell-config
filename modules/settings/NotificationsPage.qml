// NotificationsPage.qml
// Pop-ups, quiet hours and per-app rules.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Notifications"
  description: "Everything always lands in the clock panel; these only change what pops up. Critical notifications always get through."
  resetAction: () => {
    Config.notifications.popups = true;
    Config.notifications.stack = true;
    Config.notifications.position = "top-right";
    Config.notifications.duration = 5;
    Config.notifications.sound = false;
    Config.notifications.quietFrom = "";
    Config.notifications.quietTo = "";
    Config.notifications.mutedApps = [];
  }

  readonly property var durations: [3, 5, 10]

  SettingRow {
    title: "Show pop-ups"
    subtitle: "Off: they only go to the clock panel."
    Toggle { checked: Config.notifications.popups; accessibleName: "Show pop-ups"; onToggled: value => Config.notifications.popups = value }
  }
  SettingRow {
    title: "Stack pop-ups"
    subtitle: "Several fold into one pile; hover it to fan them out."
    Toggle { checked: Config.notifications.stack; accessibleName: "Stack pop-ups"; onToggled: value => Config.notifications.stack = value }
  }
  SettingRow {
    title: "Position"
    Segmented {
      model: ["Top right", "Top centre", "Bottom right"]
      currentIndex: Math.max(0, ["top-right", "top-center", "bottom-right"].indexOf(Config.notifications.position))
      accessibleName: "Pop-up position"
      onActivated: index => Config.notifications.position = ["top-right", "top-center", "bottom-right"][index]
    }
  }
  SettingRow {
    title: "How long"
    subtitle: "When the app doesn't say. Hovering keeps them."
    Segmented {
      model: ["3 s", "5 s", "10 s"]
      currentIndex: Math.max(0, page.durations.indexOf(Config.notifications.duration))
      accessibleName: "Pop-up duration"
      onActivated: index => Config.notifications.duration = page.durations[index]
    }
  }
  SettingRow {
    title: "Play a sound"
    subtitle: "The system's notification sound."
    Toggle { checked: Config.notifications.sound; accessibleName: "Play a sound"; onToggled: value => Config.notifications.sound = value }
  }

  // --- Quiet hours ------------------------------------------------------------------
  component TimeField: Rectangle {
    id: field
    property string value
    signal edited(string value)
    width: 76
    height: 32
    radius: 16
    color: Theme.alpha(Theme.crust, 0.5)
    border.width: input.activeFocus ? 1 : 0
    border.color: Theme.accent

    TextInput {
      id: input
      anchors.fill: parent
      horizontalAlignment: TextInput.AlignHCenter
      verticalAlignment: TextInput.AlignVCenter
      text: field.value
      color: Theme.text
      font.family: Theme.font.family
      font.pixelSize: Theme.font.body
      inputMask: "99:99"
      onEditingFinished: {
        const m = text.match(/^(\d{2}):(\d{2})$/);
        if (m && parseInt(m[1]) < 24 && parseInt(m[2]) < 60) field.edited(text);
      }
      Accessible.role: Accessible.EditableText
    }
  }

  SettingRow {
    title: "Quiet hours"
    subtitle: Notifications.inQuietHours ? "On right now: pop-ups wait until " + Config.notifications.quietTo + "."
            : "Do not disturb every day between these times."

    Toggle {
      anchors.verticalCenter: parent.verticalCenter
      checked: Config.notifications.quietFrom !== ""
      accessibleName: "Quiet hours"
      onToggled: value => {
        Config.notifications.quietFrom = value ? "22:00" : "";
        Config.notifications.quietTo = value ? "07:00" : "";
      }
    }
    TimeField {
      visible: Config.notifications.quietFrom !== ""
      anchors.verticalCenter: parent.verticalCenter
      value: Config.notifications.quietFrom
      onEdited: value => Config.notifications.quietFrom = value
    }
    Label { visible: Config.notifications.quietFrom !== ""; text: "to"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter }
    TimeField {
      visible: Config.notifications.quietFrom !== ""
      anchors.verticalCenter: parent.verticalCenter
      value: Config.notifications.quietTo
      onEdited: value => Config.notifications.quietTo = value
    }
  }

  // --- Per app --------------------------------------------------------------------------
  Label { text: "Per app"; kind: "label"; Layout.topMargin: 8 }

  Label {
    visible: Config.notifications.knownApps.length === 0
    text: "Apps show up here once they've sent a notification."
    kind: "muted"
  }

  Repeater {
    model: Config.notifications.knownApps

    SettingRow {
      id: appRow
      required property string modelData
      title: modelData
      subtitle: Notifications.isMuted(modelData) ? "No pop-ups; still in the clock panel" : "Pop-ups"
      Toggle {
        checked: !Notifications.isMuted(appRow.modelData)
        accessibleName: "Pop-ups from " + appRow.modelData
        onToggled: value => Notifications.setMuted(appRow.modelData, !value)
      }
    }
  }
}
