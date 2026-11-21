// AudioPage.qml
// Sound details: output and input device with their volume, and the
// volume per app.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../config"
import "../../components"
import "../../widgets/sound"

ColumnLayout {
  id: root

  readonly property var nodes: Pipewire.nodes.values
  readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
  readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
  // Apps that are playing sound
  readonly property var apps: nodes.filter(n => n.audio && n.type === PwNodeType.AudioOutStream)

  // The app behind a stream, found by its program first: Spotify says
  // "Chromium" as its name but runs as `spotify`; Zen runs as `zen-bin`
  function nodeEntry(node: PwNode): var {
    const bin = node.properties["application.process.binary"] ?? "";
    const keys = [bin, bin.replace(/-bin$/, ""), node.properties["application.name"] ?? ""].filter(k => k !== "");
    for (const k of keys) {
      const entry = DesktopEntries.heuristicLookup(k);
      if (entry) return entry;
    }
    return null;
  }

  function nodeIcon(node: PwNode): string {
    const entry = nodeEntry(node);
    if (entry && entry.icon !== "") return entry.icon;
    return node.properties["application.icon-name"] ?? "";
  }

  function nodeName(node: PwNode): string {
    const entry = nodeEntry(node);
    if (entry) return entry.name.replace(/\s*\(.*\)$/, "");
    return node.properties["application.name"] ?? (node.description !== "" ? node.description : node.name);
  }

  // Volume and mute of these nodes are only live while they are tracked
  PwObjectTracker {
    objects: root.apps.concat(root.outputs).concat(root.inputs)
  }

  spacing: 12

  PageHeader {
    Layout.fillWidth: true
    title: "Sound"
  }

  // --- Output / input devices --------------------------------------------------
  component DeviceList: Card {
    id: deviceList
    property var model: []
    property PwNode current: null
    signal picked(PwNode node)

    Layout.fillWidth: true
    implicitHeight: column.implicitHeight

    Column {
      id: column
      width: parent.width

      Repeater {
        model: deviceList.model

        ListRow {
          id: deviceRow
          required property PwNode modelData
          required property int index
          readonly property bool selected: deviceList.current !== null && deviceList.current.id === modelData.id

          width: column.width
          first: index === 0
          title: modelData.description !== "" ? modelData.description : modelData.name

          Rectangle {
            width: 16
            height: 16
            radius: 8
            color: deviceRow.selected ? Theme.accent : "transparent"
            border.width: 2
            border.color: deviceRow.selected ? Theme.accent : Theme.overlay
            anchors.verticalCenter: parent.verticalCenter
          }

          MouseArea {
            parent: deviceRow
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: deviceList.picked(deviceRow.modelData)
          }
        }
      }
    }
  }

  Label { text: "Output"; kind: "label" }
  // The chosen output's volume
  RowLayout {
    Layout.fillWidth: true
    spacing: 6
    IconButton {
      icon: Sound.isMuted ? "volume-off" : "volume"
      size: Theme.size.slider
      variant: Sound.isMuted ? "dangerSoft" : "ghost"
      accessibleName: Sound.isMuted ? "Unmute output" : "Mute output"
      onClicked: Sound.toggleMute()
    }
    PillSlider {
      Layout.fillWidth: true
      label: "Output volume"
      showValue: true
      value: Sound.volume / 100
      opacity: Sound.isMuted ? 0.5 : 1
      onMoved: v => Sound.setVolume(v)
    }
  }

  DeviceList {
    model: root.outputs
    current: Pipewire.defaultAudioSink
    onPicked: node => Pipewire.preferredDefaultAudioSink = node
  }

  Label { text: "Input"; kind: "label"; visible: root.inputs.length > 0 }
  // The chosen microphone's level
  RowLayout {
    visible: root.inputs.length > 0
    Layout.fillWidth: true
    spacing: 6
    IconButton {
      icon: Sound.isMicMuted ? "mic-off" : "mic"
      size: Theme.size.slider
      variant: Sound.isMicMuted ? "dangerSoft" : "ghost"
      accessibleName: Sound.isMicMuted ? "Unmute microphone" : "Mute microphone"
      onClicked: Sound.toggleMicMute()
    }
    PillSlider {
      Layout.fillWidth: true
      label: "Microphone level"
      showValue: true
      value: Sound.micVolume / 100
      opacity: Sound.isMicMuted ? 0.5 : 1
      onMoved: v => Sound.setMicVolume(v)
    }
  }

  DeviceList {
    visible: root.inputs.length > 0
    model: root.inputs
    current: Pipewire.defaultAudioSource
    onPicked: node => Pipewire.preferredDefaultAudioSource = node
  }

  // --- Apps ----------------------------------------------------------------------
  Label { text: "Apps"; kind: "label" }

  Label {
    visible: root.apps.length === 0
    text: "No app is playing sound"
    kind: "muted"
  }

  Repeater {
    model: root.apps

    RowLayout {
      id: app
      required property PwNode modelData
      Layout.fillWidth: true
      spacing: 6

      IconButton {
        icon: app.modelData.audio?.muted ? "volume-off" : "volume"
        size: Theme.size.slider
        checked: false
        variant: app.modelData.audio?.muted ? "dangerSoft" : "ghost"
        accessibleName: (app.modelData.audio?.muted ? "Unmute " : "Mute ") + root.nodeName(app.modelData)
        onClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
      }

      PillSlider {
        Layout.fillWidth: true
        label: root.nodeName(app.modelData) + " volume"
        showValue: true
        value: app.modelData.audio?.volume ?? 0
        opacity: app.modelData.audio?.muted ? 0.5 : 1
        onMoved: v => { if (app.modelData.audio) app.modelData.audio.volume = v; }

        Row {
          anchors.left: parent.left
          anchors.leftMargin: 10
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 80
          spacing: 8
          IconImage {
            readonly property string appIcon: root.nodeIcon(app.modelData)
            visible: appIcon !== ""
            implicitSize: 18
            anchors.verticalCenter: parent.verticalCenter
            source: Quickshell.iconPath(appIcon, true)
          }
          Label {
            text: root.nodeName(app.modelData)
            font.weight: Font.Bold
            color: Theme.onAccent
            width: parent.width - 26
            elide: Text.ElideRight
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }
    }
  }
}
