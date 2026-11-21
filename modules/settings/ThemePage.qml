// ThemePage.qml
// Colour theme (built in, your own, or from the wallpaper), accent, and the
// look: glass, panels, corners, blur, borders and shadows, with a live preview.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Theme"
  description: "Colours of the whole shell. Changes apply right away. Super + T switches quickly. New theme starts from the current one; your own themes can be edited below the list."
  resetAction: () => {
    Config.appearance.theme = "Mocha";
    Config.appearance.accent = "";
    Config.appearance.glass = 0.45;
    Config.appearance.panelOpacity = 0.86;
    Config.appearance.roundness = 1;
    Config.appearance.blur = true;
    Config.appearance.borders = true;
    Config.appearance.shadows = true;
    Config.appearance.wallpaperMode = "auto";
  }

  // --- Live preview: a bit of bar and a panel on a made-up wallpaper ----------------------
  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 190
    radius: Theme.radiusCard
    color: Theme.crust
    clip: true

    Accessible.role: Accessible.Graphic
    Accessible.name: "Preview of the theme"

    // The "wallpaper": blobs in the theme's colours
    Repeater {
      model: [{ x: -0.08, y: -0.6, s: 0.5, c: Theme.palette.dots[5] ?? Theme.accent },
              { x: 0.35, y: -0.7, s: 0.4, c: Theme.palette.dots[1] ?? Theme.warn },
              { x: 0.78, y: -0.3, s: 0.45, c: Theme.accent },
              { x: 0.55, y: 0.45, s: 0.35, c: Theme.good }]
      Rectangle {
        required property var modelData
        x: parent.width * modelData.x
        y: parent.height * modelData.y
        width: parent.width * modelData.s
        height: width
        radius: width / 2
        color: modelData.c
        opacity: 0.85
      }
    }

    // The bar
    Rectangle {
      x: Theme.barPills ? 10 : Config.bar.style === "attached" ? 0 : 10
      y: Config.bar.style === "attached" ? 0 : 10
      width: parent.width - 2 * x
      height: 40
      radius: Config.bar.style === "attached" ? 0 : Theme.pill(height)
      color: Theme.barPills ? "transparent" : Theme.panel
      border.width: !Theme.barPills && Theme.borders ? 1 : 0
      border.color: Theme.border

      component MiniPill: Rectangle {
        property alias text: pillLabel.text
        property bool accent: false
        height: 28
        width: pillLabel.implicitWidth + 24
        radius: Theme.pill(height)
        color: accent ? Theme.alpha(Theme.accent, 0.16) : Theme.barItem
        border.width: accent || (Theme.barPills && Theme.borders) ? 1 : 0
        border.color: accent ? Theme.accent : Theme.border
        anchors.verticalCenter: parent.verticalCenter
        Label { id: pillLabel; anchors.centerIn: parent; font.pixelSize: Theme.font.small }
      }

      Row {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        MiniPill { text: "● ━ ●" }
        MiniPill { text: "♫ Song · Artist" }
      }
      MiniPill { anchors.centerIn: parent; text: Qt.formatTime(Time.date, "HH:mm"); accent: true }
      Row {
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        MiniPill { text: "Wi-Fi  ♪  100%" }
      }
    }

    // A panel
    GlassPanel {
      x: parent.width - width - 16
      y: 62
      width: 250
      height: 110
      color: Theme.panelSolid

      Column {
        x: 14
        y: 14
        width: parent.width - 28
        spacing: 10
        Row {
          spacing: 10
          Toggle { checked: true; accessibleName: "Preview toggle" }
          Label { text: "Night light"; anchors.verticalCenter: parent.verticalCenter }
        }
        Row {
          spacing: 8
          Button { text: "Button"; variant: "primary"; size: Theme.size.buttonRow }
          Button { text: "Ghost"; variant: "ghost"; size: Theme.size.buttonRow }
          Chip { text: "Chip"; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  readonly property var accents: ["", "#89b4fa", "#b4befe", "#cba6f7", "#f5c2e7", "#f38ba8", "#fab387", "#f9e2af", "#a6e3a1"]

  GridLayout {
    Layout.fillWidth: true
    columns: 4
    columnSpacing: 10
    rowSpacing: 10

    Repeater {
      model: Palettes.list

      Rectangle {
        id: card
        required property var modelData
        readonly property bool chosen: Config.appearance.theme === modelData.name

        Layout.fillWidth: true
        implicitHeight: 96
        radius: Theme.radiusCard
        color: modelData.base
        border.width: chosen ? 2 : 1
        border.color: chosen ? Theme.accent : Qt.rgba(1, 1, 1, 0.12)

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData.name
        Accessible.checked: chosen

        Rectangle { x: 10; y: 10; width: parent.width - 20; height: 9; radius: Theme.r(4); color: card.modelData.surface }
        Rectangle { x: 10; y: 26; width: parent.width * 0.4; height: 6; radius: Theme.r(3); color: card.modelData.text }
        Rectangle { x: 10; y: 37; width: parent.width * 0.28; height: 6; radius: Theme.r(3); color: card.modelData.subtext }
        Rectangle { anchors.right: parent.right; anchors.rightMargin: 10; y: 26; width: parent.width * 0.3; height: 17; radius: Theme.r(8); color: card.modelData.accent }

        Row {
          x: 10
          y: 52
          spacing: 3
          Repeater {
            model: card.modelData.dots
            Rectangle { required property string modelData; width: 9; height: 9; radius: Theme.r(5); color: modelData }
          }
        }

        Text {
          x: 10
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          text: card.modelData.name
          color: card.modelData.text
          font.family: Theme.font.family
          font.pixelSize: Theme.font.small
          font.weight: card.chosen ? Font.Bold : Font.Normal
        }

        Icon {
          visible: card.chosen
          anchors.right: parent.right
          anchors.bottom: parent.bottom
          anchors.margins: 8
          name: "check"
          size: 14
          strokeWidth: 3
          color: card.modelData.accent
        }

        // Your own themes are marked
        Rectangle {
          visible: card.modelData.custom === true || card.modelData.wallpaper === true
          anchors.right: parent.right
          anchors.top: parent.top
          anchors.margins: 6
          implicitWidth: customLabel.implicitWidth + 10
          implicitHeight: 16
          radius: Theme.r(8)
          color: card.modelData.accent
          Text {
            id: customLabel
            anchors.centerIn: parent
            text: card.modelData.wallpaper ? "Wallpaper" : "Yours"
            color: card.modelData.light ? card.modelData.base : card.modelData.crust
            font.family: Theme.font.family
            font.pixelSize: Theme.font.label
            font.weight: Font.Bold
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.appearance.theme = card.modelData.name
        }
      }
    }

    // The wallpaper's colours, until the first time they're made
    Rectangle {
      visible: Palettes.fromWallpaper.length === 0
      Layout.fillWidth: true
      implicitHeight: 96
      radius: Theme.radiusCard
      color: wallMouse.containsMouse ? Theme.hover(Theme.item) : "transparent"
      border.width: 1
      border.color: Theme.border

      Accessible.role: Accessible.Button
      Accessible.name: "Theme from the wallpaper"

      Column {
        anchors.centerIn: parent
        spacing: 6
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "image"; size: 20; color: Theme.subtext }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "From wallpaper"; font.pixelSize: Theme.font.small; color: Theme.subtext }
      }

      MouseArea {
        id: wallMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Config.appearance.theme = "Wallpaper"
      }
    }

    // A copy of the current theme to edit
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 96
      radius: Theme.radiusCard
      color: newMouse.containsMouse ? Theme.hover(Theme.item) : "transparent"
      border.width: 1
      border.color: Theme.border

      Accessible.role: Accessible.Button
      Accessible.name: "New theme from the current one"

      Column {
        anchors.centerIn: parent
        spacing: 6
        Icon { anchors.horizontalCenter: parent.horizontalCenter; name: "plus"; size: 20; color: Theme.subtext }
        Label { anchors.horizontalCenter: parent.horizontalCenter; text: "New theme"; font.pixelSize: Theme.font.small; color: Theme.subtext }
      }

      MouseArea {
        id: newMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Palettes.create(Theme.palette)
      }
    }
  }

  ThemeEditor { Layout.fillWidth: true }

  SettingRow {
    title: "Accent"
    subtitle: "Buttons, sliders and highlights. The first one is the theme's own."

    Repeater {
      model: page.accents

      Rectangle {
        id: swatch
        required property string modelData
        width: 24
        height: 24
        radius: Theme.r(12)
        color: modelData !== "" ? modelData : Theme.palette.accent
        border.width: Config.appearance.accent === modelData ? 2 : 0
        border.color: Theme.text

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData !== "" ? modelData : "Theme default"
        Accessible.checked: Config.appearance.accent === modelData

        Rectangle { visible: swatch.modelData === ""; anchors.centerIn: parent; width: 8; height: 8; radius: Theme.r(4); color: Theme.base }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Config.appearance.accent = swatch.modelData
        }
      }
    }
  }

  SettingRow {
    visible: Config.appearance.theme === "Wallpaper"
    title: "From wallpaper"
    subtitle: "Light or dark: from the picture, or always one of them. Follows the wallpaper of the main screen."
    Segmented {
      readonly property var modes: ["auto", "dark", "light"]
      model: ["Auto", "Dark", "Light"]
      currentIndex: Math.max(0, modes.indexOf(Config.appearance.wallpaperMode))
      accessibleName: "Wallpaper theme light or dark"
      onActivated: index => Config.appearance.wallpaperMode = modes[index]
    }
  }

  // --- The look -------------------------------------------------------------------------
  SettingRow {
    title: "Bar glass"
    subtitle: "How much of what's behind shows through the bar."

    PillSlider {
      width: 220
      icon: "image"
      label: "Bar glass"
      // 0.2 … 1 shown as 0 … 100%
      value: (Config.appearance.glass - 0.2) / 0.8
      throttle: 50
      onMoved: v => Config.appearance.glass = Math.round((0.2 + v * 0.8) * 100) / 100
    }
  }

  SettingRow {
    title: "Panels"
    subtitle: "How solid menus, quick settings and dialogs are. Lower shows more of what's behind."

    PillSlider {
      width: 220
      icon: "window"
      label: "Panels"
      // 0.5 … 1 shown as 0 … 100%
      value: (Config.appearance.panelOpacity - 0.5) / 0.5
      throttle: 50
      onMoved: v => Config.appearance.panelOpacity = Math.round((0.5 + v * 0.5) * 100) / 100
    }
  }

  SettingRow {
    title: "Corners"
    subtitle: "From square to fully round pills."

    PillSlider {
      width: 220
      icon: "region"
      label: "Corners"
      value: Config.appearance.roundness
      step: 0.1
      throttle: 50
      onMoved: v => Config.appearance.roundness = Math.round(v * 20) / 20
    }
  }

  SettingRow {
    title: "Blur"
    subtitle: "Hyprland blurs what's behind the glass. Off is lighter on the GPU."
    Toggle { checked: Config.appearance.blur; accessibleName: "Blur"; onToggled: value => Config.appearance.blur = value }
  }
  SettingRow {
    title: "Borders"
    subtitle: "A thin edge and a highlight along the top of the glass."
    Toggle { checked: Config.appearance.borders; accessibleName: "Borders"; onToggled: value => Config.appearance.borders = value }
  }
  SettingRow {
    title: "Shadows"
    subtitle: "A soft shadow under panels and menus."
    Toggle { checked: Config.appearance.shadows; accessibleName: "Shadows"; onToggled: value => Config.appearance.shadows = value }
  }
}
