// SoonPage.qml
// A section that isn't built yet.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

SettingsPage {
  id: page
  property string hint

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 140
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      anchors.centerIn: parent
      width: parent.width - 60
      spacing: 8
      Icon { name: "settings"; size: 26; color: Theme.subtext; Layout.alignment: Qt.AlignHCenter }
      Label { text: "Coming in a later update"; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
      Label {
        text: page.hint
        kind: "muted"
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        Layout.fillWidth: true
      }
    }
  }
}
