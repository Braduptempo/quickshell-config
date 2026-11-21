// BluetoothHint.qml
// Shown instead of "No Bluetooth adapter found": what's wrong, the command
// that fixes it, and a button when the shell can do it for you.
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../config"
import "../../components"
import "../../services"

ColumnLayout {
  id: root

  visible: BluetoothCheck.missing
  spacing: 8

  RowLayout {
    Layout.fillWidth: true
    spacing: 10
    Icon { name: "bluetooth"; size: 16; color: Theme.warn }
    Label { Layout.fillWidth: true; text: BluetoothCheck.title; font.weight: Font.Bold; wrapMode: Text.Wrap }
  }

  Label {
    visible: text !== ""
    Layout.fillWidth: true
    text: BluetoothCheck.detail
    kind: "muted"
    font.pixelSize: Theme.font.small
    wrapMode: Text.Wrap
  }

  // The command, click to copy
  Rectangle {
    visible: BluetoothCheck.command !== ""
    Layout.fillWidth: true
    implicitHeight: commandLabel.implicitHeight + 16
    radius: Theme.r(10)
    color: commandMouse.containsMouse ? Theme.hover(Theme.item) : Theme.item

    Accessible.role: Accessible.Button
    Accessible.name: "Copy the command: " + BluetoothCheck.command

    Label {
      id: commandLabel
      anchors.left: parent.left
      anchors.right: copied.left
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 10
      anchors.rightMargin: 8
      text: BluetoothCheck.command
      font.family: "monospace"
      font.pixelSize: Theme.font.small
      wrapMode: Text.WrapAnywhere
    }
    Label {
      id: copied
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.rightMargin: 10
      text: copyTimer.running ? "Copied" : "Copy"
      kind: "muted"
      font.pixelSize: Theme.font.label
    }
    MouseArea {
      id: commandMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: {
        Quickshell.execDetached(["wl-copy", BluetoothCheck.command]);
        copyTimer.restart();
      }
    }
    Timer { id: copyTimer; interval: 1500 }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 8
    Button {
      visible: BluetoothCheck.canFix
      text: BluetoothCheck.fixing ? "Working…" : BluetoothCheck.fixLabel
      variant: "primary"
      size: Theme.size.buttonRow
      onClicked: BluetoothCheck.fix()
    }
    Button {
      text: "Check again"
      variant: "ghost"
      size: Theme.size.buttonRow
      onClicked: BluetoothCheck.check()
    }
  }
}
