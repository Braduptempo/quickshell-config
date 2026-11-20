// ExtrasPills.qml
// Small pills on the right of the bar, each only when it has something to
// say: mic / camera / screen in use, waiting updates, removable drives.
// Click one for its menu (modules/bar/ExtrasMenu.qml). Settings → Bar &
// panels turns each off.
import QtQuick
import Quickshell
import "../../config"
import "../../components"
import "../../services"

Row {
  id: root

  required property ShellScreen screen

  spacing: 6

  function open(kind: string, item: Item): void {
    const p = item.mapToItem(null, item.width, 0);
    Panels.toggleExtras(kind, root.screen, p.x);
  }

  // Privacy: red-ish while anything listens or watches
  BarItem {
    id: privacy
    visible: Config.bar.showPrivacy && Privacy.anyInUse
    padding: 10
    active: Panels.extrasMenu === "privacy" && Panels.extrasScreen === root.screen
    activeColor: Theme.error
    accessibleName: "In use: " + [Privacy.micInUse ? "microphone" : "", Privacy.cameraInUse ? "camera" : "", Privacy.screenInUse ? "screen" : ""].filter(s => s !== "").join(", ")
    onClicked: root.open("privacy", privacy)

    Icon { visible: Privacy.micInUse; name: "mic"; size: 14; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.cameraInUse; name: "camera"; size: 14; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
    Icon { visible: Privacy.screenInUse; name: "monitor"; size: 14; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
  }

  // Updates waiting
  BarItem {
    id: updates
    visible: Config.bar.showUpdates && Updates.count > 0
    padding: 10
    active: Panels.extrasMenu === "updates" && Panels.extrasScreen === root.screen
    accessibleName: Updates.count + " updates"
    onClicked: root.open("updates", updates)

    Icon { name: "download"; size: 14; color: Updates.kernel ? Theme.warn : Theme.accent; anchors.verticalCenter: parent.verticalCenter }
    Label { text: Updates.count; font.weight: Font.Bold; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
  }

  // Removable drives
  BarItem {
    id: drives
    visible: Config.bar.showDrives && Drives.drives.length > 0
    padding: 0
    active: Panels.extrasMenu === "drives" && Panels.extrasScreen === root.screen
    accessibleName: Drives.drives.length + (Drives.drives.length === 1 ? " drive" : " drives")
    onClicked: root.open("drives", drives)

    Icon { name: "usb"; size: 15; color: drives.active ? Theme.accent : Theme.text; anchors.verticalCenter: parent.verticalCenter }
  }
}
