// DisplaysPage.qml
// Resolution, refresh rate, scale, rotation and order of the monitors.
// Apply tries the new settings for 15 s; Keep saves them, otherwise they go
// back by themselves. Details in services/Displays.qml.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Displays"
  description: "Changes are tried first: keep them within 15 seconds, or they go back by themselves."

  readonly property var scales: [1, 1.25, 1.5, 2]
  // The settings being edited, left to right
  property var draft: []
  readonly property bool changed: JSON.stringify(draft.map(Displays.lua)) !== JSON.stringify(Displays.monitors.map(Displays.lua))

  function reset(): void {
    draft = Displays.monitors.map(m => Object.assign({}, m));
  }

  function update(index: int, values: var): void {
    const list = draft.slice();
    list[index] = Object.assign({}, list[index], values);
    draft = Displays.arrange(list);
  }

  function move(index: int, step: int): void {
    const list = draft.slice();
    const other = index + step;
    if (other < 0 || other >= list.length) return;
    [list[index], list[other]] = [list[other], list[index]];
    draft = Displays.arrange(list);
  }

  Component.onCompleted: {
    Displays.refresh();
    reset();
  }

  Connections {
    target: Displays
    function onMonitorsChanged() {
      if (!Displays.confirming) page.reset();
    }
  }

  // --- Keep or go back ---------------------------------------------------------------
  Rectangle {
    visible: Displays.confirming
    Layout.fillWidth: true
    implicitHeight: 60
    radius: Theme.radiusCard
    color: Theme.alpha(Theme.warn, 0.12)
    border.width: 1
    border.color: Theme.alpha(Theme.warn, 0.45)

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 10
      spacing: 10
      Icon { name: "monitor"; size: 18; color: Theme.warn }
      Label { Layout.fillWidth: true; text: "Keep these display settings? Going back in " + Displays.countdown + " s"; font.weight: Font.Bold }
      Button { text: "Go back"; variant: "ghost"; size: Theme.size.buttonList; onClicked: Displays.revert() }
      Button { text: "Keep"; variant: "primary"; size: Theme.size.buttonList; onClicked: Displays.keep() }
    }
  }

  Label {
    visible: Displays.error !== ""
    Layout.fillWidth: true
    text: "Hyprland didn't accept that: " + Displays.error
    color: Theme.error
    wrapMode: Text.Wrap
    font.pixelSize: Theme.font.small
  }

  // --- Arrangement, to scale ------------------------------------------------------------
  Rectangle {
    id: arrangement
    Layout.fillWidth: true
    implicitHeight: 170
    radius: Theme.radiusCard
    color: Theme.item

    readonly property var shown: page.draft.filter(m => !m.disabled)
    readonly property real totalWidth: Math.max(1, shown.reduce((sum, m) => sum + Math.round((m.transform % 2 ? m.height : m.width) / m.scale), 0))
    readonly property real totalHeight: Math.max(1, ...shown.map(m => Math.round((m.transform % 2 ? m.width : m.height) / m.scale)))
    readonly property real factor: Math.min((width - 60) / totalWidth, (height - 40) / totalHeight)

    Item {
      anchors.centerIn: parent
      width: arrangement.totalWidth * arrangement.factor
      height: arrangement.totalHeight * arrangement.factor

      Repeater {
        model: arrangement.shown

        Rectangle {
          id: screenBox
          required property var modelData
          readonly property bool main: modelData.name === (Config.displays.primary || Quickshell.screens[0]?.name)
          x: modelData.x * arrangement.factor
          y: modelData.y * arrangement.factor
          width: Math.round((modelData.transform % 2 ? modelData.height : modelData.width) / modelData.scale) * arrangement.factor - 4
          height: Math.round((modelData.transform % 2 ? modelData.width : modelData.height) / modelData.scale) * arrangement.factor - 4
          radius: Theme.r(8)
          color: Theme.alpha(Theme.accent, main ? 0.25 : 0.12)
          border.width: 1
          border.color: main ? Theme.accent : Theme.border

          Behavior on x { NumberAnimation { duration: Theme.anim.toggle } }

          Column {
            anchors.centerIn: parent
            spacing: 2
            Label { anchors.horizontalCenter: parent.horizontalCenter; text: screenBox.modelData.name; font.weight: Font.Bold; font.pixelSize: Theme.font.small }
            Label {
              anchors.horizontalCenter: parent.horizontalCenter
              text: Displays.hz(screenBox.modelData.refresh) + (screenBox.main ? " · main" : "")
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
          }
        }
      }
    }
  }

  // --- One card per monitor -----------------------------------------------------------------
  Repeater {
    model: page.draft

    Rectangle {
      id: monitorCard
      required property var modelData
      required property int index
      readonly property var m: modelData
      readonly property var resolutions: [...new Set(m.modes.map(x => x.width + "x" + x.height))]
      readonly property string currentRes: m.width + "x" + m.height
      readonly property var rates: m.modes.filter(x => x.width + "x" + x.height === currentRes).map(x => x.refresh).filter((r, i, all) => all.findIndex(o => Math.abs(o - r) < 0.05) === i).sort((a, b) => b - a)
      readonly property int enabledCount: page.draft.filter(x => !x.disabled).length

      Layout.fillWidth: true
      implicitHeight: cardColumn.implicitHeight + 28
      radius: Theme.radiusCard
      color: Theme.item

      ColumnLayout {
        id: cardColumn
        x: 16
        y: 14
        width: parent.width - 32
        spacing: 12

        RowLayout {
          Layout.fillWidth: true
          spacing: 10
          Icon { name: "monitor"; size: 16; color: Theme.accent }
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Label { text: monitorCard.m.name; font.weight: Font.Bold }
            Label { text: monitorCard.m.description; kind: "muted"; font.pixelSize: Theme.font.label }
          }
          Button {
            visible: page.draft.length > 1
            text: "← Left"
            variant: "ghost"
            size: Theme.size.buttonRow
            onClicked: page.move(monitorCard.index, -1)
          }
          Button {
            visible: page.draft.length > 1
            text: "Right →"
            variant: "ghost"
            size: Theme.size.buttonRow
            onClicked: page.move(monitorCard.index, 1)
          }
          Label { text: "On"; kind: "muted"; font.pixelSize: Theme.font.small }
          Toggle {
            checked: !monitorCard.m.disabled
            accessibleName: monitorCard.m.name + " on"
            // The last monitor that's on can't be turned off
            onToggled: value => {
              if (value || monitorCard.enabledCount > 1) page.update(monitorCard.index, { disabled: !value });
            }
          }
        }

        GridLayout {
          visible: !monitorCard.m.disabled
          Layout.fillWidth: true
          columns: 2
          columnSpacing: 16
          rowSpacing: 10

          Label { text: "Resolution"; kind: "muted"; font.pixelSize: Theme.font.small }
          Dropdown {
            Layout.preferredWidth: 220
            model: monitorCard.resolutions.map(r => r.replace("x", " × "))
            currentIndex: Math.max(0, monitorCard.resolutions.indexOf(monitorCard.currentRes))
            accessibleName: "Resolution of " + monitorCard.m.name
            onActivated: index => {
              const [w, h] = monitorCard.resolutions[index].split("x").map(Number);
              const best = monitorCard.m.modes.filter(x => x.width === w && x.height === h).sort((a, b) => b.refresh - a.refresh)[0];
              page.update(monitorCard.index, { width: w, height: h, refresh: best ? best.refresh : 60 });
            }
          }

          Label { text: "Refresh rate"; kind: "muted"; font.pixelSize: Theme.font.small }
          Segmented {
            // 60 and 59.94 both round to 60: show the decimals then
            model: monitorCard.rates.map(r => monitorCard.rates.filter(o => Math.round(o) === Math.round(r)).length > 1 ? r.toFixed(2) + " Hz" : Displays.hz(r))
            currentIndex: Math.max(0, monitorCard.rates.findIndex(r => Math.abs(r - monitorCard.m.refresh) < 0.5))
            accessibleName: "Refresh rate of " + monitorCard.m.name
            onActivated: index => page.update(monitorCard.index, { refresh: monitorCard.rates[index] })
          }

          Label { text: "Scale"; kind: "muted"; font.pixelSize: Theme.font.small }
          Segmented {
            model: page.scales.map(s => Math.round(s * 100) + "%")
            currentIndex: Math.max(0, page.scales.findIndex(s => Math.abs(s - monitorCard.m.scale) < 0.01))
            accessibleName: "Scale of " + monitorCard.m.name
            onActivated: index => page.update(monitorCard.index, { scale: page.scales[index] })
          }

          Label { text: "Rotation"; kind: "muted"; font.pixelSize: Theme.font.small }
          Segmented {
            model: ["Normal", "90°", "180°", "270°"]
            currentIndex: Math.max(0, Math.min(3, monitorCard.m.transform))
            accessibleName: "Rotation of " + monitorCard.m.name
            onActivated: index => page.update(monitorCard.index, { transform: index })
          }

          Label { text: "Main monitor"; kind: "muted"; font.pixelSize: Theme.font.small }
          RowLayout {
            spacing: 10
            Toggle {
              checked: monitorCard.m.name === (Config.displays.primary || Quickshell.screens[0]?.name)
              accessibleName: monitorCard.m.name + " is the main monitor"
              onToggled: value => { if (value) Config.displays.primary = monitorCard.m.name; }
            }
            Label { text: "Gets the full bar; applies right away"; kind: "muted"; font.pixelSize: Theme.font.label }
          }
        }
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 8
    Label {
      Layout.fillWidth: true
      text: page.changed ? "Not applied yet." : "Saved settings live in " + Quickshell.shellPath("hyprland/monitors.lua").replace(Quickshell.env("HOME"), "~") + "; delete it to use your own monitor config."
      kind: "muted"
      font.pixelSize: Theme.font.small
      wrapMode: Text.Wrap
    }
    Button { visible: page.changed; text: "Undo changes"; variant: "ghost"; size: Theme.size.buttonList; onClicked: page.reset() }
    Button {
      text: "Apply"
      variant: "primary"
      size: Theme.size.buttonList
      opacity: page.changed && !Displays.confirming ? 1 : 0.5
      onClicked: if (page.changed && !Displays.confirming) Displays.apply(page.draft)
    }
  }
}
