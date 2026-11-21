// BluetoothCheck.qml
// Why there's no Bluetooth adapter, and what fixes it. Only runs while
// Bluetooth.defaultAdapter is missing (BlueZ shows no adapter).
//   BluetoothCheck.problem   "service" | "blocked" | "hardblocked" | "notinstalled" | "nohardware" | ""
//   BluetoothCheck.title / detail / command   text for the hint
//   BluetoothCheck.fix()     runs the fix that needs no terminal (start the service, unblock)
// QS_BT_FAKE=<problem> pretends the adapter is missing for that reason (testing).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth

Singleton {
  id: root

  readonly property string fake: Quickshell.env("QS_BT_FAKE") ?? ""
  readonly property bool missing: fake !== "" || Bluetooth.defaultAdapter === null
  property string problem: ""
  property bool fixing: false

  readonly property string title: ({
    service: "The Bluetooth service isn't running",
    blocked: "Bluetooth is blocked",
    hardblocked: "Bluetooth is switched off in hardware",
    notinstalled: "BlueZ isn't installed",
    nohardware: "No Bluetooth hardware found"
  })[problem] ?? "No Bluetooth adapter found"

  readonly property string detail: ({
    service: "The adapter is there, but bluetooth.service is stopped or disabled. Start it now and at every boot:",
    blocked: "rfkill has turned Bluetooth off (airplane mode, or a key). Unblock it:",
    hardblocked: "A switch, an Fn key or the BIOS/UEFI has turned the radio off. Turn it on there; this can't be done from here.",
    notinstalled: "Install the Bluetooth stack, then start its service:",
    nohardware: "Linux doesn't see a Bluetooth adapter. Check that it's enabled in the BIOS/UEFI and that the btusb driver is loaded:"
  })[problem] ?? ""

  readonly property string command: ({
    service: "sudo systemctl enable --now bluetooth",
    blocked: "rfkill unblock bluetooth",
    notinstalled: "sudo pacman -S bluez bluez-utils && sudo systemctl enable --now bluetooth",
    nohardware: "sudo modprobe btusb"
  })[problem] ?? ""

  // A button can do it for you (asks your password where needed)
  readonly property bool canFix: problem === "service" || problem === "blocked"
  readonly property string fixLabel: problem === "service" ? "Start Bluetooth" : "Unblock"

  function check(): void {
    if (fake !== "") {
      problem = fake;
      return;
    }
    if (missing) probe.running = true;
    else problem = "";
  }

  function fix(): void {
    if (fake !== "" || !canFix) return;
    fixing = true;
    run.command = problem === "service"
      ? ["pkexec", "systemctl", "enable", "--now", "bluetooth.service"]
      : ["rfkill", "unblock", "bluetooth"];
    run.running = true;
  }

  onMissingChanged: check()
  Component.onCompleted: check()

  Process {
    id: probe
    command: ["sh", "-c",
      "echo hw=$(ls /sys/class/bluetooth 2>/dev/null | head -n1);"
      + "systemctl cat bluetooth.service >/dev/null 2>&1 && echo installed=yes;"
      + "echo svc=$(systemctl is-active bluetooth.service 2>/dev/null);"
      + "echo hard=$(rfkill -rn -o TYPE,HARD 2>/dev/null | grep -c '^bluetooth blocked');"
      + "echo soft=$(rfkill -rn -o TYPE,SOFT 2>/dev/null | grep -c '^bluetooth blocked');"
      + "echo radio=$(rfkill -rn -o TYPE 2>/dev/null | grep -c '^bluetooth')"]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = {};
        for (const line of text.split("\n")) {
          const i = line.indexOf("=");
          if (i > 0) v[line.slice(0, i)] = line.slice(i + 1).trim();
        }
        if (parseInt(v.hard) > 0) root.problem = "hardblocked";
        else if (parseInt(v.soft) > 0) root.problem = "blocked";
        else if (v.installed !== "yes") root.problem = "notinstalled";
        else if (v.svc !== "active") root.problem = "service";
        else if (!v.hw && parseInt(v.radio) === 0) root.problem = "nohardware";
        else root.problem = "";
      }
    }
  }

  Process {
    id: run
    onExited: {
      root.fixing = false;
      recheck.restart();
    }
  }

  // BlueZ needs a moment to show the adapter
  Timer {
    id: recheck
    interval: 1500
    onTriggered: root.check()
  }
}
