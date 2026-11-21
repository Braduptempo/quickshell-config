// MainMenuButton.qml
// The button at the far left of the bar. Left click: the main menu.
// Right click: the launcher.
import QtQuick
import Quickshell
import "../../config"
import "../../components"
import "../../services"

BarItem {
  id: root

  required property ShellScreen screen
  readonly property bool open: Panels.mainMenuOpen && Panels.mainMenuScreen === screen

  active: open
  padding: 0
  accessibleName: open ? "Main menu, open" : "Main menu"

  Icon {
    name: "apps"
    size: 15
    color: root.open ? Theme.accent : Theme.text
    anchors.verticalCenter: parent.verticalCenter
  }

  onClicked: mouse => {
    if (mouse.button === Qt.RightButton) {
      Panels.mainMenuOpen = false;
      Launcher.toggle(root.screen);
    } else {
      Panels.toggleMainMenu(root.screen);
    }
  }
}
