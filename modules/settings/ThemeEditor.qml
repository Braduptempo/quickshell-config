// ThemeEditor.qml
// Edits the chosen custom theme in place: name, light or dark, and every
// colour as a hex value (or picked from the screen with hyprpicker).
// Changes apply right away and are saved in settings.json.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"
import "../../components"

Rectangle {
  id: root

  readonly property var theme: Theme.palette
  property bool confirmDelete: false

  readonly property var labels: ({
    base: "Background",
    surface: "Surface",
    overlay: "Overlay",
    crust: "Darkest",
    text: "Text",
    subtext: "Secondary text",
    accent: "Accent",
    good: "Good",
    warn: "Warning",
    error: "Error"
  })

  visible: theme.custom === true
  implicitHeight: column.implicitHeight + 28
  radius: Theme.radiusCard
  color: Theme.item

  onThemeChanged: confirmDelete = false

  // Colour picked from the screen goes to this key
  property string pickKey: ""
  Process {
    id: picker
    command: ["hyprpicker", "-f", "hex", "-n"]
    stdout: StdioCollector {
      onStreamFinished: {
        const c = text.trim().toLowerCase();
        if (Palettes.isValidColor(c) && root.pickKey !== "") Palettes.update(root.theme.name, { [root.pickKey]: c });
        root.pickKey = "";
      }
    }
  }

  ColumnLayout {
    id: column
    x: 14
    y: 14
    width: parent.width - 28
    spacing: 12

    RowLayout {
      Layout.fillWidth: true
      spacing: 10

      Label { text: "Edit theme"; kind: "label" }
      Item { Layout.fillWidth: true }
      Segmented {
        model: ["Dark", "Light"]
        currentIndex: root.theme.light ? 1 : 0
        accessibleName: "Light or dark theme"
        onActivated: index => Palettes.update(root.theme.name, { light: index === 1 })
      }
      Button {
        text: root.confirmDelete ? "Delete for good?" : "Delete"
        variant: "dangerSoft"
        size: Theme.size.buttonRow
        onClicked: {
          if (root.confirmDelete) Palettes.remove(root.theme.name);
          else root.confirmDelete = true;
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 10
      Label { text: "Name"; Layout.preferredWidth: 110 }
      TextField {
        id: nameField
        Layout.fillWidth: true
        placeholder: "Theme name"
        text: root.theme.name
        error: nameError.visible
        onAccepted: nameError.visible = !Palettes.rename(root.theme.name, text)
      }
      Connections {
        target: root
        function onThemeChanged() {
          nameField.text = root.theme.name;
          nameError.visible = false;
        }
      }
    }
    Label {
      id: nameError
      visible: false
      text: "That name is empty or already used"
      color: Theme.error
      font.pixelSize: Theme.font.label
    }
    Label {
      text: "Press Enter to rename. Colours: a hex value like #89b4fa, or the pipette to pick one from the screen."
      kind: "muted"
      font.pixelSize: Theme.font.label
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }

    GridLayout {
      Layout.fillWidth: true
      columns: 2
      columnSpacing: 16
      rowSpacing: 8

      Repeater {
        model: Palettes.keys

        RowLayout {
          id: colorRow
          required property string modelData
          readonly property string value: root.theme[modelData] ?? ""

          Layout.fillWidth: true
          spacing: 8

          // Typing breaks the text binding; keep the field in step with the pipette
          onValueChanged: if (!hex.activeFocus) hex.text = value

          Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: Theme.r(11)
            color: colorRow.value
            border.width: 1
            border.color: Theme.border
          }
          Label {
            text: root.labels[colorRow.modelData] ?? colorRow.modelData
            font.pixelSize: Theme.font.small
            Layout.preferredWidth: 104
            elide: Text.ElideRight
          }
          TextField {
            id: hex
            Layout.fillWidth: true
            implicitWidth: 96
            implicitHeight: 30
            text: colorRow.value
            error: !Palettes.isValidColor(text)
            Accessible.name: (root.labels[colorRow.modelData] ?? colorRow.modelData) + " colour"
            onTextChanged: {
              const c = text.trim().toLowerCase();
              if (Palettes.isValidColor(c) && c !== colorRow.value) Palettes.update(root.theme.name, { [colorRow.modelData]: c });
            }
          }
          IconButton {
            icon: "pipette"
            size: 28
            accessibleName: "Pick " + (root.labels[colorRow.modelData] ?? colorRow.modelData) + " from the screen"
            checked: root.pickKey === colorRow.modelData
            onClicked: {
              root.pickKey = colorRow.modelData;
              picker.running = true;
            }
          }
        }
      }
    }

    Label {
      visible: Config.appearance.accent !== ""
      text: "The Accent row below overrides this theme's accent. Choose its first swatch to use the theme's own."
      kind: "muted"
      font.pixelSize: Theme.font.label
      wrapMode: Text.Wrap
      Layout.fillWidth: true
    }
  }
}
