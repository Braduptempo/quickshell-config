// EmptyState.qml
// What a panel shows when there's nothing to show: a big icon (crossed out
// for "off"), a title, a line of explanation and up to two buttons.
//   EmptyState { icon: "wifi"; crossed: true; title: "Wi-Fi is off"
//                text: "…"; action: "Turn on Wi-Fi"; onActivated: … }
import QtQuick
import QtQuick.Layouts
import "../config"

ColumnLayout {
  id: root

  property string icon
  property bool crossed: false
  property color iconColor: Theme.subtext
  property string title
  property string text
  // Main button (accent) and a second one; empty = no button
  property string action
  property string secondAction

  signal activated()
  signal secondActivated()

  spacing: 10

  Item {
    Layout.alignment: Qt.AlignHCenter
    Layout.topMargin: 12
    implicitWidth: 40
    implicitHeight: 40
    Icon { anchors.centerIn: parent; name: root.icon; size: 40; strokeWidth: 1.6; color: root.iconColor; opacity: root.crossed ? 0.35 : 1 }
    // The slash across an icon that is off
    Rectangle {
      visible: root.crossed
      anchors.centerIn: parent
      width: 50
      height: 1.6
      radius: 1
      rotation: 45
      color: root.iconColor
    }
  }

  Label {
    Layout.fillWidth: true
    text: root.title
    font.weight: Font.Bold
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
  }
  Label {
    visible: text !== ""
    Layout.fillWidth: true
    text: root.text
    kind: "muted"
    font.pixelSize: Theme.font.small
    horizontalAlignment: Text.AlignHCenter
    wrapMode: Text.Wrap
  }

  RowLayout {
    visible: root.action !== "" || root.secondAction !== ""
    Layout.fillWidth: true
    Layout.topMargin: 4
    Layout.bottomMargin: 4
    spacing: 8
    Button {
      visible: root.action !== ""
      Layout.fillWidth: true
      text: root.action
      variant: "primary"
      onClicked: root.activated()
    }
    Button {
      visible: root.secondAction !== ""
      Layout.fillWidth: true
      text: root.secondAction
      variant: "secondary"
      onClicked: root.secondActivated()
    }
  }
}
