// PowerMenu.qml
// Lock, suspend, log out, restart and shut down (Super + Esc).
//   ← →            choose            L S E R P   choose directly
//   Enter          confirm           Tab         when: now, in 15 min, 30 min, 1 h
//   Esc            back / close
// Log out, restart and shut down count down from 10 s and then happen by
// themselves; pick a later time to schedule them instead.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../config"
import "../../components"
import "../../services"

PanelWindow {
  id: window

  readonly property bool shown: Power.open
  // Index into Power.actions, -1 = nothing chosen
  property int selected: -1
  // Index into whenOptions
  property int when: 0
  property int countdown: 10

  readonly property var whenOptions: [
    { label: "Now", minutes: 0 },
    { label: "In 15 min", minutes: 15 },
    { label: "In 30 min", minutes: 30 },
    { label: "In 1 h", minutes: 60 }
  ]
  readonly property var current: selected >= 0 ? Power.actions[selected] : null
  readonly property bool needsConfirm: current !== null && !current.instant
  readonly property color tone: toneColor(current?.tone ?? "accent")

  component MoreButton: Rectangle {
    id: more
    property string icon
    property string text
    property string hint
    property bool available: true
    signal clicked()

    implicitHeight: 30
    implicitWidth: moreRow.implicitWidth + 24
    radius: Theme.pill(height)
    color: moreMouse.containsMouse && available ? Theme.item : "transparent"
    border.width: 1
    border.color: Theme.border
    opacity: available ? 1 : 0.5

    Accessible.role: Accessible.Button
    Accessible.name: text + (hint !== "" ? ", " + hint : "")

    Row {
      id: moreRow
      anchors.centerIn: parent
      spacing: 7
      Icon { name: more.icon; size: 13; color: Theme.text; anchors.verticalCenter: parent.verticalCenter }
      Label { text: more.text; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
    }

    MouseArea {
      id: moreMouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: more.available ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: if (more.available) more.clicked()
    }
  }

  function toneColor(name: string): color {
    switch (name) {
    case "warn": return Theme.warn;
    case "orange": return Theme.palette.dots[1] ?? Theme.warn;
    case "error": return Theme.error;
    default: return Theme.accent;
    }
  }

  screen: Power.screen ?? Panels.focusedScreen()
  visible: shown || backdrop.opacity > 0
  color: "transparent"

  WlrLayershell.namespace: "quickshell-power"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Ignore
  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  function choose(index: int): void {
    selected = index;
    when = 0;
    countdown = 10;
  }

  function move(step: int): void {
    const count = Power.actions.length;
    choose(selected < 0 ? (step > 0 ? 0 : count - 1) : (selected + step + count) % count);
  }

  function confirm(): void {
    const action = current;
    if (!action) return;
    Power.open = false;
    if (!action.instant && when > 0) {
      Power.schedule(action.id, whenOptions[when].minutes);
      Quickshell.execDetached(["notify-send", "-a", "Power", action.label + " at " + Power.scheduledTime,
                               "A reminder comes 1 minute before. Cancel it in the power menu."]);
    } else {
      runDelay.actionId = action.id;
      runDelay.restart();
    }
  }

  // Let the menu fade out before the screen locks or the session ends
  Timer {
    id: runDelay
    property string actionId: ""
    interval: Theme.anim.panelOut + 60
    onTriggered: Power.run(actionId)
  }

  function back(): void {
    if (selected >= 0) selected = -1;
    else Power.open = false;
  }

  onShownChanged: {
    if (shown) {
      const start = Power.actions.findIndex(a => a.key === Power.initialKey);
      if (start >= 0) choose(start);
      else selected = -1;
      when = 0;
      firmwareButton.firmwarePending = false;
      keys.forceActiveFocus();
    }
  }

  // Counts down while a confirm action is chosen for "Now"
  Timer {
    running: window.shown && window.needsConfirm && window.when === 0
    interval: 1000
    repeat: true
    onTriggered: {
      window.countdown--;
      if (window.countdown <= 0) window.confirm();
    }
  }

  HyprlandFocusGrab {
    active: window.shown
    windows: [window]
    onCleared: Power.open = false
  }

  // --- Dim the screen; clicking it closes ----------------------------------------------
  Rectangle {
    id: backdrop
    anchors.fill: parent
    color: Theme.alpha(Theme.crust, 0.45)
    opacity: window.shown ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }

    MouseArea {
      anchors.fill: parent
      onClicked: Power.open = false
    }
  }

  Item {
    id: keys
    focus: true
    Keys.onPressed: event => {
      const letter = event.text.toUpperCase();
      const index = Power.actions.findIndex(a => a.key === letter);
      if (index >= 0 && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
        window.choose(index);
      } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
        window.move(-1);
      } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
        window.move(1);
      } else if (event.key === Qt.Key_Tab && window.needsConfirm) {
        window.when = (window.when + 1) % window.whenOptions.length;
        window.countdown = 10;
      } else if (event.key === Qt.Key_Backtab && window.needsConfirm) {
        window.when = (window.when + window.whenOptions.length - 1) % window.whenOptions.length;
        window.countdown = 10;
      } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
        window.confirm();
      } else if (event.key === Qt.Key_Escape) {
        window.back();
      } else {
        return;
      }
      event.accepted = true;
    }
  }

  // --- The card ---------------------------------------------------------------------------
  GlassPanel {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round(parent.height * 0.46 - height / 2) + (window.shown ? 0 : 12)
    width: 720
    height: column.implicitHeight + 44
    radius: Theme.r(24)
    color: Theme.panelSolid
    opacity: window.shown ? 1 : 0
    scale: window.shown ? 1 : 0.97

    Accessible.role: Accessible.Dialog
    Accessible.name: "Power menu"

    Behavior on opacity { NumberAnimation { duration: window.shown ? Theme.anim.panelIn : Theme.anim.panelOut } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on scale { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    Behavior on height { NumberAnimation { duration: Theme.anim.fast } }

    // Clicks on the card don't close the menu
    MouseArea { anchors.fill: parent }

    ColumnLayout {
      id: column
      x: 22
      y: 22
      width: parent.width - 44
      spacing: 18

      // --- Header ----------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Rectangle {
          implicitWidth: 44
          implicitHeight: 44
          radius: Theme.r(22)
          color: Theme.surface
          border.width: 2
          border.color: Theme.accent

          Icon { anchors.centerIn: parent; visible: avatar.status !== Image.Ready; name: "user"; size: 20; color: Theme.subtext }
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

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Label { text: Lock.displayName; kind: "title" }
          Label {
            text: [Power.uptime, Power.system, "Hyprland"].filter(t => t !== "").join(" · ")
            kind: "muted"
            font.pixelSize: Theme.font.small
          }
        }

        Kbd { text: "Super + Esc" }
        IconButton { icon: "close"; size: 34; accessibleName: "Close power menu"; onClicked: Power.open = false }
      }

      // --- Scheduled for later --------------------------------------------------------------
      Rectangle {
        visible: Power.scheduled
        Layout.fillWidth: true
        implicitHeight: 48
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.warn, 0.12)
        border.width: 1
        border.color: Theme.alpha(Theme.warn, 0.4)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 6
          spacing: 10
          Icon { name: "clock"; size: 15; color: Theme.warn }
          Label {
            Layout.fillWidth: true
            text: (Power.action(Power.scheduledId)?.label ?? "") + " at " + Power.scheduledTime
            color: Theme.warn
            font.weight: Font.Bold
          }
          Button { text: "Cancel"; size: Theme.size.buttonList; variant: "ghost"; onClicked: Power.cancelSchedule() }
        }
      }

      // --- The five actions ---------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Repeater {
          model: Power.actions

          Rectangle {
            id: tile
            required property var modelData
            required property int index
            readonly property bool active: window.selected === index
            readonly property color toneColor: window.toneColor(modelData.tone)

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            implicitHeight: tileColumn.implicitHeight + 26
            radius: Theme.r(20)
            color: active ? Theme.alpha(toneColor, 0.12) : tileMouse.containsMouse ? Theme.item : "transparent"
            border.width: 1
            border.color: active ? Theme.alpha(toneColor, 0.5) : "transparent"

            Accessible.role: Accessible.Button
            Accessible.name: modelData.label + ", shortcut " + modelData.key
            Accessible.checked: active

            Behavior on color { ColorAnimation { duration: Theme.anim.fast } }

            ColumnLayout {
              id: tileColumn
              anchors.centerIn: parent
              spacing: 10

              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 64
                implicitHeight: 64
                radius: Theme.r(32)
                color: tile.active ? tile.toneColor : Theme.item
                scale: tileMouse.pressed ? 0.94 : tileMouse.containsMouse && !tile.active ? 1.04 : 1

                Behavior on color { ColorAnimation { duration: Theme.anim.fast } }
                Behavior on scale { NumberAnimation { duration: Theme.anim.fast } }

                Icon {
                  anchors.centerIn: parent
                  name: tile.modelData.icon
                  size: 24
                  strokeWidth: 2
                  color: tile.active ? Theme.onAccent : tile.modelData.id === "poweroff" ? Theme.error : Theme.text
                }
              }

              Label {
                Layout.alignment: Qt.AlignHCenter
                text: tile.modelData.label
                font.weight: tile.active ? Font.Bold : Font.Normal
              }

              Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.max(20, keyLabel.implicitWidth + 12)
                implicitHeight: 20
                radius: Theme.r(10)
                color: Theme.alpha(Theme.crust, 0.5)
                Label { id: keyLabel; anchors.centerIn: parent; text: tile.modelData.key; kind: "muted"; font.pixelSize: Theme.font.label }
              }
            }

            MouseArea {
              id: tileMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (tile.active) window.confirm();
                else window.choose(tile.index);
              }
            }
          }
        }
      }

      // --- Nothing chosen ---------------------------------------------------------------------
      Rectangle {
        visible: window.current === null
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.crust, 0.35)
        Label { anchors.centerIn: parent; text: "Choose an action, or press its letter"; kind: "muted" }
      }

      // --- Lock and suspend: one click -----------------------------------------------------------
      Rectangle {
        visible: window.current !== null && window.current.instant
        Layout.fillWidth: true
        implicitHeight: 52
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.crust, 0.45)

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 18
          anchors.rightMargin: 8
          spacing: 12
          Label { Layout.fillWidth: true; text: window.current?.text ?? ""; color: Theme.subtext }
          Button { text: window.current?.verb ?? ""; variant: "primary"; onClicked: window.confirm() }
        }
      }

      // --- Log out, restart, shut down: confirm, or schedule ----------------------------------
      Rectangle {
        visible: window.needsConfirm
        Layout.fillWidth: true
        implicitHeight: confirmColumn.implicitHeight + 28
        radius: Theme.r(18)
        color: Theme.alpha(Theme.crust, 0.45)
        border.width: 1
        border.color: Theme.alpha(window.tone, 0.35)

        ColumnLayout {
          id: confirmColumn
          x: 14
          y: 14
          width: parent.width - 28
          spacing: 12

          RowLayout {
            Layout.fillWidth: true
            spacing: 14

            // Countdown ring for "Now"
            Item {
              implicitWidth: 44
              implicitHeight: 44

              Canvas {
                id: ring
                anchors.fill: parent
                visible: window.when === 0
                readonly property real progress: window.countdown / 10
                onProgressChanged: requestPaint()
                onVisibleChanged: requestPaint()
                onPaint: {
                  const ctx = getContext("2d");
                  ctx.reset();
                  ctx.lineWidth = 4;
                  ctx.lineCap = "round";
                  ctx.strokeStyle = Theme.overlay;
                  ctx.beginPath();
                  ctx.arc(22, 22, 18, 0, Math.PI * 2);
                  ctx.stroke();
                  ctx.strokeStyle = window.tone;
                  ctx.beginPath();
                  ctx.arc(22, 22, 18, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * progress);
                  ctx.stroke();
                }
              }

              Label {
                visible: window.when === 0
                anchors.centerIn: parent
                text: window.countdown + "s"
                font.weight: Font.Bold
                font.pixelSize: Theme.font.small
              }

              Rectangle {
                visible: window.when > 0
                anchors.fill: parent
                radius: Theme.r(22)
                color: Theme.alpha(window.tone, 0.18)
                Icon { anchors.centerIn: parent; name: "clock"; size: 18; color: window.tone }
              }
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 3
              Label {
                text: window.when === 0 ? (window.current?.verb ?? "") + " now?"
                    : (window.current?.verb ?? "") + " " + window.whenOptions[window.when].label.toLowerCase()
                font.weight: Font.Bold
                font.pixelSize: Theme.font.title - 1
              }
              Label {
                Layout.fillWidth: true
                text: window.when === 0 ? (window.current?.text ?? "") + " Happens by itself in " + window.countdown + " s."
                    : "A reminder comes 1 minute before. Cancel it here."
                kind: "muted"
                font.pixelSize: Theme.font.small
                wrapMode: Text.Wrap
              }
            }

            Button { text: "Cancel"; variant: "ghost"; onClicked: window.selected = -1 }
            Button {
              text: window.when === 0 ? (window.current?.verb ?? "") : "Schedule"
              variant: window.current?.tone === "error" ? "danger" : "primary"
              onClicked: window.confirm()
            }
          }

          RowLayout {
            spacing: 10
            Label { Layout.preferredWidth: 60; text: "When"; kind: "muted"; font.pixelSize: Theme.font.label }
            Segmented {
              model: window.whenOptions.map(o => o.label)
              currentIndex: window.when
              accessibleName: "When"
              onActivated: index => {
                window.when = index;
                window.countdown = 10;
              }
            }
          }
        }
      }

      // --- More -------------------------------------------------------------------------------------
      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Label { text: "More"; kind: "muted"; font.pixelSize: Theme.font.label; Layout.rightMargin: 4 }

        MoreButton {
          id: firmwareButton
          icon: "monitor"
          text: firmwarePending ? "Click again to restart" : "Restart to firmware"
          hint: "Restarts into the BIOS / UEFI settings"
          property bool firmwarePending: false
          onClicked: {
            if (firmwarePending) {
              Power.open = false;
              runDelay.actionId = "firmware";
              runDelay.restart();
            } else {
              firmwarePending = true;
              firmwareReset.restart();
            }
          }
          Timer { id: firmwareReset; interval: 4000; onTriggered: firmwareButton.firmwarePending = false }
        }
        MoreButton {
          icon: "restart"
          text: "Reload shell"
          hint: "Restarts Quickshell, apps stay open"
          onClicked: {
            Power.open = false;
            Quickshell.reload(false);
          }
        }
        MoreButton {
          icon: "moon"
          text: "Hibernate"
          hint: Power.canHibernate ? "Saves everything to disk and turns off" : "Needs a swap partition or swap file (zram doesn't count)"
          available: Power.canHibernate
          onClicked: {
            Power.open = false;
            runDelay.actionId = "hibernate";
            runDelay.restart();
          }
        }

        Item { Layout.fillWidth: true }

        Label {
          visible: !Power.canHibernate
          text: "Hibernate needs swap on disk"
          kind: "muted"
          font.pixelSize: Theme.font.label
        }
      }

      // --- Keys -----------------------------------------------------------------------------------------
      Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 14
        Row { spacing: 6; Kbd { text: "← →" } Label { text: "choose"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "L S E R P" } Label { text: "direct"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Tab" } Label { text: "when"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Enter" } Label { text: "confirm"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
        Row { spacing: 6; Kbd { text: "Esc" } Label { text: "close"; kind: "muted"; font.pixelSize: Theme.font.label; anchors.verticalCenter: parent.verticalCenter } }
      }
    }
  }
}
