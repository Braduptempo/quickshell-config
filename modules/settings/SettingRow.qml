// SettingRow.qml
// One setting: a title and a short explanation on the left, the control
// (Toggle, Segmented, slider…) on the right. Put the control inside.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

Rectangle {
  id: root

  property string title
  property string subtitle
  default property alias control: controlRow.data

  Layout.fillWidth: true
  implicitHeight: Math.max(56, textColumn.implicitHeight + 24)
  radius: Theme.radiusCard
  color: Theme.item

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 16
    anchors.rightMargin: 14
    spacing: 16

    ColumnLayout {
      id: textColumn
      Layout.fillWidth: true
      spacing: 3
      Label { text: root.title; font.weight: Font.Bold; Layout.fillWidth: true; elide: Text.ElideRight }
      Label {
        visible: text !== ""
        text: root.subtitle
        kind: "muted"
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
        Layout.fillWidth: true
      }
    }

    Row {
      id: controlRow
      spacing: 8
    }
  }
}
