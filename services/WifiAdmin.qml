// WifiAdmin.qml
// What Quickshell's Networking can't do itself, through nmcli: school and
// work networks (WPA2-Enterprise such as eduroam), hidden networks, and a
// saved network's password and auto-connect.
// Passwords never go on a command line (other programs can read those): they
// reach NetworkManager through stdin of `nmcli connection edit`, in $PW.
//   WifiAdmin.joinEnterprise(ssid, identity, password, method, domain, anonymous)
//   WifiAdmin.addHidden(ssid, password)
//   WifiAdmin.inspect(ssid) fills WifiAdmin.info { uuid, autoconnect, enterprise, identity }
//   WifiAdmin.setPassword(ssid, password) / setAutoconnect(ssid, on)
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool busy: false
  // Result of the last action, for under the list
  property string message: ""
  property bool failed: false
  property var info: ({})

  // EAP method labels and their nmcli settings
  readonly property var methods: [
    { label: "PEAP (MSCHAPv2)", eap: "peap", phase2: "mschapv2" },
    { label: "TTLS (PAP)", eap: "ttls", phase2: "pap" },
    { label: "TTLS (MSCHAPv2)", eap: "ttls", phase2: "mschapv2" }
  ]

  // uuid_of SSID: the saved Wi-Fi connection for a network name
  readonly property string helpers:
    "uuid_of() { nmcli -g UUID,TYPE connection show | while IFS=: read -r u t; do "
    + "[ \"$t\" = 802-11-wireless ] && [ \"$(nmcli -g 802-11-wireless.ssid connection show \"$u\")\" = \"$1\" ] && { echo \"$u\"; break; }; "
    + "done; }\n"
    // set_secret UUID KEY: the password from $PW, through stdin
    + "set_secret() { printf 'set %s %s\\nsave persistent\\nquit\\n' \"$2\" \"$PW\" | nmcli connection edit uuid \"$1\" >/dev/null; }\n"

  function start(what: string, script: string, args: var, password: string): void {
    busy = true;
    failed = false;
    message = what;
    run.environment = { PW: password };
    run.command = ["sh", "-c", helpers + script, "sh"].concat(args);
    run.running = true;
  }

  function joinEnterprise(ssid: string, identity: string, password: string, method: int, domain: string, anonymous: string): void {
    const m = methods[method] ?? methods[0];
    start("Connecting to " + ssid + "…",
      "ssid=$1; id=$2; eap=$3; p2=$4; dom=$5; anon=$6\n"
      + "old=$(uuid_of \"$ssid\"); [ -n \"$old\" ] && nmcli connection delete uuid \"$old\" >/dev/null\n"
      + "set -- type wifi con-name \"$ssid\" ssid \"$ssid\" wifi-sec.key-mgmt wpa-eap 802-1x.eap \"$eap\" 802-1x.phase2-auth \"$p2\" 802-1x.identity \"$id\" 802-1x.password-flags 0\n"
      + "[ -n \"$anon\" ] && set -- \"$@\" 802-1x.anonymous-identity \"$anon\"\n"
      + "[ -n \"$dom\" ] && set -- \"$@\" 802-1x.domain-suffix-match \"$dom\" 802-1x.system-ca-certs yes\n"
      + "nmcli connection add \"$@\" >/dev/null || exit 1\n"
      + "u=$(uuid_of \"$ssid\"); [ -n \"$u\" ] || exit 1\n"
      + "set_secret \"$u\" 802-1x.password\n"
      + "nmcli --wait 40 connection up uuid \"$u\" >/dev/null",
      [ssid, identity, m.eap, m.phase2, domain, anonymous], password);
  }

  function addHidden(ssid: string, password: string): void {
    start("Connecting to " + ssid + "…",
      "old=$(uuid_of \"$1\"); [ -n \"$old\" ] && nmcli connection delete uuid \"$old\" >/dev/null\n"
      + "if [ -n \"$PW\" ]; then nmcli connection add type wifi con-name \"$1\" ssid \"$1\" 802-11-wireless.hidden yes wifi-sec.key-mgmt wpa-psk wifi-sec.psk 00000000 wifi-sec.psk-flags 0 >/dev/null || exit 1\n"
      + "else nmcli connection add type wifi con-name \"$1\" ssid \"$1\" 802-11-wireless.hidden yes >/dev/null || exit 1; fi\n"
      + "u=$(uuid_of \"$1\"); [ -n \"$u\" ] || exit 1\n"
      // nmcli wants a key to create the network; the real one replaces it
      + "[ -n \"$PW\" ] && set_secret \"$u\" 802-11-wireless-security.psk\n"
      + "nmcli --wait 40 connection up uuid \"$u\" >/dev/null",
      [ssid], password);
  }

  function setPassword(ssid: string, password: string): void {
    start("Saving…",
      "u=$(uuid_of \"$1\"); [ -n \"$u\" ] || exit 1\n"
      + "if [ \"$(nmcli -g 802-11-wireless-security.key-mgmt connection show \"$u\")\" = wpa-eap ]; then set_secret \"$u\" 802-1x.password; "
      + "else set_secret \"$u\" 802-11-wireless-security.psk; fi",
      [ssid], password);
  }

  function setAutoconnect(ssid: string, on: bool): void {
    start("Saving…",
      "u=$(uuid_of \"$1\"); [ -n \"$u\" ] || exit 1\n"
      + "nmcli connection modify uuid \"$u\" connection.autoconnect \"$2\"",
      [ssid, on ? "yes" : "no"], "");
    info = Object.assign({}, info, { autoconnect: on });
  }

  // --- Reading a saved network ---------------------------------------------------------
  function inspect(ssid: string): void {
    info = {};
    inspectProc.command = ["sh", "-c", helpers
      + "u=$(uuid_of \"$1\"); [ -n \"$u\" ] || exit 0\n"
      + "echo \"uuid=$u\"\n"
      + "nmcli -g connection.autoconnect,802-11-wireless-security.key-mgmt,802-1x.identity connection show \"$u\" | sed -n '1s/^/auto=/p;2s/^/keymgmt=/p;3s/^/identity=/p'",
      "sh", ssid];
    inspectProc.running = true;
  }

  Process {
    id: inspectProc
    stdout: StdioCollector {
      onStreamFinished: {
        const v = {};
        for (const line of text.split("\n")) {
          const i = line.indexOf("=");
          if (i > 0) v[line.slice(0, i)] = line.slice(i + 1);
        }
        root.info = { uuid: v.uuid ?? "", autoconnect: v.auto === "yes", enterprise: v.keymgmt === "wpa-eap", identity: v.identity ?? "" };
      }
    }
  }

  Process {
    id: run
    stderr: StdioCollector { id: runErr }
    onExited: code => {
      root.busy = false;
      root.failed = code !== 0;
      const why = runErr.text.trim().split("\n").pop().replace(/^Error: /, "");
      root.message = code === 0 ? "Done" : "Couldn't do it" + (why !== "" ? ": " + why : "");
      clearMessage.restart();
    }
  }

  Timer {
    id: clearMessage
    interval: 8000
    onTriggered: if (!root.busy) root.message = ""
  }
}
