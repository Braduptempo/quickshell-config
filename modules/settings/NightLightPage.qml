// NightLightPage.qml
// Warmer colours in the evening (hyprsunset): when, and how warm.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  title: "Night light"
  description: Session.nightLightAvailable ? "Warmer colours are easier on the eyes at night. Quick settings turns it on and off by hand."
                                           : "Night light needs hyprsunset: sudo pacman -S hyprsunset"
  resetAction: () => {
    Config.nightLight.temperature = 4000;
    Config.nightLight.schedule = "manual";
    Config.nightLight.from = "20:00";
    Config.nightLight.to = "07:00";
    Config.nightLight.pauseWhileRecording = true;
  }

  // --- Now ---------------------------------------------------------------------------
  SettingRow {
    title: "Night light"
    subtitle: !Session.nightLightAvailable ? "Not available"
            : Session.nightLightPaused ? "Paused while recording"
            : Session.nightLight ? "On · " + Config.nightLight.temperature + " K" : "Off"
    Toggle {
      checked: Session.nightLight
      accessibleName: "Night light"
      onToggled: value => Session.nightLight = value
    }
  }

  // --- How warm ----------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: warmColumn.implicitHeight + 28
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: warmColumn
      x: 16
      y: 14
      width: parent.width - 32
      spacing: 10

      RowLayout {
        Layout.fillWidth: true
        Label { text: "Colour temperature"; font.weight: Font.Bold; Layout.fillWidth: true }
        Label { text: Config.nightLight.temperature + " K"; font.weight: Font.Bold }
      }

      // From 6000 K (almost neutral) on the left to 2500 K (very warm) on the right
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: 10
        radius: 5
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0; color: "#fff4e8" }
          GradientStop { position: 0.5; color: "#ffc58a" }
          GradientStop { position: 1; color: "#ff8a2a" }
        }
      }

      PillSlider {
        Layout.fillWidth: true
        icon: "sun"
        label: "Colour temperature"
        fillColor: Theme.warn
        showValue: false
        value: (6000 - Config.nightLight.temperature) / 3500
        throttle: 150
        onMoved: v => Config.nightLight.temperature = Math.round((6000 - v * 3500) / 100) * 100
      }

      RowLayout {
        Layout.fillWidth: true
        Label { text: "Cooler · 6000 K"; kind: "muted"; font.pixelSize: Theme.font.label; Layout.fillWidth: true }
        Label { text: "Warmer · 2500 K"; kind: "muted"; font.pixelSize: Theme.font.label }
      }
    }
  }

  // --- When ---------------------------------------------------------------------------
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
    title: "Schedule"
    subtitle: Config.nightLight.schedule === "custom" ? "Turns on and off by itself; you can still switch it by hand in between."
                                                     : "Only when you turn it on."
    Segmented {
      model: ["Manual", "Custom times"]
      currentIndex: Config.nightLight.schedule === "custom" ? 1 : 0
      accessibleName: "Schedule"
      onActivated: index => Config.nightLight.schedule = index === 1 ? "custom" : "manual"
    }
  }

  SettingRow {
    visible: Config.nightLight.schedule === "custom"
    title: "From"
    subtitle: Session.nightLightScheduled ? "Inside the scheduled hours right now." : ""
    TimeField {
      anchors.verticalCenter: parent.verticalCenter
      value: Config.nightLight.from
      onEdited: value => Config.nightLight.from = value
    }
    Label { text: "until"; kind: "muted"; anchors.verticalCenter: parent.verticalCenter }
    TimeField {
      anchors.verticalCenter: parent.verticalCenter
      value: Config.nightLight.to
      onEdited: value => Config.nightLight.to = value
    }
  }

  SettingRow {
    title: "Pause while recording"
    subtitle: "Screen recordings keep their real colours."
    Toggle {
      checked: Config.nightLight.pauseWhileRecording
      accessibleName: "Pause while recording"
      onToggled: value => Config.nightLight.pauseWhileRecording = value
    }
  }
}
