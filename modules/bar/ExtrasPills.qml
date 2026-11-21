// ExtrasPills.qml
// Small pills on the right of the bar, each only when it has something to
// say: mic / camera / screen in use, high load, waiting updates, removable
// drives.
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
    // Which app, when it's just one
    Label {
      readonly property var apps: [...new Set(Privacy.micApps.concat(Privacy.cameraApps).concat(Privacy.screenApps))]
      visible: apps.length === 1
      text: apps[0] ?? ""
      color: Theme.error
      font.pixelSize: Theme.font.small
      width: Math.min(implicitWidth, 110)
      elide: Text.ElideRight
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  // Working hard: CPU or GPU at 90 % or more, or 85 °C
  BarItem {
    id: load
    visible: Config.bar.showLoad && SystemStats.heavy
    padding: 10
    activeColor: Theme.warn
    accessibleName: "High load: CPU " + Math.round(SystemStats.cpu) + " percent" + (SystemStats.gpu > 0 ? ", GPU " + Math.round(SystemStats.gpu) + " percent" : "")
                    + (SystemStats.hottest > 0 ? ", " + Math.round(SystemStats.hottest) + " degrees" : "")
    onClicked: Panels.openQuickSettings(root.screen, "system")

    Icon { name: "activity"; size: 14; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
    Label {
      text: Math.round(Math.max(SystemStats.cpu, SystemStats.gpu)) + "%"
      color: Theme.warn
      font.pixelSize: Theme.font.small
      anchors.verticalCenter: parent.verticalCenter
    }
    Label {
      visible: SystemStats.hottest > 0
      text: Math.round(SystemStats.hottest) + "°"
      color: Theme.warn
      font.pixelSize: Theme.font.small
      anchors.verticalCenter: parent.verticalCenter
    }
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
