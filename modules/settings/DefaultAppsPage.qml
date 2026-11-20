// DefaultAppsPage.qml
// Which app opens what. Written with xdg-mime, so other apps follow the same
// choice; the terminal is the shell's own setting.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "Default apps"
  description: "Saved with xdg-mime in ~/.config/mimeapps.list, so other apps use the same choice. Quicklinks open in the browser; \"show in folder\" uses the file manager."

  Component.onCompleted: DefaultApps.refresh()

  // --- Terminal (the shell's own) --------------------------------------------------------
  SettingRow {
    title: "Terminal"
    subtitle: "Used by the shell to edit scripts, snippets and keybinds, and to show logs."

    Dropdown {
      width: 260
      readonly property var choices: DefaultApps.terminals.some(t => t.command === Config.apps.terminal)
        ? DefaultApps.terminals : [{ name: Config.apps.terminal, command: Config.apps.terminal }].concat(DefaultApps.terminals)
      model: choices.map(t => t.name + (t.name.toLowerCase() !== t.command ? " (" + t.command + ")" : ""))
      currentIndex: Math.max(0, choices.findIndex(t => t.command === Config.apps.terminal))
      accessibleName: "Terminal"
      onActivated: index => Config.apps.terminal = choices[index].command
    }
  }

  // --- Everything xdg-mime knows ----------------------------------------------------------
  Repeater {
    model: DefaultApps.kinds

    SettingRow {
      id: kindRow
      required property var modelData
      readonly property var options: DefaultApps.options[modelData.key] ?? []
      readonly property string currentId: DefaultApps.current[modelData.key] ?? ""
      // The current one first, even when it doesn't list the type itself
      readonly property var choices: currentId !== "" && options.indexOf(currentId) < 0 ? [currentId].concat(options) : options

      title: modelData.label
      subtitle: choices.length === 0 ? "No installed app opens this" : choices.length + (choices.length === 1 ? " app can open this" : " apps can open this")

      Dropdown {
        visible: kindRow.choices.length > 0
        width: 260
        model: kindRow.choices.map(id => DefaultApps.nameOf(id))
        currentIndex: Math.max(0, kindRow.choices.indexOf(kindRow.currentId))
        accessibleName: kindRow.modelData.label
        onActivated: index => DefaultApps.set(kindRow.modelData.key, kindRow.choices[index])
      }
    }
  }
}
