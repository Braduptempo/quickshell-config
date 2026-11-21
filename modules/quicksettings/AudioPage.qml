// AudioPage.qml
// Sound details, laid out like the Mixer design: the output (chips for up to
// three devices) and its volume, every app with its own icon (click to mute)
// and what it's playing, and the microphone.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import "../../config"
import "../../components"
import "../../services"
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

    Button {
      text: "Settings"
      variant: "ghost"
      size: Theme.size.buttonList
      onClicked: Panels.openSettings(null, "sound")
    }
  }

  // What kind of device, from its name
  function deviceIcon(node: PwNode): string {
    const n = ((node.description || "") + " " + (node.name || "")).toLowerCase();
    if (/headset|headphone|bluez|airpods|buds/.test(n)) return "headphones";
    if (/hdmi|displayport|monitor/.test(n)) return "monitor";
    if (/usb/.test(n)) return "usb";
    return "volume";
  }

  // A short name: "Steinberg UR22C Stereo Line (output)" -> "Steinberg UR22C"
  function shortName(node: PwNode): string {
    const n = node.description !== "" ? node.description : node.name;
    return n.replace(/\s*\(.*\)$/, "").replace(/ (Analog|Digital) Stereo.*$/, "").replace(/ Stereo Line.*$/, "")
            .replace(/ High Definition Audio Controller/, " HDA");
  }

  // Up to three outputs as chips next to each other
  component DeviceChips: RowLayout {
    id: chips
    property var model: []
    property PwNode current: null
    signal picked(PwNode node)

    Layout.fillWidth: true
    spacing: 6

    Repeater {
      model: chips.model
      Rectangle {
        id: chip
        required property PwNode modelData
        readonly property bool selected: chips.current !== null && chips.current.id === modelData.id

        Layout.fillWidth: true
        Layout.preferredWidth: 1
        implicitHeight: 40
        radius: Theme.pill(height)
        color: selected ? Theme.alpha(Theme.accent, 0.14) : chipMouse.containsMouse ? Theme.hover(Theme.item) : Theme.item
        border.width: 1
        border.color: selected ? Theme.alpha(Theme.accent, 0.5) : "transparent"

        Accessible.role: Accessible.RadioButton
        Accessible.name: root.shortName(modelData)
        Accessible.checked: selected

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 5
          anchors.rightMargin: 10
          spacing: 7
          Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: Theme.pill(height)
            color: chip.selected ? Theme.accent : Theme.alpha(Theme.text, 0.08)
            Icon { anchors.centerIn: parent; name: root.deviceIcon(chip.modelData); size: 14; color: chip.selected ? Theme.onAccent : Theme.text }
          }
          Label {
            Layout.fillWidth: true
            text: root.shortName(chip.modelData)
            font.pixelSize: Theme.font.label
            font.weight: chip.selected ? Font.Bold : Font.Normal
            elide: Text.ElideRight
          }
        }
        MouseArea {
          id: chipMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: chips.picked(chip.modelData)
        }
      }
    }
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
            radius: Theme.r(8)
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

  EmptyState {
    visible: root.outputs.length === 0 || Fake.has("no-audio")
    Layout.fillWidth: true
    icon: "volume"
    crossed: true
    title: "No output device found"
    text: "Check your cable, or connect headphones over Bluetooth."
    action: "Bluetooth…"
    secondAction: "Restart audio"
    onActivated: Panels.quickSettingsPage = "bluetooth"
    onSecondActivated: Quickshell.execDetached(["systemctl", "--user", "restart", "pipewire", "pipewire-pulse", "wireplumber"])
  }

  Label { visible: root.outputs.length > 0; text: "Output"; kind: "label" }
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

  DeviceChips {
    visible: root.outputs.length > 0 && root.outputs.length <= 3
    model: root.outputs.length <= 3 ? root.outputs : []
    current: Pipewire.defaultAudioSink
    onPicked: node => Pipewire.preferredDefaultAudioSink = node
  }
  DeviceList {
    visible: root.outputs.length > 3
    model: root.outputs.length > 3 ? root.outputs : []
    current: Pipewire.defaultAudioSink
    onPicked: node => Pipewire.preferredDefaultAudioSink = node
  }

  Label { text: "Microphone"; kind: "label"; visible: root.inputs.length > 0 }
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
    // One microphone needs no choice
    visible: root.inputs.length > 1
    model: root.inputs
    current: Pipewire.defaultAudioSource
    onPicked: node => Pipewire.preferredDefaultAudioSource = node
  }

  // --- Apps ----------------------------------------------------------------------
  Label { text: "Apps"; kind: "label"; Layout.topMargin: 4 }

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
      required property int index
      Layout.fillWidth: true
      spacing: 6

      // The app itself: click to mute
      Rectangle {
        id: appButton
        readonly property bool muted: app.modelData.audio?.muted ?? false
        readonly property string appIcon: root.nodeIcon(app.modelData)
        implicitWidth: Theme.size.slider
        implicitHeight: Theme.size.slider
        radius: Theme.pill(height)
        color: appIcon !== "" ? (appMouse.containsMouse ? Theme.hover(Theme.item) : Theme.item) : Theme.palette.dots[app.index % 6] ?? Theme.accent
        opacity: muted ? 0.6 : 1

        Accessible.role: Accessible.Button
        Accessible.name: (muted ? "Unmute " : "Mute ") + root.nodeName(app.modelData)

        IconImage {
          visible: appButton.appIcon !== ""
          anchors.centerIn: parent
          implicitSize: 22
          source: Quickshell.iconPath(appButton.appIcon, true)
        }
        Label {
          visible: appButton.appIcon === ""
          anchors.centerIn: parent
          text: root.nodeName(app.modelData).charAt(0).toUpperCase()
          font.weight: Font.Bold
          color: Theme.crust
        }
        // Muted: a red badge
        Rectangle {
          visible: appButton.muted
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: -2
          width: 18
          height: 18
          radius: Theme.pill(height)
          color: Theme.error
          border.width: 2
          border.color: Theme.base
          Icon { anchors.centerIn: parent; name: "close"; size: 9; strokeWidth: 4; color: Theme.crust }
        }
        MouseArea {
          id: appMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
        }
      }

      PillSlider {
        Layout.fillWidth: true
        label: root.nodeName(app.modelData) + " volume"
        showValue: true
        value: app.modelData.audio?.volume ?? 0
        opacity: app.modelData.audio?.muted ? 0.5 : 1
        onMoved: v => { if (app.modelData.audio) app.modelData.audio.volume = v; }

        // The app, and what it plays (or "Muted")
        Column {
          readonly property string playing: app.modelData.properties["media.name"] ?? ""
          anchors.left: parent.left
          anchors.leftMargin: 14
          anchors.verticalCenter: parent.verticalCenter
          width: parent.width - 80
          spacing: 0
          Label {
            text: root.nodeName(app.modelData)
            font.weight: Font.Bold
            font.pixelSize: Theme.font.small
            color: Theme.onAccent
            width: parent.width
            elide: Text.ElideRight
          }
          Label {
            visible: text !== ""
            text: appButton.muted ? "Muted" : parent.playing
            font.pixelSize: Theme.font.label
            color: Theme.alpha(Theme.onAccent, 0.7)
            width: parent.width
            elide: Text.ElideRight
          }
        }
      }
    }
  }
}
