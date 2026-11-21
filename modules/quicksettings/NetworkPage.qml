// NetworkPage.qml
// Network details: the connection in use (with IP, speeds and ping),
// Ethernet when it is unplugged, and Wi-Fi with its networks.
// Known networks connect with one click; new secured ones ask for a password,
// school and work networks (eduroam) for a username and password. Saved
// networks have a gear: auto-connect, a new password, Forget.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../config"
import "../../components"
import "../../services"

ColumnLayout {
  id: root

  required property var network
  property string expandedName: ""
  // What the open network shows: "password", "enterprise" or "manage"
  property string expandedMode: ""
  property bool addingHidden: false
  property bool confirmForget: false

  function expand(name: string, mode: string): void {
    const same = expandedName === name && expandedMode === mode;
    expandedName = same ? "" : name;
    expandedMode = same ? "" : mode;
    confirmForget = false;
    if (!same && mode === "manage") WifiAdmin.inspect(name);
  }

  function isEnterprise(n: var): bool {
    return n.security === WifiSecurityType.Wpa2Eap || n.security === WifiSecurityType.WpaEap || n.security === WifiSecurityType.Wpa3SuiteB192;
  }

  readonly property var sorted: {
    const list = (root.network.availableNetworks ?? []).filter(n => n.name !== "");
    return list.slice().sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1;
      if (a.known !== b.known) return a.known ? -1 : 1;
      return (b.signalStrength ?? 0) - (a.signalStrength ?? 0);
    });
  }

  spacing: 12

  PageHeader {
    Layout.fillWidth: true
    title: "Network"
  }

  // --- In use: whichever connection carries the traffic ---------------------
  Label {
    visible: stats.visible
    text: "In use"
    kind: "label"
  }

  // Connected, but the internet isn't reachable (or a login page is in the way)
  readonly property bool noInternet: root.network.primary !== "none"
    && (Networking.connectivity === NetworkConnectivity.Limited || Networking.connectivity === NetworkConnectivity.Portal)

  Rectangle {
    visible: root.noInternet
    Layout.fillWidth: true
    implicitHeight: warnColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.alpha(Theme.warn, 0.12)
    border.width: 1
    border.color: Theme.alpha(Theme.warn, 0.4)

    Accessible.role: Accessible.AlertMessage
    Accessible.name: warnTitle.text

    ColumnLayout {
      id: warnColumn
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 8
      RowLayout {
        spacing: 10
        Icon { name: "warning"; size: 18; color: Theme.warn }
        Label {
          id: warnTitle
          Layout.fillWidth: true
          text: Networking.connectivity === NetworkConnectivity.Portal ? "This network wants you to log in" : "Connected, but no internet"
          font.weight: Font.Bold
          wrapMode: Text.Wrap
        }
      }
      Label {
        Layout.fillWidth: true
        text: Networking.connectivity === NetworkConnectivity.Portal
          ? "Hotels, trains and schools often show a login page first. Open it to get online."
          : "Check that the router is online. Some networks need a login page first."
        kind: "muted"
        font.pixelSize: Theme.font.small
        wrapMode: Text.Wrap
      }
      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Button { Layout.fillWidth: true; text: "Try again"; variant: "primary"; size: Theme.size.buttonRow; onClicked: Networking.checkConnectivity() }
        // A plain http page, so the network's login page can take over
        Button { Layout.fillWidth: true; text: "Open login page"; variant: "secondary"; size: Theme.size.buttonRow; onClicked: Quickshell.execDetached(["xdg-open", "http://neverssl.com"]) }
      }
    }
  }

  ConnectionStats {
    id: stats
    network: root.network
    Layout.fillWidth: true
  }

  Label {
    visible: root.network.primary === "none"
    text: "No connection. IP, speed and ping show up here as soon as a cable or Wi-Fi is connected."
    kind: "muted"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  // --- Ethernet, only when it's not the one in use ---------------------------
  Label {
    visible: root.network.hasWiredDevice && root.network.primary !== "ethernet"
    text: "Ethernet"
    kind: "label"
  }

  Card {
    visible: root.network.hasWiredDevice && root.network.primary !== "ethernet"
    Layout.fillWidth: true
    implicitHeight: wiredRow.implicitHeight

    ListRow {
      id: wiredRow
      width: parent.width
      first: true
      title: root.network.wiredName
      subtitle: root.network.isWiredConnected ? "Connected" : "Plug in a cable to use it"

      Icon {
        name: "ethernet"
        size: 16
        color: Theme.subtext
        anchors.verticalCenter: parent.verticalCenter
      }

      Chip {
        text: root.network.isWiredConnected ? "Connected" : "Unplugged"
        tone: root.network.isWiredConnected ? "neutral" : "warn"
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  // --- Wi-Fi ---------------------------------------------------------------------
  RowLayout {
    visible: root.network.hasWifiDevice
    Layout.fillWidth: true
    Layout.topMargin: 4

    Label {
      text: "Wi-Fi"
      kind: "label"
      Layout.fillWidth: true
    }

    Toggle {
      checked: Networking.wifiEnabled
      accessibleName: "Wi-Fi"
      onToggled: value => Networking.wifiEnabled = value
    }
  }

  Label {
    visible: root.network.hasWifiDevice && Networking.wifiEnabled && root.network.activeNetwork !== null && root.network.primary !== "wifi"
    text: "Standby: Wi-Fi stays connected and takes over when the cable is unplugged."
    kind: "muted"
    wrapMode: Text.WordWrap
    Layout.fillWidth: true
  }

  EmptyState {
    visible: root.network.hasWifiDevice && !Networking.wifiEnabled
    Layout.fillWidth: true
    icon: "wifi"
    crossed: true
    title: "Wi-Fi is off"
    text: "Turn it on to see networks nearby."
    action: "Turn on Wi-Fi"
    onActivated: Networking.wifiEnabled = true
  }

  Card {
    visible: root.network.hasWifiDevice && Networking.wifiEnabled && root.sorted.length > 0
    Layout.fillWidth: true
    implicitHeight: list.implicitHeight

    Column {
      id: list
      width: parent.width

      Repeater {
        model: root.sorted.slice(0, 8)

        Column {
          id: entry
          required property var modelData
          required property int index
          readonly property bool expanded: root.expandedName === modelData.name
          readonly property bool secured: modelData.security !== undefined && modelData.security !== WifiSecurityType.Open
          readonly property bool enterprise: root.isEnterprise(modelData)
          readonly property bool saved: modelData.known || modelData.connected

          width: list.width

          ListRow {
            width: parent.width
            first: entry.index === 0
            title: entry.modelData.name
            subtitle: entry.modelData.connected ? (root.network.primary === "wifi" ? "Connected · in use" : "Connected · standby")
                    : entry.modelData.stateChanging ? "Connecting…"
                    : entry.modelData.connectionFailed ? "Couldn't connect"
                    : entry.modelData.known ? "Saved"
                    : entry.enterprise ? "School or work · sign in" : entry.secured ? "Secured" : "Open"
            // A connected network never shows red, even if an older attempt failed
            subtitleColor: entry.modelData.connected ? (root.network.primary === "wifi" ? Theme.good : Theme.subtext)
                         : entry.modelData.connectionFailed ? Theme.error : Theme.subtext

            Icon {
              name: "wifi"
              size: 16
              color: entry.modelData.connected && root.network.primary === "wifi" ? Theme.good : Theme.text
              opacity: 0.4 + 0.6 * (entry.modelData.signalStrength ?? 0)
              anchors.verticalCenter: parent.verticalCenter
            }

            IconButton {
              visible: entry.saved
              icon: "settings"
              size: Theme.size.buttonRow
              checked: entry.expanded && root.expandedMode === "manage"
              accessibleName: "Manage " + entry.modelData.name
              anchors.verticalCenter: parent.verticalCenter
              onClicked: root.expand(entry.modelData.name, "manage")
            }

            Button {
              size: Theme.size.buttonRow
              variant: entry.modelData.connected ? "ghost" : "secondary"
              text: entry.modelData.connected ? "Disconnect" : entry.enterprise && !entry.modelData.known ? "Sign in" : "Connect"
              onClicked: {
                const n = entry.modelData;
                if (n.connected) n.disconnect();
                else if (n.known || !entry.secured) n.connect();
                else root.expand(n.name, entry.enterprise ? "enterprise" : "password");
              }
            }
          }

          // --- A new secured network: its password ---------------------------------
          RowLayout {
            visible: entry.expanded && root.expandedMode === "password"
            width: parent.width - 20
            x: 10
            height: visible ? implicitHeight + 10 : 0
            spacing: 6

            TextField {
              id: password
              Layout.fillWidth: true
              placeholder: "Password"
              password: true
              capsLock: Lock.capsLock
              onAccepted: connectButton.clicked()
            }

            Button {
              id: connectButton
              text: "Join"
              variant: "primary"
              onClicked: {
                entry.modelData.connectWithPsk(password.text);
                password.text = "";
                root.expand("", "");
              }
            }
          }

          // --- School or work (eduroam): username and password -------------------------
          ColumnLayout {
            visible: entry.expanded && root.expandedMode === "enterprise"
            width: parent.width - 20
            x: 10
            height: visible ? implicitHeight + 12 : 0
            spacing: 6

            TextField { id: identity; Layout.fillWidth: true; placeholder: "Username, e.g. you@school.nl" }
            TextField { id: eapPassword; Layout.fillWidth: true; placeholder: "Password"; password: true; capsLock: Lock.capsLock }
            Dropdown {
              id: method
              Layout.fillWidth: true
              model: WifiAdmin.methods.map(m => m.label)
              currentIndex: 0
              accessibleName: "Sign-in method"
              onActivated: index => currentIndex = index
            }
            TextField { id: domain; Layout.fillWidth: true; placeholder: "Server domain (optional, e.g. school.nl)" }
            Label {
              Layout.fillWidth: true
              text: "Eduroam: your school email and password, usually PEAP. Your school's IT page lists the method and domain; the geteduroam app (AUR geteduroam-linux) sets it up for you too."
              kind: "muted"
              font.pixelSize: Theme.font.label
              wrapMode: Text.Wrap
            }
            Button {
              Layout.alignment: Qt.AlignRight
              text: WifiAdmin.busy ? "Connecting…" : "Join"
              variant: "primary"
              onClicked: {
                if (identity.text.trim() === "" || eapPassword.text === "") return;
                // No anonymous identity: not every school accepts one
                WifiAdmin.joinEnterprise(entry.modelData.name, identity.text.trim(), eapPassword.text, method.currentIndex,
                                         domain.text.trim(), "");
                eapPassword.text = "";
                root.expand("", "");
              }
            }
          }

          // --- A saved network: auto-connect, password, Forget -------------------------------
          ColumnLayout {
            visible: entry.expanded && root.expandedMode === "manage"
            width: parent.width - 20
            x: 10
            height: visible ? implicitHeight + 12 : 0
            spacing: 8

            RowLayout {
              Layout.fillWidth: true
              Label { Layout.fillWidth: true; text: "Connect automatically"; font.pixelSize: Theme.font.small }
              Toggle {
                checked: WifiAdmin.info.autoconnect ?? true
                enabled: (WifiAdmin.info.uuid ?? "") !== ""
                accessibleName: "Connect automatically to " + entry.modelData.name
                onToggled: value => WifiAdmin.setAutoconnect(entry.modelData.name, value)
              }
            }
            Label {
              visible: (WifiAdmin.info.identity ?? "") !== ""
              text: "Signed in as " + (WifiAdmin.info.identity ?? "")
              kind: "muted"
              font.pixelSize: Theme.font.label
            }
            RowLayout {
              Layout.fillWidth: true
              spacing: 6
              TextField {
                id: newPassword
                Layout.fillWidth: true
                placeholder: "New password"
                password: true
                capsLock: Lock.capsLock
                onAccepted: savePassword.clicked()
              }
              Button {
                id: savePassword
                text: "Save"
                variant: "secondary"
                size: Theme.size.buttonRow
                onClicked: {
                  if (newPassword.text === "") return;
                  WifiAdmin.setPassword(entry.modelData.name, newPassword.text);
                  newPassword.text = "";
                }
              }
            }
            Button {
              Layout.alignment: Qt.AlignRight
              text: root.confirmForget ? "Forget for good?" : "Forget network"
              variant: "dangerSoft"
              size: Theme.size.buttonRow
              onClicked: {
                if (!root.confirmForget) {
                  root.confirmForget = true;
                  return;
                }
                entry.modelData.forget();
                root.expand("", "");
              }
            }
          }
        }
      }
    }
  }

  // --- A network that doesn't broadcast its name ----------------------------------------
  Button {
    visible: root.network.hasWifiDevice && Networking.wifiEnabled && !root.addingHidden
    text: "Add hidden network"
    variant: "ghost"
    size: Theme.size.buttonRow
    onClicked: root.addingHidden = true
  }

  ColumnLayout {
    visible: root.addingHidden
    Layout.fillWidth: true
    spacing: 6

    Label { text: "Hidden network"; kind: "label" }
    TextField { id: hiddenName; Layout.fillWidth: true; placeholder: "Network name (SSID)" }
    TextField { id: hiddenPassword; Layout.fillWidth: true; placeholder: "Password (empty for an open network)"; password: true; capsLock: Lock.capsLock }
    RowLayout {
      Layout.alignment: Qt.AlignRight
      spacing: 6
      Button { text: "Cancel"; variant: "ghost"; size: Theme.size.buttonRow; onClicked: root.addingHidden = false }
      Button {
        text: "Join"
        variant: "primary"
        size: Theme.size.buttonRow
        onClicked: {
          if (hiddenName.text.trim() === "") return;
          WifiAdmin.addHidden(hiddenName.text.trim(), hiddenPassword.text);
          hiddenName.text = "";
          hiddenPassword.text = "";
          root.addingHidden = false;
        }
      }
    }
  }

  // What the last action did
  Label {
    visible: WifiAdmin.message !== ""
    Layout.fillWidth: true
    text: WifiAdmin.message
    color: WifiAdmin.failed ? Theme.error : Theme.subtext
    font.pixelSize: Theme.font.small
    wrapMode: Text.Wrap
  }
}
