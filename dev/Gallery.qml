// Gallery.qml
// Test window with every component, to check them against the design and to
// tune theme and animation speed live. Open it with:
//   QS_GALLERY=1 qs -p <config>       or     qs ipc call gallery toggle
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../config"
import "../components"

FloatingWindow {
  id: root

  title: "Quickshell components"
  implicitWidth: 1180
  implicitHeight: 820
  color: Theme.crust

  // Colourful blobs behind the glass, like a wallpaper
  Rectangle { x: -120; y: 260; width: 520; height: 520; radius: 260; color: "#cba6f7"; opacity: 0.35 }
  Rectangle { x: 760; y: -180; width: 560; height: 560; radius: 280; color: "#89b4fa"; opacity: 0.3 }
  Rectangle { x: 520; y: 560; width: 420; height: 420; radius: 210; color: "#a6e3a1"; opacity: 0.25 }

  Flickable {
    anchors.fill: parent
    contentHeight: page.implicitHeight + 48
    clip: true

    ColumnLayout {
      id: page
      x: 24
      y: 24
      width: root.width - 48
      spacing: 18

      // --- Header: live theme and motion controls ---------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 12
        Label { text: "Components"; kind: "section" }
        Label { text: "Change theme or speed: everything updates live"; kind: "muted"; Layout.fillWidth: true }
        Label { text: "Speed"; kind: "muted" }
        Segmented {
          model: ["Off", "Slow", "Normal", "Fast"]
          currentIndex: Config.animations.speed
          accessibleName: "Animation speed"
          onActivated: index => Config.animations.speed = index
        }
      }

      Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
          model: Palettes.list
          Chip {
            required property var modelData
            text: modelData.name
            checkable: true
            checked: Config.appearance.theme === modelData.name
            onToggled: Config.appearance.theme = modelData.name
          }
        }
      }

      GridLayout {
        Layout.fillWidth: true
        columns: 3
        columnSpacing: 18
        rowSpacing: 18

        // --- Buttons ---------------------------------------------------------
        GlassPanel {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          implicitHeight: buttons.implicitHeight + 36
          ColumnLayout {
            id: buttons
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Label { text: "Buttons"; kind: "title" }
            Flow {
              Layout.fillWidth: true
              spacing: 8
              Button { text: "Primary"; variant: "primary" }
              Button { text: "Secondary" }
              Button { text: "Ghost"; variant: "ghost" }
              Button { text: "Outline"; variant: "outline" }
              Button { text: "Shut down"; variant: "danger" }
              Button { text: "Stop"; variant: "dangerSoft" }
              Button { text: "Disabled"; enabled: false }
              Button { text: "With icon"; icon: "plus"; variant: "primary" }
            }
            Flow {
              Layout.fillWidth: true
              spacing: 8
              Button { text: "32 px"; size: Theme.size.buttonSmall }
              Button { text: "28 px"; size: Theme.size.buttonList }
              Button { text: "26 px"; size: Theme.size.buttonRow }
            }
            Label { text: "Icon buttons"; kind: "label" }
            Row {
              spacing: 8
              IconButton { icon: "chevron-right"; size: 28; accessibleName: "Details" }
              IconButton { icon: "clipboard"; size: 30; accessibleName: "Clipboard" }
              IconButton { icon: "close"; size: 34; accessibleName: "Close" }
              IconButton { icon: "power"; size: 34; variant: "dangerSoft"; accessibleName: "Power" }
              IconButton { icon: "play"; size: 38; variant: "primary"; accessibleName: "Play" }
              IconButton { icon: "arrow-right"; size: 44; variant: "primary"; accessibleName: "Unlock" }
            }
          }
        }

        // --- Selection -------------------------------------------------------
        GlassPanel {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          implicitHeight: selection.implicitHeight + 36
          ColumnLayout {
            id: selection
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Label { text: "Toggles & selection"; kind: "title" }
            Row {
              spacing: 12
              Toggle { checked: true; accessibleName: "Example on" }
              Toggle { checked: false; accessibleName: "Example off" }
            }
            Segmented {
              Layout.fillWidth: true
              model: ["Saver", "Balanced", "Performance"]
              currentIndex: 1
              accessibleName: "Power profile"
            }
            Label { text: "Filter chips"; kind: "label" }
            Flow {
              Layout.fillWidth: true
              spacing: 6
              Chip { text: "All"; checkable: true; checked: true }
              Chip { text: "Text"; checkable: true }
              Chip { text: "Images"; checkable: true }
              Chip { text: "Links"; checkable: true }
            }
            Label { text: "Status"; kind: "label" }
            Flow {
              Layout.fillWidth: true
              spacing: 6
              Chip { text: "Connected"; tone: "good" }
              Chip { text: "Restart needed"; tone: "warn" }
              Chip { text: "Wrong password"; tone: "error" }
              Chip { text: "AUR"; tone: "accent" }
              Kbd { text: "Super + T" }
            }
          }
        }

        // --- Sliders ---------------------------------------------------------
        GlassPanel {
          Layout.fillWidth: true
          Layout.alignment: Qt.AlignTop
          implicitHeight: sliders.implicitHeight + 36
          ColumnLayout {
            id: sliders
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Label { text: "Sliders"; kind: "title" }
            PillSlider { Layout.fillWidth: true; icon: "volume"; label: "Volume"; value: 0.45 }
            PillSlider { Layout.fillWidth: true; icon: "sun"; label: "Brightness"; value: 0.7; fillColor: Theme.warn }
            PillSlider {
              Layout.fillWidth: true
              icon: "settings"
              label: "Glass"
              value: Config.appearance.glass
              onMoved: v => Config.appearance.glass = Math.max(0.2, v)
            }
            Label { text: "The last one changes the glass for real"; kind: "muted" }
          }
        }

        // --- List ------------------------------------------------------------
        GlassPanel {
          Layout.fillWidth: true
          Layout.columnSpan: 2
          implicitHeight: list.implicitHeight + 36
          ColumnLayout {
            id: list
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12
            Label { text: "Lists & rows"; kind: "title" }
            Card {
              Layout.fillWidth: true
              implicitHeight: rows.implicitHeight
              Column {
                id: rows
                width: parent.width
                ListRow {
                  width: parent.width
                  first: true
                  title: "Setting with a switch"
                  subtitle: "One line of explanation"
                  Toggle { accessibleName: "Setting" }
                }
                ListRow {
                  width: parent.width
                  title: "Arctis Nova 7"
                  subtitle: "Connected · battery 80%"
                  subtitleColor: Theme.good
                  Button { text: "Disconnect"; variant: "ghost"; size: Theme.size.buttonRow }
                }
                ListRow {
                  width: parent.width
                  title: "linux-lts"
                  subtitle: "6.18.64 → 6.18.66"
                  Chip { text: "core" }
                }
              }
            }
          }
        }

        // --- Theme colours ---------------------------------------------------
        GlassPanel {
          Layout.fillWidth: true
          implicitHeight: colours.implicitHeight + 36
          ColumnLayout {
            id: colours
            anchors.fill: parent
            anchors.margins: 18
            spacing: 10
            Label { text: Config.appearance.theme; kind: "title" }
            Grid {
              columns: 5
              spacing: 8
              Repeater {
                model: [
                  { n: "crust", c: Theme.crust }, { n: "base", c: Theme.base }, { n: "surface", c: Theme.surface },
                  { n: "overlay", c: Theme.overlay }, { n: "text", c: Theme.text }, { n: "subtext", c: Theme.subtext },
                  { n: "accent", c: Theme.accent }, { n: "good", c: Theme.good }, { n: "warn", c: Theme.warn },
                  { n: "error", c: Theme.error }
                ]
                Column {
                  required property var modelData
                  spacing: 4
                  Rectangle { width: 48; height: 28; radius: 10; color: parent.modelData.c; border.width: 1; border.color: Theme.border }
                  Label { text: parent.modelData.n; kind: "label"; font.capitalization: Font.MixedCase; font.letterSpacing: 0 }
                }
              }
            }
          }
        }
      }

      // --- Icons ---------------------------------------------------------------
      GlassPanel {
        Layout.fillWidth: true
        implicitHeight: icons.implicitHeight + 36
        ColumnLayout {
          id: icons
          anchors.fill: parent
          anchors.margins: 18
          spacing: 12
          Label { text: "Icons (" + Icons.names.length + ")"; kind: "title" }
          Flow {
            Layout.fillWidth: true
            spacing: 10
            Repeater {
              model: Icons.names
              Column {
                required property string modelData
                width: 76
                spacing: 6
                Icon { name: parent.modelData; size: 20; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: parent.modelData; kind: "label"; font.capitalization: Font.MixedCase; font.letterSpacing: 0; width: parent.width; horizontalAlignment: Text.AlignHCenter }
              }
            }
          }
        }
      }
    }
  }
}
