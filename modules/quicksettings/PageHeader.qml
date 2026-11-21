// PageHeader.qml
// Header of a detail page: back arrow, title, and an optional switch.
import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

RowLayout {
  id: root

  property string title
  property bool showToggle: false
  property bool checked: false
  default property alias extra: extraRow.data

  signal toggled(bool checked)

  spacing: 10

  IconButton {
    icon: "chevron-left"
    size: 34
    accessibleName: "Back to quick settings"
    onClicked: Panels.quickSettingsPage = "main"
  }

  Label {
    text: root.title
    kind: "title"
    Layout.fillWidth: true
  }

  Row {
    id: extraRow
    spacing: 6
  }

  Toggle {
    visible: root.showToggle
    checked: root.checked
    accessibleName: root.title
    onToggled: value => root.toggled(value)
  }
}
