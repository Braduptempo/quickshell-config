// SoundPage.qml
// Output and microphone (choice and volume), the volume per app, and a few
// options. The quick settings sound page has the same devices in short.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../config"
import "../../components"
import "../../widgets/sound"

SettingsPage {
  id: page
  title: "Sound"
  resetAction: () => {
    Config.sound.maxVolume = 1.0;
    Config.sound.feedback = false;
    Config.sound.followNewDevices = true;
  }

  readonly property var nodes: Pipewire.nodes.values
  readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
  readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
  readonly property var apps: nodes.filter(n => n.audio && n.type === PwNodeType.AudioOutStream)

  function nodeName(node: PwNode): string {
    return node.properties["application.name"] ?? (node.description !== "" ? node.description : node.name);
  }

  // Volume and mute are only live while tracked
  PwObjectTracker {
    objects: page.apps.concat(page.outputs).concat(page.inputs)
  }

  // --- A list of devices to pick from -------------------------------------------------
  component DeviceCard: Rectangle {
    id: card
    property string heading
    property var devices: []
    property PwNode current: null
    property string icon
    signal picked(PwNode node)
    default property alias extra: extraColumn.data

    Layout.fillWidth: true
    implicitHeight: cardColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: cardColumn
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 4

      Label { text: card.heading; kind: "label"; Layout.leftMargin: 4; Layout.bottomMargin: 4 }

      Label {
        visible: card.devices.length === 0
        text: "Nothing found"
        kind: "muted"
        Layout.leftMargin: 4
      }

      Repeater {
        model: card.devices

        Rectangle {
          id: device
          required property PwNode modelData
          readonly property bool chosen: card.current !== null && card.current.id === modelData.id

          Layout.fillWidth: true
          implicitHeight: 42
          radius: Theme.pill(height)
          color: chosen ? Theme.alpha(Theme.accent, 0.16) : deviceMouse.containsMouse ? Theme.item : "transparent"
          border.width: chosen ? 1 : 0
          border.color: Theme.alpha(Theme.accent, 0.5)

          Accessible.role: Accessible.RadioButton
          Accessible.name: page.nodeName(modelData)
          Accessible.checked: chosen

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 10
            Icon { name: card.icon; size: 15; color: device.chosen ? Theme.accent : Theme.subtext }
            Label { Layout.fillWidth: true; text: page.nodeName(device.modelData); font.weight: device.chosen ? Font.Bold : Font.Normal; elide: Text.ElideRight }
            Icon { visible: device.chosen; name: "check"; size: 14; strokeWidth: 3; color: Theme.accent }
          }

          MouseArea {
            id: deviceMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.picked(device.modelData)
          }
        }
      }

      ColumnLayout {
        id: extraColumn
        Layout.fillWidth: true
        Layout.topMargin: 6
        spacing: 8
      }
    }
  }

  DeviceCard {
    heading: "Output"
    icon: "volume"
    devices: page.outputs
    current: Pipewire.defaultAudioSink
    onPicked: node => Pipewire.preferredDefaultAudioSink = node

    PillSlider {
      Layout.fillWidth: true
      icon: Sound.isMuted ? "volume-off" : "volume"
      label: "Output volume"
      // The pill shows 0 … the maximum (100% or 150%)
      value: (Sound.defaultSink?.audio?.volume ?? 0) / Config.sound.maxVolume
      onMoved: v => Sound.setVolume(v * Config.sound.maxVolume)
    }
  }

  DeviceCard {
    heading: "Microphone"
    icon: "mic"
    devices: page.inputs
    current: Pipewire.defaultAudioSource
    onPicked: node => Pipewire.preferredDefaultAudioSource = node

    PillSlider {
      Layout.fillWidth: true
      icon: Sound.isMicMuted ? "mic-off" : "mic"
      label: "Microphone volume"
      fillColor: Theme.good
      value: Sound.defaultSource?.audio?.volume ?? 0
      onMoved: v => Sound.setMicVolume(v)
    }
  }

  // --- Apps -------------------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: appColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: appColumn
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 8

      Label { text: "Apps"; kind: "label"; Layout.leftMargin: 4 }
      Label {
        visible: page.apps.length === 0
        text: "No app is playing sound right now"
        kind: "muted"
        Layout.leftMargin: 4
      }

      Repeater {
        model: page.apps

        RowLayout {
          id: app
          required property PwNode modelData
          Layout.fillWidth: true
          spacing: 10

          Label { Layout.preferredWidth: 150; text: page.nodeName(app.modelData); elide: Text.ElideRight; font.pixelSize: Theme.font.small }
          PillSlider {
            Layout.fillWidth: true
            icon: app.modelData.audio?.muted ? "volume-off" : "volume"
            label: page.nodeName(app.modelData)
            value: app.modelData.audio?.volume ?? 0
            onMoved: v => { if (app.modelData.audio) app.modelData.audio.volume = v; }
          }
          IconButton {
            size: 30
            icon: app.modelData.audio?.muted ? "volume-off" : "volume"
            variant: app.modelData.audio?.muted ? "dangerSoft" : "ghost"
            accessibleName: (app.modelData.audio?.muted ? "Unmute " : "Mute ") + page.nodeName(app.modelData)
            onClicked: { if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted; }
          }
        }
      }
    }
  }

  // --- Options ------------------------------------------------------------------------------
  SettingRow {
    title: "Switch to new devices"
    subtitle: "Plugging in headphones moves the sound there."
    Toggle { checked: Config.sound.followNewDevices; accessibleName: "Switch to new devices"; onToggled: value => Config.sound.followNewDevices = value }
  }
  SettingRow {
    title: "Allow above 100%"
    subtitle: "Up to 150%; louder, but it can distort."
    Toggle {
      checked: Config.sound.maxVolume > 1
      accessibleName: "Allow above 100 percent"
      onToggled: value => {
        Config.sound.maxVolume = value ? 1.5 : 1.0;
        // Back to at most 100% when turned off
        if (!value && (Sound.defaultSink?.audio?.volume ?? 0) > 1) Sound.setVolume(1);
      }
    }
  }
  SettingRow {
    title: "Volume change sound"
    subtitle: "A short click when the volume changes."
    Toggle { checked: Config.sound.feedback; accessibleName: "Volume change sound"; onToggled: value => Config.sound.feedback = value }
  }
}
