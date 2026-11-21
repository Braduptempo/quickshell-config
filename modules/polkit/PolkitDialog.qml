// PolkitDialog.qml
// "Authentication required": asks for your password when an app needs
// administrator rights. The rest of the screen is dimmed and blocked until
// you authenticate or cancel (Esc). The state lives in services/Polkit.qml.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Polkit.shown
  readonly property bool ok: Polkit.state === "ok"
  readonly property bool cancelled: Polkit.state === "cancelled"
  readonly property bool wrong: Polkit.state === "wrong"
  property bool details: false

  screen: Panels.focusedScreen()
  visible: shown || backdrop.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-polkit"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  onShownChanged: {
    // Never keep a password around
    field.text = "";
    if (shown) {
      details = false;
      field.forceActiveFocus();
      Lock.refreshKeyboard();
    }
  }

  Connections {
    target: Polkit
    function onFailuresChanged() {
      field.text = "";
      shakeAnim.restart();
      field.forceActiveFocus();
    }
  }

  // Dimmed and blocked: clicks here do nothing
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.alpha(Theme.crust, 0.6)
    opacity: window.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }

    MouseArea {
      anchors.fill: parent
      onClicked: field.forceActiveFocus()
    }
  }

  GlassPanel {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((parent.height - height) / 2) + (window.shown ? 0 : 10)
    width: 440
    height: column.implicitHeight + 44
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.88))
    opacity: window.shown ? 1 : 0
    scale: window.shown ? 1 : 0.97

    Accessible.role: Accessible.Dialog
    Accessible.name: title.text

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on height { NumberAnimation { duration: Theme.anim.fast } }

    ColumnLayout {
      id: column
      x: 22
      y: 22
      width: parent.width - 44
      spacing: 16

      // --- Title -------------------------------------------------------------------
      RowLayout {
        spacing: 14

        Rectangle {
          implicitWidth: 48
          implicitHeight: 48
          radius: 24
          color: window.ok ? Theme.alpha(Theme.good, 0.18) : window.cancelled ? Theme.overlay : Theme.alpha(Theme.warn, 0.18)

          Icon {
            anchors.centerIn: parent
            name: window.ok ? "check" : window.cancelled ? "close" : "shield"
            size: 22
            strokeWidth: 2
            color: window.ok ? Theme.good : window.cancelled ? Theme.text : Theme.warn
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Label {
            id: title
            text: window.ok ? "Authenticated" : window.cancelled ? "Cancelled" : "Authentication required"
            kind: "title"
            font.pixelSize: Theme.font.title + 1
          }
          Label {
            text: window.ok ? "Going ahead" : window.cancelled ? "Nothing was changed" : "An app wants administrator rights"
            kind: "muted"
            font.pixelSize: Theme.font.small
          }
        }
      }

      // --- What it's for ---------------------------------------------------------------
      Rectangle {
        Layout.fillWidth: true
        implicitHeight: messageColumn.implicitHeight + 24
        radius: 14
        color: Theme.alpha(Theme.crust, 0.45)

        ColumnLayout {
          id: messageColumn
          x: 14
          y: 12
          width: parent.width - 28
          spacing: 6

          Label {
            Layout.fillWidth: true
            text: Polkit.message
            wrapMode: Text.Wrap
            lineHeight: 1.3
          }

          Rectangle {
            implicitHeight: 24
            implicitWidth: detailsRow.implicitWidth + 16
            radius: 12
            color: detailsMouse.containsMouse ? Theme.item : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: window.details ? "Hide details" : "Show details"

            Row {
              id: detailsRow
              anchors.verticalCenter: parent.verticalCenter
              x: 6
              spacing: 6
              Icon {
                name: "chevron-right"
                size: 10
                strokeWidth: 3
                color: Theme.subtext
                rotation: window.details ? 90 : 0
                anchors.verticalCenter: parent.verticalCenter
                Behavior on rotation { NumberAnimation { duration: Theme.anim.fast } }
              }
              Label { text: "Details"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter }
            }

            MouseArea {
              id: detailsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: window.details = !window.details
            }
          }

          GridLayout {
            visible: window.details
            columns: 2
            columnSpacing: 10
            rowSpacing: 6
            Label { text: "Action"; kind: "muted"; font.pixelSize: Theme.font.label }
            Label { text: Polkit.actionId; font.pixelSize: Theme.font.label; wrapMode: Text.WrapAnywhere; Layout.fillWidth: true }
            Label { text: "Agent"; kind: "muted"; font.pixelSize: Theme.font.label }
            Label { text: "Quickshell"; font.pixelSize: Theme.font.label }
          }
        }
      }

      // --- Password ------------------------------------------------------------------------
      ColumnLayout {
        visible: !window.ok && !window.cancelled
        Layout.fillWidth: true
        spacing: 10

        RowLayout {
          spacing: 10

          Rectangle {
            implicitWidth: 30
            implicitHeight: 30
            radius: 15
            color: Theme.surface
            border.width: 2
            border.color: Theme.accent

            Icon { anchors.centerIn: parent; visible: avatar.status !== Image.Ready; name: "user"; size: 14; color: Theme.subtext }
            Image { id: avatar; anchors.fill: parent; anchors.margins: 2; source: Lock.avatar; fillMode: Image.PreserveAspectCrop; visible: false }
            MultiEffect {
              anchors.fill: avatar
              source: avatar
              visible: avatar.status === Image.Ready
              maskEnabled: true
              maskSource: avatarMask
            }
            Rectangle { id: avatarMask; anchors.fill: avatar; radius: width / 2; visible: false; layer.enabled: true }
          }

          Label { Layout.fillWidth: true; text: Lock.displayName; font.weight: Font.Bold }
          Label { text: "Administrator"; kind: "muted"; font.pixelSize: Theme.font.label }
        }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Theme.pill(height)
          color: Theme.item
          border.width: 1
          border.color: window.wrong ? Theme.error : Theme.accent

          transform: Translate { id: shake }

          TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 18
            verticalAlignment: TextInput.AlignVCenter
            echoMode: Polkit.echo ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.font.family
            font.pixelSize: Theme.font.title
            font.letterSpacing: Polkit.echo ? 0 : 3
            clip: true
            focus: true
            readOnly: Polkit.state === "checking" || !Polkit.needsInput
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

            Accessible.role: Accessible.EditableText
            Accessible.name: "Password"
            Accessible.passwordEdit: !Polkit.echo

            Keys.onPressed: event => { if (event.key === Qt.Key_CapsLock) Lock.capsChanged(); }
            Keys.onReturnPressed: Polkit.submit(text)
            Keys.onEnterPressed: Polkit.submit(text)
            Keys.onEscapePressed: Polkit.cancel()

            Label {
              visible: field.text === ""
              anchors.verticalCenter: parent.verticalCenter
              text: Polkit.state === "checking" ? "Checking…" : "Your password"
              kind: "muted"
              font.pixelSize: Theme.font.title
            }
          }
        }

        SequentialAnimation {
          id: shakeAnim
          NumberAnimation { target: shake; property: "x"; to: -7; duration: 45 }
          NumberAnimation { target: shake; property: "x"; to: 7; duration: 90 }
          NumberAnimation { target: shake; property: "x"; to: -7; duration: 90 }
          NumberAnimation { target: shake; property: "x"; to: 7; duration: 90 }
          NumberAnimation { target: shake; property: "x"; to: 0; duration: 45 }
        }

        // Caps Lock on: the most common reason a password is "wrong"
        Rectangle {
          visible: Lock.capsLock
          implicitHeight: 26
          implicitWidth: polkitCaps.implicitWidth + 24
          radius: Theme.pill(height)
          color: Theme.alpha(Theme.warn, 0.14)

          Accessible.role: Accessible.AlertMessage
          Accessible.name: "Caps Lock is on"

          Row {
            id: polkitCaps
            anchors.centerIn: parent
            spacing: 6
            Icon { name: "caps"; size: 13; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
            Label { text: "Caps Lock is on"; color: Theme.warn; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
          }
        }

        Rectangle {
          visible: window.wrong || (Polkit.note !== "" && Polkit.noteIsError)
          implicitHeight: 26
          implicitWidth: Math.min(wrongLabel.implicitWidth + 24, column.width)
          radius: Theme.pill(height)
          color: Theme.alpha(Theme.error, 0.14)

          Accessible.role: Accessible.AlertMessage
          Accessible.name: wrongLabel.text

          Label {
            id: wrongLabel
            anchors.centerIn: parent
            width: Math.min(implicitWidth, column.width - 24)
            elide: Text.ElideRight
            text: Polkit.note !== "" && Polkit.noteIsError ? Polkit.note : "Wrong password, try again"
            color: Theme.error
            font.pixelSize: Theme.font.small
          }
        }

        Label {
          visible: Polkit.note !== "" && !Polkit.noteIsError
          Layout.fillWidth: true
          text: Polkit.note
          kind: "muted"
          font.pixelSize: Theme.font.small
          wrapMode: Text.Wrap
        }
      }

      // --- Buttons -------------------------------------------------------------------------
      RowLayout {
        visible: !window.ok && !window.cancelled
        Layout.fillWidth: true
        spacing: 8

        Label {
          Layout.fillWidth: true
          text: "Esc cancels"
          kind: "muted"
          font.pixelSize: Theme.font.label
          elide: Text.ElideRight
        }
        Button { text: "Cancel"; variant: "ghost"; onClicked: Polkit.cancel() }
        Button { text: "Authenticate"; variant: "primary"; onClicked: Polkit.submit(field.text) }
      }
    }
  }
}
