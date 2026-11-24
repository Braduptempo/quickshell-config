// Icon.qml
// The shell's stroke icons (components/Icons.qml), only the ones this login
// screen uses: SDDM can't read the shell's folder, so they're copied here.
import QtQuick
import QtQuick.Shapes

Item {
  id: root

  property string name
  property real size: 16
  property color color: "white"

  readonly property var paths: ({
    "lock": "M5 11h14v10H5zM8 11V7a4 4 0 0 1 8 0v4",
    "user": "M12 4a4 4 0 1 0 0 8a4 4 0 1 0 0-8M4 21a8 8 0 0 1 16 0",
    "eye": "M2 12c1-2.5 5-7 10-7s9 4.5 10 7c-1 2.5-5 7-10 7S3 14.5 2 12zM12 9a3 3 0 1 0 0 6a3 3 0 1 0 0-6",
    "eye-off": "M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.1A10 10 0 0 1 12 5c5 0 9 4.5 10 7a13 13 0 0 1-3 4.2M6.6 6.6C4.3 8 2.7 10.1 2 12c1 2.5 5 7 10 7a10 10 0 0 0 4.4-1",
    "arrow-right": "M5 12h14M13 6l6 6-6 6",
    "warning": "M12 3 2 20h20zM12 10v4M12 17h.01",
    "chevron-up": "M6 15l6-6 6 6",
    "chevron-left": "M15 6l-6 6 6 6",
    "chevron-right": "M9 6l6 6-6 6",
    "check": "M5 12l5 5 9-10",
    "moon": "M21 13A9 9 0 1 1 11 3a7 7 0 0 0 10 10z",
    "restart": "M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5",
    "power": "M12 2v10M18.4 6.6a9 9 0 1 1-12.8 0",
    "keyboard": "M2 6h20v12H2zM6 10h.01M10 10h.01M14 10h.01M18 10h.01M7 14h10",
    "monitor": "M3 4h18v12H3zM8 20h8M12 16v4"
  })

  implicitWidth: size
  implicitHeight: size

  Shape {
    width: 24
    height: 24
    scale: root.size / 24
    transformOrigin: Item.TopLeft
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.color
      fillColor: "transparent"
      strokeWidth: 2
      capStyle: ShapePath.RoundCap
      joinStyle: ShapePath.RoundJoin

      PathSvg { path: root.paths[root.name] ?? "" }
    }
  }
}
