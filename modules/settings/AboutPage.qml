// AboutPage.qml
// What this is and what it runs on, plus a few handy actions.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../config"
import "../../components"
import "../../services"

SettingsPage {
  id: page
  title: "About"

  readonly property string folder: Quickshell.shellPath("")
  property string system: ""
  property string kernel: ""
  property string quickshell: ""
  property string git: ""
  property string memory: ""
  property string updates: ""

  readonly property var rows: [
    { k: "System", v: system },
    { k: "Kernel", v: kernel },
    { k: "CPU", v: SystemStats.cpuModel + (SystemStats.threads > 0 ? " · " + SystemStats.threads + " threads" : "") },
    { k: "GPU", v: SystemStats.gpuModel !== "" ? SystemStats.gpuModel : "—" },
    { k: "Memory", v: memory },
    { k: "Displays", v: Quickshell.screens.map(s => s.name + " " + s.width + "×" + s.height).join(" · ") },
    { k: "Uptime", v: Power.uptime.replace(/^Up /, "") }
  ].filter(r => r.v !== "")

  Component.onCompleted: {
    Power.refreshInfo();
    infoProc.running = true;
  }

  Process {
    id: infoProc
    command: ["sh", "-c",
      ". /etc/os-release 2>/dev/null; echo \"${PRETTY_NAME:-Linux}\"; uname -r;" +
      "qs --version 2>/dev/null | head -1;" +
      "git -C \"$1\" rev-parse --abbrev-ref HEAD 2>/dev/null || echo -;" +
      "awk '/MemTotal/ {printf \"%.0f GB\\n\", $2/1048576}' /proc/meminfo", "sh", page.folder]
    stdout: StdioCollector {
      onStreamFinished: {
        const l = text.split("\n");
        page.system = l[0] ?? "";
        page.kernel = l[1] ?? "";
        // "quickshell 0.3.2 (revision …)" -> "0.3.2"
        page.quickshell = ((l[2] ?? "").match(/\d+\.\d+(\.\d+)?/) ?? [""])[0];
        page.git = l[3] && l[3] !== "-" ? l[3] : "";
        page.memory = l[4] ?? "";
      }
    }
  }

  // Fetches and compares with the remote branch; nothing is changed
  Process {
    id: updateProc
    command: ["sh", "-c", "cd \"$1\" && git fetch -q 2>/dev/null && git rev-list --count HEAD..@{u} 2>/dev/null || echo error", "sh", page.folder]
    stdout: StdioCollector {
      onStreamFinished: {
        const n = text.trim();
        page.updates = n === "error" ? "Couldn't check (no remote branch?)"
                     : n === "0" ? "Up to date"
                     : n + (n === "1" ? " new commit" : " new commits") + " · run git pull in " + page.folder;
      }
    }
  }

  function systemInfo(): string {
    return rows.map(r => r.k + ": " + r.v).join("\n") + "\nQuickshell: " + quickshell;
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: 96
    radius: Theme.radiusCard
    color: Theme.item

    RowLayout {
      anchors.fill: parent
      anchors.margins: 16
      spacing: 16

      Rectangle {
        implicitWidth: 64
        implicitHeight: 64
        radius: 20
        color: Theme.accent
        Icon { anchors.centerIn: parent; name: "monitor"; size: 30; color: Theme.onAccent }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 4
        Label { text: "Your Quickshell config"; kind: "title"; font.pixelSize: Theme.font.title + 2 }
        Label { text: "Quickshell " + (page.quickshell || "?") + " · Hyprland"; color: Theme.subtext; font.pixelSize: Theme.font.small }
        Label {
          text: page.folder.replace(Quickshell.env("HOME"), "~") + (page.git !== "" ? " · git: " + page.git : "") + (page.updates !== "" ? " · " + page.updates : "")
          kind: "muted"
          font.pixelSize: Theme.font.label
          elide: Text.ElideRight
          Layout.fillWidth: true
        }
      }
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: infoColumn.implicitHeight
    radius: Theme.radiusCard
    color: Theme.item
    clip: true

    ColumnLayout {
      id: infoColumn
      width: parent.width
      spacing: 0

      Repeater {
        model: page.rows

        Item {
          id: infoRow
          required property var modelData
          required property int index
          Layout.fillWidth: true
          implicitHeight: 38

          Rectangle { visible: infoRow.index > 0; width: parent.width; height: 1; color: Theme.hairline }
          Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: infoRow.modelData.k; kind: "muted"; font.pixelSize: Theme.font.small }
          Label {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width - 120)
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
            text: infoRow.modelData.v
            font.weight: Font.Bold
            font.pixelSize: Theme.font.small
          }
        }
      }
    }
  }

  Flow {
    Layout.fillWidth: true
    spacing: 8

    Button { text: "Check for updates"; variant: "primary"; onClicked: { page.updates = "Checking…"; updateProc.running = true; } }
    Button { text: "Reload shell"; variant: "ghost"; onClicked: Quickshell.reload(false) }
    Button { text: "Copy system info"; variant: "ghost"; onClicked: Quickshell.execDetached(["wl-copy", page.systemInfo()]) }
    Button { text: "Open config folder"; variant: "ghost"; onClicked: Qt.openUrlExternally("file://" + page.folder) }
    Button { text: "Show logs"; variant: "ghost"; onClicked: DefaultApps.inTerminal("qs log -p \"$1\" -f", [page.folder]) }
  }
}
