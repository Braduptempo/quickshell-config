// ListRow.qml
// A row in a settings list: title, optional subtitle, and anything you put
// inside it (a Toggle, a Button…) on the right.
import QtQuick
import QtQuick.Layouts
import "../config"

Item {
  id: root

  property string title
  property string subtitle
  property color subtitleColor: Theme.subtext
  property bool first: false
  default property alias trailing: trailingRow.data

  implicitHeight: Math.max(Theme.size.row, layout.implicitHeight + 12)
  implicitWidth: 320

  Rectangle {
    visible: !root.first
    width: parent.width
    height: 1
    color: Theme.hairline
  }

  RowLayout {
    id: layout
    anchors.fill: parent
    anchors.leftMargin: 12
    anchors.rightMargin: 10
    spacing: 10

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2
      Label { text: root.title; Layout.fillWidth: true }
      Label {
        visible: root.subtitle !== ""
        text: root.subtitle
        kind: "small"
        color: root.subtitleColor
        font.pixelSize: Theme.font.label
        Layout.fillWidth: true
      }
    }

    Row {
      id: trailingRow
      spacing: 6
      Layout.alignment: Qt.AlignVCenter
    }
  }
}
