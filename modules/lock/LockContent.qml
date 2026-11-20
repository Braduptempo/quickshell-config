// LockContent.qml
// What one monitor shows while locked: the blurred wallpaper, status, the
// clock, the unlock card, what's playing and the power buttons.
// Every monitor shows the same; the password text is shared, so it doesn't
// matter which one has the keyboard.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris
import "../../config"
import "../../components"
import "../../services"
import "../../widgets/network"
import "../../widgets/sound"
import "../../widgets/battery"

Item {
  id: root

  required property ShellScreen screen

  readonly property bool resting: Lock.state === "rest"
  readonly property bool wrong: Lock.state === "wrong"
  readonly property bool ok: Lock.state === "ok"
  readonly property color ring: ok ? Theme.good : wrong ? Theme.error : Theme.accent

  // Keys typed while only the clock shows start the password
  focus: true
  Keys.onPressed: event => {
    if (root.resting && event.text !== "" && event.text.charCodeAt(0) >= 32) {
      Lock.wake();
      Lock.typed = event.text;
      field.forceActiveFocus();
      field.cursorPosition = field.text.length;
      event.accepted = true;
    } else if (root.resting && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
      Lock.wake();
      field.forceActiveFocus();
      event.accepted = true;
    } else if (event.key === Qt.Key_CapsLock) {
      Lock.capsChanged();
    } else if (event.key === Qt.Key_Escape && Lock.preview) {
      // Only the preview can be closed like this
      Lock.preview = false;
      event.accepted = true;
    }
  }

  onRestingChanged: {
    if (resting) root.forceActiveFocus();
    else field.forceActiveFocus();
  }

  Component.onCompleted: forceActiveFocus()

  // --- Background ----------------------------------------------------------------
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0; color: Theme.surface }
      GradientStop { position: 1; color: Theme.crust }
    }
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: Lock.wallpapers[root.screen?.name ?? ""] ?? ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: wallpaper
    visible: wallpaper.status === Image.Ready
    blurEnabled: true
    blurMax: 64
    blur: root.resting ? 0.7 : 1
    saturation: 0.1

    Behavior on blur { NumberAnimation { duration: Theme.anim.stack } }
  }

  // Darker while typing, so the card stands out
  Rectangle {
    anchors.fill: parent
    color: Theme.alpha(Theme.crust, root.resting ? 0.3 : 0.5)
    Behavior on color { ColorAnimation { duration: Theme.anim.stack } }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      Lock.wake();
      field.forceActiveFocus();
    }
  }

  // --- Top: locked since, and status ------------------------------------------------
  component GlassPill: Rectangle {
    implicitHeight: 36
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.55))
    border.width: 1
    border.color: Theme.border
  }

  GlassPill {
    x: 32
    y: 28
    implicitWidth: lockedRow.implicitWidth + 28

    Row {
      id: lockedRow
      anchors.centerIn: parent
      spacing: 8
      Icon { name: "lock"; size: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
      Label { text: "Locked since " + Qt.formatDateTime(Lock.lockedAt, "HH:mm"); anchors.verticalCenter: parent.verticalCenter }
    }
  }

  NetworkManager { id: network }

  GlassPill {
    anchors.right: parent.right
    anchors.rightMargin: 32
    y: 28
    implicitWidth: statusRow.implicitWidth + 18

    Accessible.role: Accessible.StatusBar
    Accessible.name: "Status"

    Row {
      id: statusRow
      anchors.verticalCenter: parent.verticalCenter
      x: 14
      spacing: 14

      Row {
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Icon {
          name: network.primary === "ethernet" ? "ethernet" : network.primary === "wifi" ? "wifi" : "wifi-off"
          size: 14
          anchors.verticalCenter: parent.verticalCenter
        }
        Label {
          text: network.primary === "ethernet" ? "Ethernet" : network.primary === "wifi" ? (network.activeNetwork?.name ?? "Wi-Fi") : "Offline"
          anchors.verticalCenter: parent.verticalCenter
        }
      }

      Row {
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: Sound.isMuted ? "volume-off" : "volume"; size: 14; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Sound.isMuted ? "Muted" : Sound.volume + "%"; anchors.verticalCenter: parent.verticalCenter }
      }

      Row {
        visible: Battery.hasBattery
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter
        Icon { name: "battery"; size: 14; color: Battery.charging ? Theme.good : Theme.text; anchors.verticalCenter: parent.verticalCenter }
        Label { text: Battery.batteryLevel + "%"; anchors.verticalCenter: parent.verticalCenter }
      }

      // Keyboard layout: click to switch
      Rectangle {
        visible: Lock.layout !== ""
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: layoutLabel.implicitWidth + 24
        implicitHeight: 28
        radius: Theme.pill(height)
        color: layoutMouse.containsMouse ? Theme.hover(Theme.overlay) : Theme.overlay

        Accessible.role: Accessible.Button
        Accessible.name: "Keyboard layout " + Lock.layout + ", click to switch"

        Label { id: layoutLabel; anchors.centerIn: parent; text: Lock.layout; font.weight: Font.Bold; font.pixelSize: Theme.font.small }
        MouseArea {
          id: layoutMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: Lock.nextLayout()
        }
      }
    }
  }

  // --- Clock ---------------------------------------------------------------------------
  ColumnLayout {
    id: clock
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * (root.resting ? 0.23 : 0.13)
    spacing: 10

    Behavior on y { NumberAnimation { duration: Theme.anim.stack; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: Time.time
      color: Theme.text
      font.family: Theme.font.family
      font.pixelSize: root.resting ? 156 : 112
      font.weight: Font.Light
      font.letterSpacing: -4

      Behavior on font.pixelSize { NumberAnimation { duration: Theme.anim.stack; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }
    }

    Label {
      Layout.alignment: Qt.AlignHCenter
      text: Qt.formatDateTime(Time.date, "dddd, MMMM d")
      font.pixelSize: 18
      color: Theme.subtext
    }

    // Notifications that came in (only the count, never the content)
    GlassPill {
      visible: Config.lock.showNotifications && Notifications.count > 0
      Layout.alignment: Qt.AlignHCenter
      Layout.topMargin: 8
      implicitHeight: 30
      implicitWidth: notifRow.implicitWidth + 28

      Row {
        id: notifRow
        anchors.centerIn: parent
        spacing: 8
        Rectangle { width: 7; height: 7; radius: 4; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
        Label {
          text: Notifications.count + (Notifications.count === 1 ? " notification" : " notifications")
          font.pixelSize: Theme.font.small
          anchors.verticalCenter: parent.verticalCenter
        }
      }
    }
  }

  // --- Resting: hint --------------------------------------------------------------------
  Rectangle {
    id: hint
    visible: opacity > 0
    opacity: root.resting ? 1 : 0
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * 0.62
    implicitWidth: hintRow.implicitWidth + 36
    implicitHeight: 40
    radius: Theme.pill(height)
    color: Theme.alpha(Theme.base, 0.35)
    border.width: 1
    border.color: Theme.border

    Behavior on opacity { NumberAnimation { duration: Theme.anim.fast } }

    Row {
      id: hintRow
      anchors.centerIn: parent
      spacing: 10
      opacity: 0.55
      Icon { name: "lock"; size: 14; anchors.verticalCenter: parent.verticalCenter }
      Label { text: "Click or start typing to unlock"; anchors.verticalCenter: parent.verticalCenter }

      SequentialAnimation on opacity {
        running: root.resting && Theme.speed > 0
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.55; duration: 1200; easing.type: Easing.InOutSine }
      }
    }
  }

  // --- Unlock card ------------------------------------------------------------------------
  GlassPanel {
    id: card
    visible: opacity > 0
    opacity: root.resting ? 0 : 1
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * 0.47 + (root.resting ? 10 : 0)
    width: 380
    height: cardColumn.implicitHeight + 44
    radius: 24
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.7))

    Accessible.role: Accessible.Dialog
    Accessible.name: "Unlock"

    Behavior on opacity { NumberAnimation { duration: Theme.anim.panelIn } }
    Behavior on y { NumberAnimation { duration: Theme.anim.panelIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.anim.emphasized } }

    ColumnLayout {
      id: cardColumn
      x: 22
      y: 22
      width: parent.width - 44
      spacing: 14

      // Profile picture with a ring that turns red or green
      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 76
        implicitHeight: 76
        radius: 38
        color: Theme.surface
        border.width: 3
        border.color: root.ring

        Behavior on border.color { ColorAnimation { duration: Theme.anim.fast } }

        Icon { anchors.centerIn: parent; visible: avatarImage.status !== Image.Ready; name: "user"; size: 30; color: Theme.subtext }

        Image {
          id: avatarImage
          anchors.fill: parent
          anchors.margins: 3
          source: Lock.avatar
          fillMode: Image.PreserveAspectCrop
          visible: false
        }
        MultiEffect {
          anchors.fill: avatarImage
          source: avatarImage
          visible: avatarImage.status === Image.Ready
          maskEnabled: true
          maskSource: avatarMask
        }
        Rectangle {
          id: avatarMask
          anchors.fill: avatarImage
          radius: width / 2
          visible: false
          layer.enabled: true
        }
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 3
        Label { Layout.alignment: Qt.AlignHCenter; text: Lock.displayName; kind: "title" }
        Label {
          Layout.alignment: Qt.AlignHCenter
          text: root.ok ? "Unlocking…" : Lock.state === "checking" ? "Checking…" : root.wrong ? "Try again" : "Enter your password"
          kind: "muted"
          font.pixelSize: Theme.font.small
        }
      }

      // Password field and the unlock button
      RowLayout {
        id: fieldRow
        visible: !root.ok
        Layout.fillWidth: true
        spacing: 6

        transform: Translate { id: shake }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: Theme.pill(height)
          color: Theme.item
          border.width: 1
          border.color: root.wrong ? Theme.error : field.activeFocus ? Theme.accent : Theme.border

          TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 44
            verticalAlignment: TextInput.AlignVCenter
            text: Lock.typed
            echoMode: Lock.reveal ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            color: Theme.text
            selectionColor: Theme.alpha(Theme.accent, 0.4)
            font.family: Theme.font.family
            font.pixelSize: Theme.font.title
            font.letterSpacing: Lock.reveal ? 0.5 : 3
            clip: true
            readOnly: Lock.state === "checking"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

            Accessible.role: Accessible.EditableText
            Accessible.name: "Password"
            Accessible.passwordEdit: true

            onTextChanged: {
              if (Lock.typed !== text) Lock.typed = text;
              if (text !== "") Lock.wake();
            }
            Keys.onReturnPressed: Lock.submit(text)
            Keys.onEnterPressed: Lock.submit(text)
            Keys.onEscapePressed: {
              if (text !== "") Lock.typed = "";
              else Lock.state = "rest";
            }
            Keys.onPressed: event => {
              if (event.key === Qt.Key_CapsLock) Lock.capsChanged();
            }

            Label {
              visible: field.text === ""
              anchors.verticalCenter: parent.verticalCenter
              text: "Password"
              kind: "muted"
              font.pixelSize: Theme.font.title
            }
          }

          IconButton {
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            size: 34
            variant: "plain"
            icon: Lock.reveal ? "eye-off" : "eye"
            accessibleName: Lock.reveal ? "Hide password" : "Show password"
            onClicked: {
              Lock.reveal = !Lock.reveal;
              field.forceActiveFocus();
            }
          }
        }

        IconButton {
          size: 44
          variant: "primary"
          icon: "arrow-right"
          accessibleName: "Unlock"
          onClicked: Lock.submit(field.text)
        }
      }

      Connections {
        target: Lock
        function onFailuresChanged() {
          Lock.typed = "";
          shakeAnim.restart();
          field.forceActiveFocus();
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

      // Wrong password, or what PAM said
      Rectangle {
        visible: root.wrong
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 28
        implicitWidth: Math.min(wrongRow.implicitWidth + 24, cardColumn.width)
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.error, 0.14)

        Accessible.role: Accessible.AlertMessage
        Accessible.name: wrongLabel.text

        Row {
          id: wrongRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "warning"; size: 13; color: Theme.error; anchors.verticalCenter: parent.verticalCenter }
          Label {
            id: wrongLabel
            text: Lock.message !== "" ? Lock.message : "Wrong password"
            color: Theme.error
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
            width: Math.min(implicitWidth, cardColumn.width - 60)
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      Rectangle {
        visible: Lock.capsLock && !root.ok
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 28
        implicitWidth: capsRow.implicitWidth + 24
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.warn, 0.12)

        Row {
          id: capsRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "chevron-up"; size: 13; color: Theme.warn; anchors.verticalCenter: parent.verticalCenter }
          Label { text: "Caps Lock is on"; color: Theme.warn; font.pixelSize: Theme.font.small; anchors.verticalCenter: parent.verticalCenter }
        }
      }

      Rectangle {
        visible: root.ok
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 36
        implicitWidth: okRow.implicitWidth + 32
        radius: Theme.pill(height)
        color: Theme.alpha(Theme.good, 0.16)

        Row {
          id: okRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "check"; size: 14; color: Theme.good; anchors.verticalCenter: parent.verticalCenter }
          Label { text: "Welcome back"; color: Theme.good; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  // --- What's playing -------------------------------------------------------------------------
  readonly property MprisPlayer player: {
    const players = Mpris.players.values;
    for (let i = 0; i < players.length; i++) {
      if (players[i].isPlaying) return players[i];
    }
    return players.length > 0 ? players[0] : null;
  }

  // Mpris doesn't push the position; ask for it while playing
  Timer {
    running: root.player !== null && root.player.isPlaying && root.visible
    interval: 1000
    repeat: true
    onTriggered: root.player.positionChanged()
  }

  function formatTime(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
  }

  GlassPanel {
    visible: Config.lock.showMedia && root.player !== null && root.player.trackTitle !== ""
    x: 32
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 32
    width: 340
    height: mediaColumn.implicitHeight + 24
    color: Theme.alpha(Theme.base, Math.max(Theme.glass, 0.6))

    Accessible.role: Accessible.Grouping
    Accessible.name: "Now playing"

    ColumnLayout {
      id: mediaColumn
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 10

      RowLayout {
        spacing: 12
        Layout.fillWidth: true

        Rectangle {
          implicitWidth: 52
          implicitHeight: 52
          radius: 12
          color: Theme.accent
          clip: true

          Icon { anchors.centerIn: parent; visible: art.status !== Image.Ready; name: "music"; size: 22; color: Theme.onAccent }
          Image {
            id: art
            anchors.fill: parent
            source: root.player ? root.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }
        }

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Label { text: root.player?.trackTitle ?? ""; font.weight: Font.Bold; elide: Text.ElideRight; Layout.fillWidth: true }
          Label {
            text: [root.player?.trackArtist ?? "", root.player?.identity ?? ""].filter(t => t !== "").join(" · ")
            kind: "muted"
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
            Layout.fillWidth: true
          }
        }
      }

      RowLayout {
        visible: (root.player?.lengthSupported ?? false) && (root.player?.length ?? 0) > 0
        Layout.fillWidth: true
        spacing: 8
        Label { text: root.formatTime(root.player?.position ?? 0); kind: "muted"; font.pixelSize: Theme.font.label }
        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 4
          radius: 2
          color: Theme.alpha(Theme.text, 0.15)
          Rectangle {
            width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
            height: parent.height
            radius: 2
            color: Theme.accent
          }
        }
        Label { text: root.formatTime(root.player?.length ?? 0); kind: "muted"; font.pixelSize: Theme.font.label }
      }

      Row {
        Layout.alignment: Qt.AlignHCenter
        spacing: 6
        IconButton { size: 38; icon: "previous"; accessibleName: "Previous"; onClicked: root.player?.previous() }
        IconButton {
          size: 38
          variant: "primary"
          icon: root.player?.isPlaying ? "pause" : "play"
          accessibleName: root.player?.isPlaying ? "Pause" : "Play"
          onClicked: root.player?.togglePlaying()
        }
        IconButton { size: 38; icon: "next"; accessibleName: "Next"; onClicked: root.player?.next() }
      }
    }
  }

  // --- Power: click twice ------------------------------------------------------------------------
  property int powerPending: -1

  readonly property var powerActions: [
    { label: "Suspend", icon: "moon", tone: Theme.text, run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
    { label: "Restart", icon: "restart", tone: Theme.warn, run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
    { label: "Shut down", icon: "power", tone: Theme.error, run: () => Quickshell.execDetached(["systemctl", "poweroff"]) }
  ]

  Timer {
    id: powerReset
    interval: 4000
    onTriggered: root.powerPending = -1
  }

  GlassPill {
    anchors.right: parent.right
    anchors.rightMargin: 32
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 32
    implicitHeight: 52
    implicitWidth: powerRow.implicitWidth + 8

    Row {
      id: powerRow
      anchors.centerIn: parent
      spacing: 4

      Repeater {
        model: root.powerActions

        Rectangle {
          id: powerButton
          required property var modelData
          required property int index
          readonly property bool pending: root.powerPending === index

          implicitHeight: 44
          implicitWidth: pending ? powerLabelRow.implicitWidth + 32 : 44
          radius: Theme.pill(height)
          color: pending ? Theme.alpha(modelData.tone, 0.18) : powerMouse.containsMouse ? Theme.item : "transparent"

          Accessible.role: Accessible.Button
          Accessible.name: pending ? modelData.label + ", click again to confirm" : modelData.label

          Behavior on implicitWidth { NumberAnimation { duration: Theme.anim.fast } }

          Row {
            id: powerLabelRow
            anchors.centerIn: parent
            spacing: 8
            Icon { name: powerButton.modelData.icon; size: 17; color: powerButton.modelData.tone; anchors.verticalCenter: parent.verticalCenter }
            Label {
              visible: powerButton.pending
              text: "Click again to " + powerButton.modelData.label.toLowerCase()
              color: powerButton.modelData.tone
              font.pixelSize: Theme.font.small
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          MouseArea {
            id: powerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (powerButton.pending) {
                root.powerPending = -1;
                powerButton.modelData.run();
              } else {
                root.powerPending = powerButton.index;
                powerReset.restart();
              }
            }
          }
        }
      }
    }
  }
}
