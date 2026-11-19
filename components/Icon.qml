// Icon.qml
// A stroke icon from Icons.qml, drawn as a vector shape so it stays sharp
// at any size and takes the colour you give it.
import QtQuick
import QtQuick.Shapes
import "../config"

Item {
  id: root

  property string name
  property real size: 16
  property color color: Theme.text
  property real strokeWidth: 2
  // For solid glyphs such as play and pause
  property bool filled: name === "play" || name === "pause" || name === "next" || name === "previous"

  implicitWidth: size
  implicitHeight: size

  Shape {
    width: 24
    height: 24
    scale: root.size / 24
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.filled ? "transparent" : root.color
      fillColor: root.filled ? root.color : "transparent"
      strokeWidth: root.strokeWidth
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin

      PathSvg {
        path: Icons.paths[root.name] ?? ""
      }
    }
  }
}
