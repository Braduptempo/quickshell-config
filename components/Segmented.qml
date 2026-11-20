// Segmented.qml
// One choice out of a few, as pills in a track. The selection slides over.
// model: list of labels. Emits activated(index) when the user picks one.
// It doesn't change currentIndex itself: bind currentIndex to your state and
// update that state in onActivated, so the two can never disagree.
pragma ComponentBehavior: Bound

import QtQuick
import "../config"

Item {
  id: root

  property var model: []
  property int currentIndex: 0
  property int itemHeight: 30
  property string accessibleName

  signal activated(int index)

  readonly property real itemWidth: model.length > 0 ? (width - 6 - (model.length - 1) * 3) / model.length : 0

  implicitHeight: itemHeight + 6
  // Every segment as wide as the widest label, so a longer one
  // ("Notifications · 12") never runs out of its pill
  implicitWidth: model.length > 0 ? 6 + model.length * measure.implicitWidth + (model.length - 1) * 3 : 0

  Accessible.role: Accessible.Grouping
  Accessible.name: accessibleName

  // Widest label + padding (a Column is as wide as its widest child);
  // bold, because the selected label is bold
  Column {
    id: measure
    visible: false
    Repeater {
      model: root.model
      Label { required property string modelData; text: modelData; kind: "small"; font.weight: Font.Bold; leftPadding: 14; rightPadding: 14 }
    }
  }

  Rectangle {
    anchors.fill: parent
    radius: Theme.pill(height)
    color: Theme.item
  }

  Rectangle {
    id: indicator
    y: 3
    height: root.itemHeight
    width: root.itemWidth
    x: 3 + root.currentIndex * (root.itemWidth + 3)
    radius: Theme.pill(height)
    color: Theme.overlay
    visible: root.currentIndex >= 0

    Behavior on x {
      NumberAnimation { duration: Theme.anim.segment; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.standard }
    }
  }

  Row {
    x: 3
    y: 3
    spacing: 3

    Repeater {
      model: root.model

      Item {
        id: segment
        required property string modelData
        required property int index

        width: root.itemWidth
        height: root.itemHeight

        Accessible.role: Accessible.RadioButton
        Accessible.name: modelData
        Accessible.checked: index === root.currentIndex

        Label {
          anchors.centerIn: parent
          text: segment.modelData
          kind: "small"
          font.weight: segment.index === root.currentIndex ? Font.Bold : Font.Normal
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activated(segment.index)
        }
      }
    }
  }
}
