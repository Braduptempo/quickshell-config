// SettingsPage.qml
// A settings page: the title and a scrolling column for its rows.
// Optional: a function reset() on the page, shown as "Reset to default".
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"

Flickable {
  id: root

  property string title
  property string description
  // A page that can be reset sets this
  property var resetAction: null
  default property alias content: column.data

  contentHeight: column.implicitHeight + 8
  clip: true
  boundsBehavior: Flickable.StopAtBounds

  ColumnLayout {
    id: column
    width: root.width
    spacing: 10

    Label { text: root.title; kind: "title"; font.pixelSize: Theme.font.title + 4 }
    Label {
      visible: text !== ""
      text: root.description
      kind: "muted"
      wrapMode: Text.Wrap
      Layout.fillWidth: true
      Layout.bottomMargin: 6
    }
  }
}
