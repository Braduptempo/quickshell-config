// ExtrasMenu.qml
// The menu under a bar extra (Panels.extrasMenu): what's using the mic,
// camera or screen; the waiting updates; the removable drives.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/sound"

PanelWindow {
  id: window

  readonly property string kind: Panels.extrasMenu
  readonly property bool shown: kind !== ""
  readonly property bool fromBottom: Config.bar.position === "bottom"
  readonly property string style: Config.animations.panelStyle

  screen: Panels.extrasScreen ?? Panels.focusedScreen()
  visible: shown || card.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-extras"
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors {
    top: !window.fromBottom
    bottom: window.fromBottom
    right: true
  }
  margins {
    top: 6
    bottom: 6
    // Right edge under the pill that opened it
    right: Math.max(0, (window.screen ? window.screen.width : 0) - Panels.extrasRight - 12)
  }
  implicitWidth: 340 + 24
  implicitHeight: card.implicitHeight + 24

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Panels.extrasMenu = ""
  }

  // Keeps the last content while fading out
  property string lastKind: "privacy"
  onKindChanged: if (kind !== "") lastKind = kind

  component Row2: RowLayout {
    id: line
    property string icon
    property string title
    property string subtitle
    property color tint: Theme.text
    default property alias actions: actionRow.data

    Layout.fillWidth: true
    spacing: 10

    Rectangle {
      implicitWidth: 32
      implicitHeight: 32
      radius: 16
      color: Theme.alpha(line.tint, 0.16)
      Icon { anchors.centerIn: parent; name: line.icon; size: 15; color: line.tint }
    }
    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1
      Label { text: line.title; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
      Label { visible: text !== ""; text: line.subtitle; kind: "muted"; font.pixelSize: Theme.font.label; elide: Text.ElideRight; Layout.fillWidth: true }
    }
    Row { id: actionRow; spacing: 6 }
  }

  GlassPanel {
    id: card

    x: 12
    width: 340
    implicitHeight: column.implicitHeight + 28
    height: implicitHeight
    focus: true
    transformOrigin: window.fromBottom ? Item.BottomRight : Item.TopRight

    opacity: window.shown ? 1 : 0
    y: 12 + (window.shown || window.style !== "slide" ? 0 : window.fromBottom ? 14 : -14)
    scale: window.shown || window.style !== "scale" ? 1 : 0.92

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on implicitHeight { NumberAnimation { duration: Theme.anim.fast } }

    Keys.onEscapePressed: Panels.extrasMenu = ""

    ColumnLayout {
      id: column
      x: 14
      y: 14
      width: parent.width - 28
      spacing: 10

      // --- Privacy ---------------------------------------------------------------------
      ColumnLayout {
        visible: window.lastKind === "privacy"
        Layout.fillWidth: true
        spacing: 10

        Label { text: "In use now"; kind: "label" }
        Row2 {
          visible: Privacy.micInUse
          icon: "mic"
          tint: Theme.error
          title: "Microphone · " + Privacy.since(Privacy.micSince)
          subtitle: Privacy.micApps.join(", ")
          Button { text: Sound.isMicMuted ? "Unmute" : "Mute"; variant: "ghost"; size: Theme.size.buttonRow; onClicked: Sound.toggleMicMute() }
        }
        Row2 {
          visible: Privacy.cameraInUse
          icon: "camera"
          tint: Theme.error
          title: "Camera · " + Privacy.since(Privacy.cameraSince)
          subtitle: Privacy.cameraApps.join(", ")
        }
        Row2 {
          visible: Privacy.screenInUse
          icon: "monitor"
          tint: Theme.error
          title: "Screen · " + Privacy.since(Privacy.screenSince)
          subtitle: Privacy.screenApps.concat(Capture.recording ? ["Screen recording"] : []).join(", ")
          Button { visible: Capture.recording; text: "Stop"; variant: "dangerSoft"; size: Theme.size.buttonRow; onClicked: Capture.stop() }
        }
        Label {
          visible: !Privacy.anyInUse
          text: "Nothing is using the microphone, camera or screen."
          kind: "muted"
          wrapMode: Text.Wrap
          Layout.fillWidth: true
        }
      }

      // --- Updates -----------------------------------------------------------------------
      ColumnLayout {
        visible: window.lastKind === "updates"
        Layout.fillWidth: true
        spacing: 8

        RowLayout {
          Layout.fillWidth: true
          Label { text: Updates.count + (Updates.count === 1 ? " update" : " updates"); kind: "title"; Layout.fillWidth: true }
          IconButton { icon: "restart"; size: 30; variant: "plain"; accessibleName: "Check again"; onClicked: Updates.check() }
        }
        Label {
          text: Updates.repo.length + " pacman · " + Updates.aur.length + " AUR · " + (Updates.checking ? "checking…" : Updates.ago(Updates.checkedAt))
          kind: "muted"
          font.pixelSize: Theme.font.small
        }
        Label {
          visible: Updates.kernel
          Layout.fillWidth: true
          wrapMode: Text.Wrap
          text: "Kernel update · restart afterwards to use it"
          color: Theme.warn
          font.pixelSize: Theme.font.small
        }
        Label {
          visible: !Updates.hasCheckupdates
          Layout.fillWidth: true
          wrapMode: Text.Wrap
          text: "Official packages need checkupdates: sudo pacman -S pacman-contrib"
          color: Theme.warn
          font.pixelSize: Theme.font.small
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: Math.min(220, packageList.contentHeight + 12)
          radius: Theme.radiusCard
          color: Theme.item
          visible: Updates.count > 0

          ListView {
            id: packageList
            anchors.fill: parent
            anchors.margins: 6
            clip: true
            model: Updates.repo.concat(Updates.aur.map(p => Object.assign({ aur: true }, p)))
            boundsBehavior: Flickable.StopAtBounds
            delegate: RowLayout {
              id: pkg
              required property var modelData
              width: packageList.width
              height: 24
              Label { Layout.leftMargin: 6; text: pkg.modelData.name; font.pixelSize: Theme.font.small; elide: Text.ElideRight; Layout.fillWidth: true }
              Label { visible: pkg.modelData.aur === true; text: "AUR"; kind: "muted"; font.pixelSize: Theme.font.label }
              Label { Layout.rightMargin: 6; text: pkg.modelData.to; kind: "muted"; font.pixelSize: Theme.font.label }
            }
          }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: 8
          Item { Layout.fillWidth: true }
          Button { text: "Later"; variant: "ghost"; size: Theme.size.buttonList; onClicked: Panels.extrasMenu = "" }
          Button {
            text: "Update now"
            variant: "primary"
            size: Theme.size.buttonList
            onClicked: {
              Panels.extrasMenu = "";
              Updates.updateNow();
            }
          }
        }
      }

      // --- Drives -------------------------------------------------------------------------
      ColumnLayout {
        visible: window.lastKind === "drives"
        Layout.fillWidth: true
        spacing: 10

        Label { text: "Drives"; kind: "label" }
        Label { visible: Drives.drives.length === 0; text: "No removable drives"; kind: "muted" }

        Repeater {
          model: Drives.drives

          Row2 {
            id: drive
            required property var modelData
            icon: "usb"
            tint: Theme.accent
            title: modelData.name
            subtitle: modelData.size + (modelData.mountpoint !== "" ? " · " + modelData.mountpoint : " · not mounted")

            Button {
              text: "Open"
              variant: "ghost"
              size: Theme.size.buttonRow
              onClicked: {
                Panels.extrasMenu = "";
                Drives.open(drive.modelData);
              }
            }
            Button {
              text: "Eject"
              variant: "ghost"
              size: Theme.size.buttonRow
              onClicked: Drives.eject(drive.modelData)
            }
          }
        }
      }
    }
  }
}
