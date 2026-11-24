// Main.qml
// The SDDM login screen, in the style of the shell's lock screen
// (modules/lock/LockContent.qml): the blurred wallpaper, a big clock, and a
// glass card with the password. Nothing of the shell runs yet before you log
// in, so the theme only knows what scripts/app-theme.py wrote to
// theme.conf.user: the colours, font, corners, the wallpaper and the avatar.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

Rectangle {
  id: root

  width: 1920
  height: 1080

  // --- Theme (from theme.conf / theme.conf.user) ---------------------------------
  function setting(key: string, fallback: string): string {
    const v = config[key];
    return v === undefined || v === null || String(v) === "" ? fallback : String(v);
  }

  readonly property bool light: setting("light", "false") === "true"
  readonly property color crust: setting("crust", "#1e2326")
  readonly property color base: setting("base", "#232a2e")
  readonly property color surface: setting("surface", "#2d353b")
  readonly property color overlay: setting("overlay", "#343f44")
  readonly property color textColor: setting("text", "#d3c6aa")
  readonly property color subtext: setting("subtext", "#9da9a0")
  readonly property color accent: setting("accent", "#a7c080")
  readonly property color good: setting("good", "#a7c080")
  readonly property color warn: setting("warn", "#dbbc7f")
  readonly property color error: setting("error", "#e67e80")
  readonly property real glass: parseFloat(setting("glass", "0.45"))
  readonly property real roundness: Math.max(0, Math.min(1, parseFloat(setting("roundness", "1"))))
  readonly property string fontFamily: setting("font", "JetBrains Mono")
  readonly property string background: setting("background", "")
  readonly property string avatarPath: setting("avatar", "")

  // The same derived colours as config/Theme.qml
  readonly property color onAccent: light ? base : crust
  readonly property color item: light ? Qt.rgba(0, 0, 0, 0.06) : Qt.rgba(crust.r, crust.g, crust.b, 0.45)
  readonly property color edge: light ? Qt.rgba(0, 0, 0, 0.1) : Qt.rgba(1, 1, 1, 0.14)
  readonly property color highlight: light ? Qt.rgba(1, 1, 1, 0.8) : Qt.rgba(1, 1, 1, 0.22)

  function alpha(c: color, a: real): color { return Qt.rgba(c.r, c.g, c.b, a); }
  function pill(h: real): real { return h / 2 * roundness; }
  function r(radius: real): real { return radius * roundness; }

  // --- State: "rest" (only the clock), "type", "checking", "wrong", "ok" -----------
  property string state_: "rest"
  readonly property bool resting: state_ === "rest"
  readonly property bool wrong: state_ === "wrong"
  readonly property bool ok: state_ === "ok"
  readonly property color ring: ok ? good : wrong ? error : accent
  property string loginMessage: ""

  function wake() {
    if (resting) state_ = "type";
    field.forceActiveFocus();
  }

  // --- Users and sessions ----------------------------------------------------------
  property int userIndex: userModel.lastIndex >= 0 ? userModel.lastIndex : 0
  property int sessionIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0

  // The model's rows, read through a Repeater since SDDM's models are only lists
  Repeater {
    id: users
    model: userModel
    delegate: Item {
      required property string name
      required property string realName
      required property string icon
    }
  }
  Repeater {
    id: sessions
    model: sessionModel
    delegate: Item {
      required property string name
    }
  }

  readonly property var user: users.count > 0 ? users.itemAt(Math.min(userIndex, users.count - 1)) : null
  readonly property string userName: user?.name ?? userModel.lastUser ?? ""
  readonly property string displayName: {
    const real = (user?.realName ?? "").split(",")[0].trim();
    if (real !== "") return real;
    return userName.charAt(0).toUpperCase() + userName.slice(1);
  }
  // The shell's avatar when it found one, else the account's own (not SDDM's stock face)
  readonly property string avatar: {
    if (avatarPath !== "" && users.count <= 1) return "file://" + avatarPath;
    const icon = user?.icon ?? "";
    return icon !== "" && icon.indexOf("/usr/share/sddm/faces") < 0 ? "file://" + icon : "";
  }
  readonly property string sessionName: sessions.count > 0 ? (sessions.itemAt(Math.min(sessionIndex, sessions.count - 1))?.name ?? "") : ""

  function submit() {
    if (state_ === "checking" || field.text === "") return;
    state_ = "checking";
    loginMessage = "";
    sddm.login(userName, field.text, sessionIndex);
  }

  Connections {
    target: sddm
    function onLoginFailed() {
      root.state_ = "wrong";
      field.text = "";
      shakeAnim.restart();
      field.forceActiveFocus();
    }
    function onLoginSucceeded() {
      root.state_ = "ok";
    }
    function onInformationMessage(message) {
      root.loginMessage = message;
    }
  }

  // Typing while only the clock shows starts the password
  focus: true
  Keys.onPressed: event => {
    if (resting && event.text !== "" && event.text.charCodeAt(0) >= 32) {
      wake();
      field.text = event.text;
      field.cursorPosition = field.text.length;
      event.accepted = true;
    } else if (resting && (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space)) {
      wake();
      event.accepted = true;
    }
  }
  Component.onCompleted: forceActiveFocus()

  // After a while without typing, back to the clock
  Timer {
    id: restTimer
    interval: 30000
    running: root.state_ === "type" && field.text === ""
    onTriggered: { root.state_ = "rest"; root.forceActiveFocus(); }
  }

  // --- Clock ----------------------------------------------------------------------------
  property date now: new Date()
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  // --- Background ------------------------------------------------------------------------
  gradient: Gradient {
    GradientStop { position: 0; color: root.surface }
    GradientStop { position: 1; color: root.crust }
  }

  Image {
    id: wallpaper
    anchors.fill: parent
    source: root.background !== "" ? "file://" + root.background : ""
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
    Behavior on blur { NumberAnimation { duration: 240 } }
  }

  Rectangle {
    anchors.fill: parent
    color: root.alpha(root.crust, root.resting ? 0.3 : 0.5)
    Behavior on color { ColorAnimation { duration: 240 } }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.wake()
  }

  // --- Small parts -----------------------------------------------------------------------
  component Label: Text {
    color: root.textColor
    font.family: root.fontFamily
    font.pixelSize: 12
  }

  component GlassPill: Rectangle {
    implicitHeight: 36
    radius: root.pill(height)
    color: root.alpha(root.base, Math.max(root.glass, 0.55))
    border.width: 1
    border.color: root.edge
  }

  // A round button: "primary" (accent) or "plain"
  component RoundButton: Rectangle {
    id: button
    property string icon
    property string variant: "plain"
    property real size: 34
    signal clicked

    implicitWidth: size
    implicitHeight: size
    radius: root.pill(height)
    color: variant === "primary" ? (mouse.containsMouse ? Qt.lighter(root.accent, 1.1) : root.accent)
         : mouse.containsMouse ? root.item : "transparent"

    Icon {
      anchors.centerIn: parent
      name: button.icon
      size: button.size * 0.45
      color: button.variant === "primary" ? root.onAccent : root.subtext
    }
    MouseArea {
      id: mouse
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: button.clicked()
    }
  }

  // --- Top: this computer, and session / keyboard -------------------------------------
  GlassPill {
    x: 32
    y: 28
    implicitWidth: hostRow.implicitWidth + 28

    Row {
      id: hostRow
      anchors.centerIn: parent
      spacing: 8
      Icon { name: "lock"; size: 14; color: root.accent; anchors.verticalCenter: parent.verticalCenter }
      Label { text: sddm.hostName !== "" ? sddm.hostName : "Welcome"; anchors.verticalCenter: parent.verticalCenter }
    }
  }

  GlassPill {
    visible: sessionPill.visible || layoutPill.visible
    anchors.right: parent.right
    anchors.rightMargin: 32
    y: 28
    implicitWidth: topRight.implicitWidth + 12

    Row {
      id: topRight
      anchors.centerIn: parent
      spacing: 4

      // Session: click to switch (only when there's more than one)
      Rectangle {
        id: sessionPill
        visible: sessions.count > 1
        implicitHeight: 28
        implicitWidth: sessionRow.implicitWidth + 24
        radius: root.pill(height)
        color: sessionMouse.containsMouse ? Qt.lighter(root.overlay, 1.18) : root.overlay

        Row {
          id: sessionRow
          anchors.centerIn: parent
          spacing: 6
          Icon { name: "monitor"; size: 13; anchors.verticalCenter: parent.verticalCenter; color: root.textColor }
          Label { text: root.sessionName; font.pixelSize: 11; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
        MouseArea {
          id: sessionMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.sessionIndex = (root.sessionIndex + 1) % sessions.count
        }
      }

      // Keyboard layout: click to switch
      Rectangle {
        id: layoutPill
        readonly property var layouts: keyboard.layouts ?? []
        readonly property string shortName: layouts.length > 0 ? (layouts[keyboard.currentLayout]?.shortName ?? "") : ""
        visible: shortName !== ""
        implicitHeight: 28
        implicitWidth: layoutText.implicitWidth + 24
        radius: root.pill(height)
        color: layoutMouse.containsMouse ? Qt.lighter(root.overlay, 1.18) : root.overlay

        Label { id: layoutText; anchors.centerIn: parent; text: layoutPill.shortName.toUpperCase(); font.pixelSize: 11; font.weight: Font.Bold }
        MouseArea {
          id: layoutMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: keyboard.currentLayout = (keyboard.currentLayout + 1) % layoutPill.layouts.length
        }
      }
    }
  }

  // --- Clock ---------------------------------------------------------------------------
  ColumnLayout {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * (root.resting ? 0.23 : 0.13)
    spacing: 10

    Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

    Text {
      Layout.alignment: Qt.AlignHCenter
      text: Qt.formatDateTime(root.now, "HH:mm")
      color: root.textColor
      font.family: root.fontFamily
      font.pixelSize: root.resting ? 156 : 112
      font.weight: Font.Light
      font.letterSpacing: -4
      Behavior on font.pixelSize { NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }
    }

    Label {
      Layout.alignment: Qt.AlignHCenter
      text: Qt.formatDateTime(root.now, "dddd, MMMM d")
      font.pixelSize: 18
      color: root.subtext
    }
  }

  // --- Resting: hint -----------------------------------------------------------------------
  Rectangle {
    visible: opacity > 0
    opacity: root.resting ? 1 : 0
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * 0.62
    implicitWidth: hintRow.implicitWidth + 36
    implicitHeight: 40
    radius: root.pill(height)
    color: root.alpha(root.base, 0.35)
    border.width: 1
    border.color: root.edge
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Row {
      id: hintRow
      anchors.centerIn: parent
      spacing: 10
      opacity: 0.55
      Icon { name: "lock"; size: 14; color: root.textColor; anchors.verticalCenter: parent.verticalCenter }
      Label { text: "Click or start typing to log in"; anchors.verticalCenter: parent.verticalCenter }

      SequentialAnimation on opacity {
        running: root.resting
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 1200; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.55; duration: 1200; easing.type: Easing.InOutSine }
      }
    }
  }

  // --- Login card ----------------------------------------------------------------------------
  Rectangle {
    id: card
    visible: opacity > 0
    opacity: root.resting ? 0 : 1
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.height * 0.47 + (root.resting ? 10 : 0)
    width: 380
    height: cardColumn.implicitHeight + 44
    radius: root.r(24)
    color: root.alpha(root.base, Math.max(root.glass, 0.7))
    border.width: 1
    border.color: root.edge

    Behavior on opacity { NumberAnimation { duration: 180 } }
    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] } }

    RectangularShadow {
      z: -1
      anchors.fill: parent
      radius: parent.radius
      offset.y: 6
      blur: 24
      spread: -4
      color: Qt.rgba(0, 0, 0, root.light ? 0.16 : 0.32)
    }

    // Light on the top edge, like the shell's glass
    Rectangle {
      anchors.top: parent.top
      anchors.topMargin: 1
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width - parent.radius * 2
      height: 1
      color: root.highlight
    }

    ColumnLayout {
      id: cardColumn
      x: 22
      y: 22
      width: parent.width - 44
      spacing: 14

      // Avatar with a ring that turns red or green; arrows when there are more users
      RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 12

        RoundButton {
          visible: users.count > 1
          icon: "chevron-left"
          onClicked: root.userIndex = (root.userIndex + users.count - 1) % users.count
        }

        Rectangle {
          implicitWidth: 76
          implicitHeight: 76
          radius: root.r(38)
          color: root.surface
          border.width: 3
          border.color: root.ring
          Behavior on border.color { ColorAnimation { duration: 120 } }

          Icon { anchors.centerIn: parent; visible: avatarImage.status !== Image.Ready; name: "user"; size: 30; color: root.subtext }

          Image {
            id: avatarImage
            anchors.fill: parent
            anchors.margins: 3
            source: root.avatar
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

        RoundButton {
          visible: users.count > 1
          icon: "chevron-right"
          onClicked: root.userIndex = (root.userIndex + 1) % users.count
        }
      }

      ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: 3
        Label { Layout.alignment: Qt.AlignHCenter; text: root.displayName; font.pixelSize: 14; font.weight: Font.Bold }
        Label {
          Layout.alignment: Qt.AlignHCenter
          text: root.ok ? "Logging in…" : root.state_ === "checking" ? "Checking…" : root.wrong ? "Try again" : "Enter your password"
          color: root.subtext
          font.pixelSize: 11
        }
      }

      // Password field and the log-in button
      RowLayout {
        visible: !root.ok
        Layout.fillWidth: true
        spacing: 6
        transform: Translate { id: shake }

        Rectangle {
          Layout.fillWidth: true
          implicitHeight: 44
          radius: root.pill(height)
          color: root.item
          border.width: 1
          border.color: root.wrong ? root.error : field.activeFocus ? root.accent : root.edge

          TextInput {
            id: field
            property bool reveal: false
            anchors.fill: parent
            anchors.leftMargin: 18
            anchors.rightMargin: 44
            verticalAlignment: TextInput.AlignVCenter
            echoMode: reveal ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            color: root.textColor
            selectionColor: root.alpha(root.accent, 0.4)
            font.family: root.fontFamily
            font.pixelSize: 14
            font.letterSpacing: reveal ? 0.5 : 3
            clip: true
            readOnly: root.state_ === "checking"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

            onTextChanged: {
              if (text !== "" && root.wrong) root.state_ = "type";
              if (text !== "") root.wake();
            }
            Keys.onReturnPressed: root.submit()
            Keys.onEnterPressed: root.submit()
            Keys.onEscapePressed: {
              if (text !== "") text = "";
              else { root.state_ = "rest"; root.forceActiveFocus(); }
            }

            Label {
              visible: field.text === ""
              anchors.verticalCenter: parent.verticalCenter
              text: "Password"
              color: root.subtext
              font.pixelSize: 14
            }
          }

          RoundButton {
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            icon: field.reveal ? "eye-off" : "eye"
            onClicked: {
              field.reveal = !field.reveal;
              field.forceActiveFocus();
            }
          }
        }

        RoundButton {
          size: 44
          variant: "primary"
          icon: "arrow-right"
          onClicked: root.submit()
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
        visible: root.wrong || (root.loginMessage !== "" && !root.ok)
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 28
        implicitWidth: Math.min(wrongRow.implicitWidth + 24, cardColumn.width)
        radius: root.pill(height)
        color: root.alpha(root.error, 0.14)

        Row {
          id: wrongRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "warning"; size: 13; color: root.error; anchors.verticalCenter: parent.verticalCenter }
          Label {
            text: root.loginMessage !== "" ? root.loginMessage : "Wrong password"
            color: root.error
            font.pixelSize: 11
            elide: Text.ElideRight
            width: Math.min(implicitWidth, cardColumn.width - 60)
            anchors.verticalCenter: parent.verticalCenter
          }
        }
      }

      Rectangle {
        visible: keyboard.capsLock && !root.ok
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 28
        implicitWidth: capsRow.implicitWidth + 24
        radius: root.pill(height)
        color: root.alpha(root.warn, 0.12)

        Row {
          id: capsRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "chevron-up"; size: 13; color: root.warn; anchors.verticalCenter: parent.verticalCenter }
          Label { text: "Caps Lock is on"; color: root.warn; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        }
      }

      Rectangle {
        visible: root.ok
        Layout.alignment: Qt.AlignHCenter
        implicitHeight: 36
        implicitWidth: okRow.implicitWidth + 32
        radius: root.pill(height)
        color: root.alpha(root.good, 0.16)

        Row {
          id: okRow
          anchors.centerIn: parent
          spacing: 8
          Icon { name: "check"; size: 14; color: root.good; anchors.verticalCenter: parent.verticalCenter }
          Label { text: "Welcome"; color: root.good; font.weight: Font.Bold; anchors.verticalCenter: parent.verticalCenter }
        }
      }
    }
  }

  // --- Power: click twice -------------------------------------------------------------------
  property int powerPending: -1

  readonly property var powerActions: [
    { label: "Suspend", icon: "moon", tone: root.textColor, can: sddm.canSuspend, run: () => sddm.suspend() },
    { label: "Restart", icon: "restart", tone: root.warn, can: sddm.canReboot, run: () => sddm.reboot() },
    { label: "Shut down", icon: "power", tone: root.error, can: sddm.canPowerOff, run: () => sddm.powerOff() }
  ]

  Timer {
    id: powerReset
    interval: 4000
    onTriggered: root.powerPending = -1
  }

  GlassPill {
    visible: root.powerActions.some(a => a.can)
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

          visible: modelData.can
          implicitHeight: 44
          implicitWidth: pending ? powerLabelRow.implicitWidth + 32 : 44
          radius: root.pill(height)
          color: pending ? root.alpha(modelData.tone, 0.18) : powerMouse.containsMouse ? root.item : "transparent"
          Behavior on implicitWidth { NumberAnimation { duration: 120 } }

          Row {
            id: powerLabelRow
            anchors.centerIn: parent
            spacing: 8
            Icon { name: powerButton.modelData.icon; size: 17; color: powerButton.modelData.tone; anchors.verticalCenter: parent.verticalCenter }
            Label {
              visible: powerButton.pending
              text: "Click again to " + powerButton.modelData.label.toLowerCase()
              color: powerButton.modelData.tone
              font.pixelSize: 11
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
