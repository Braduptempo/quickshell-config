// InputPage.qml
// Keyboard layouts and options, key repeat, pointer speed, scrolling and the
// cursor. Changes apply right away; see services/Input.qml.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Keyboard & mouse"
  description: "Changes apply right away and are saved to " + Quickshell.shellPath("hyprland/input.lua").replace(Quickshell.env("HOME"), "~") + ", which wins over your own input.lua."

  readonly property var repeatRates: [15, 25, 35, 50]
  readonly property var repeatDelays: [250, 400, 600, 800]
  readonly property var cursorSizes: [24, 32, 48]

  Component.onCompleted: Input.refresh()

  Label {
    visible: Input.error !== ""
    Layout.fillWidth: true
    text: "Hyprland didn't accept that: " + Input.error
    color: Theme.error
    wrapMode: Text.Wrap
    font.pixelSize: Theme.font.small
  }

  // --- Layouts ------------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: layoutColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: layoutColumn
      x: 14
      y: 12
      width: parent.width - 28
      spacing: 6

      Label { text: "Keyboard layouts"; kind: "label" }
      Label { text: "The first one is used at start."; kind: "muted"; font.pixelSize: Theme.font.small; wrapMode: Text.Wrap; Layout.fillWidth: true }

      Repeater {
        model: Input.layoutList

        RowLayout {
          id: layoutRow
          required property var modelData
          required property int index
          Layout.fillWidth: true
          implicitHeight: 38
          spacing: 10

          Rectangle {
            implicitWidth: 40
            implicitHeight: 26
            radius: 13
            color: Theme.overlay
            Label { anchors.centerIn: parent; text: layoutRow.modelData.code.toUpperCase(); font.weight: Font.Bold; font.pixelSize: Theme.font.label }
          }
          Label { Layout.fillWidth: true; text: Input.layoutName(layoutRow.modelData) }
          Label { visible: layoutRow.index === 0; text: "first"; kind: "muted"; font.pixelSize: Theme.font.label }
          IconButton {
            visible: layoutRow.index > 0
            size: 28
            icon: "chevron-up"
            variant: "plain"
            accessibleName: "Move " + Input.layoutName(layoutRow.modelData) + " up"
            onClicked: {
              const list = Input.layoutList.slice();
              [list[layoutRow.index - 1], list[layoutRow.index]] = [list[layoutRow.index], list[layoutRow.index - 1]];
              Input.setLayouts(list);
            }
          }
          IconButton {
            visible: Input.layoutList.length > 1
            size: 28
            icon: "close"
            variant: "plain"
            accessibleName: "Remove " + Input.layoutName(layoutRow.modelData)
            onClicked: Input.removeLayout(layoutRow.index)
          }
        }
      }

      RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 8
        Label { text: "Add"; kind: "muted"; font.pixelSize: Theme.font.small }
        Dropdown {
          id: addLayout
          Layout.preferredWidth: 280
          readonly property var available: Input.knownLayouts.filter(k => !Input.layoutList.some(l => (l.variant !== "" ? l.code + "(" + l.variant + ")" : l.code) === k[0]))
          model: ["Choose a layout…"].concat(available.map(k => k[1] + " · " + k[0]))
          currentIndex: 0
          accessibleName: "Add a keyboard layout"
          onActivated: index => { if (index > 0) Input.addLayout(available[index - 1][0]); }
        }
      }
    }
  }

  SettingRow {
    visible: Input.layoutList.length > 1
    title: "Switch layouts with Alt + Shift"
    subtitle: "A pop-up shows the new layout."
    Toggle { checked: Input.altShiftSwitch; accessibleName: "Switch layouts with Alt + Shift"; onToggled: value => Input.setOption("grp:alt_shift_toggle", value) }
  }

  SettingRow {
    title: "Caps Lock acts as Escape"
    subtitle: "Handy for Vim; Shift + Caps Lock still turns caps on."
    Toggle { checked: Input.capsIsEscape; accessibleName: "Caps Lock acts as Escape"; onToggled: value => Input.setCapsEscape(value) }
  }
  SettingRow {
    title: "Num Lock on at start"
    Toggle { checked: Input.numlock; accessibleName: "Num Lock on at start"; onToggled: value => Input.set({ numlock: value }) }
  }

  // --- Typing -------------------------------------------------------------------------------
  SettingRow {
    title: "Repeat rate"
    subtitle: "Characters per second while you hold a key."
    Segmented {
      model: page.repeatRates.map(r => r + "/s")
      currentIndex: Math.max(0, page.repeatRates.indexOf(Input.repeatRate))
      accessibleName: "Repeat rate"
      onActivated: index => Input.set({ repeatRate: page.repeatRates[index] })
    }
  }
  SettingRow {
    title: "Repeat delay"
    subtitle: "How long you hold a key before it repeats."
    Segmented {
      model: page.repeatDelays.map(d => d + " ms")
      currentIndex: Math.max(0, page.repeatDelays.indexOf(Input.repeatDelay))
      accessibleName: "Repeat delay"
      onActivated: index => Input.set({ repeatDelay: page.repeatDelays[index] })
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.pill(height)
    color: Theme.item

    TextInput {
      id: tryIt
      anchors.fill: parent
      anchors.leftMargin: 16
      anchors.rightMargin: 16
      verticalAlignment: TextInput.AlignVCenter
      color: Theme.text
      font.family: Theme.font.family
      font.pixelSize: Theme.font.body
      clip: true
      Accessible.role: Accessible.EditableText
      Accessible.name: "Try the keyboard here"
      Label { visible: tryIt.text === ""; anchors.verticalCenter: parent.verticalCenter; text: "Try it: hold a key here…"; kind: "muted" }
    }
  }

  // --- Mouse ------------------------------------------------------------------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: speedColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: speedColumn
      x: 16
      y: 12
      width: parent.width - 32
      spacing: 8

      RowLayout {
        Layout.fillWidth: true
        Label { text: "Pointer speed"; font.weight: Font.Bold; Layout.fillWidth: true }
        Label { text: (Input.sensitivity > 0 ? "+" : "") + Input.sensitivity.toFixed(1); font.weight: Font.Bold }
      }
      PillSlider {
        Layout.fillWidth: true
        icon: "cursor"
        label: "Pointer speed"
        showValue: false
        // -1 … 1 shown as 0 … 100%
        value: (Input.sensitivity + 1) / 2
        throttle: 100
        onMoved: v => Input.set({ sensitivity: Math.round((v * 2 - 1) * 10) / 10 })
      }
      RowLayout {
        Layout.fillWidth: true
        Label { text: "Slower"; kind: "muted"; font.pixelSize: Theme.font.label; Layout.fillWidth: true }
        Label { text: "Faster"; kind: "muted"; font.pixelSize: Theme.font.label }
      }
    }
  }

  SettingRow {
    title: "Acceleration"
    subtitle: "Flat moves the pointer the same distance at any speed: better for games."
    Segmented {
      model: ["Adaptive", "Flat"]
      currentIndex: Input.accelProfile === "flat" ? 1 : 0
      accessibleName: "Acceleration"
      onActivated: index => Input.set({ accelProfile: index === 1 ? "flat" : "adaptive" })
    }
  }
  SettingRow {
    title: "Scrolling"
    subtitle: "Natural: the page moves the way your fingers do."
    Segmented {
      model: ["Traditional", "Natural"]
      currentIndex: Input.naturalScroll ? 1 : 0
      accessibleName: "Scrolling"
      onActivated: index => Input.set({ naturalScroll: index === 1 })
    }
  }
  SettingRow {
    title: "Focus follows mouse"
    subtitle: "Windows get focus when you hover them."
    Toggle { checked: Input.followMouse === 1; accessibleName: "Focus follows mouse"; onToggled: value => Input.set({ followMouse: value ? 1 : 0 }) }
  }
  SettingRow {
    title: "Hide cursor while typing"
    Toggle { checked: Input.hideWhileTyping; accessibleName: "Hide cursor while typing"; onToggled: value => Input.set({ hideWhileTyping: value }) }
  }

  // --- Cursor -----------------------------------------------------------------------------
  SettingRow {
    title: "Cursor"
    subtitle: Input.cursorThemes.length <= 1 ? "More themes: install them (e.g. bibata-cursor-theme) and they show up here." : ""
    Dropdown {
      width: 180
      model: Input.cursorThemes.length > 0 ? Input.cursorThemes : [Input.cursorTheme]
      currentIndex: Math.max(0, Input.cursorThemes.indexOf(Input.cursorTheme))
      accessibleName: "Cursor theme"
      onActivated: index => Input.setCursor(Input.cursorThemes[index], Input.cursorSize)
    }
    Segmented {
      model: page.cursorSizes.map(s => String(s))
      currentIndex: Math.max(0, page.cursorSizes.indexOf(Input.cursorSize))
      accessibleName: "Cursor size"
      onActivated: index => Input.setCursor(Input.cursorTheme, page.cursorSizes[index])
    }
  }
}
