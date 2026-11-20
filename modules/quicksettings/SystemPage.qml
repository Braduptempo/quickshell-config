// SystemPage.qml
// The system monitor page in quick settings: CPU and GPU with a graph of the
// last minute and their temperature, memory, disk, network, and the busiest
// processes (click the cross twice to stop one). Numbers: services/SystemStats.qml.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../config"
import "../../components"
import "../../services"

ColumnLayout {
  id: root

  spacing: 12

  function percent(v: real): string {
    return Math.round(v * 100) + "%";
  }

  function tempColor(t: real): color {
    return t >= 80 ? Theme.error : t >= 65 ? Theme.warn : Theme.good;
  }

  PageHeader {
    title: "System"
    Layout.fillWidth: true
  }

  // --- CPU and GPU ---------------------------------------------------------------------
  component Chip: Rectangle {
    id: chip
    property string title
    property string model
    property real value: 0
    property real temp: -1
    property var history: []
    property color lineColor: Theme.accent
    property bool available: true
    default property alias extra: extraColumn.data

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: chipColumn.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    Accessible.role: Accessible.Grouping
    Accessible.name: title + " " + root.percent(value) + (temp >= 0 ? ", " + Math.round(temp) + " degrees" : "")

    ColumnLayout {
      id: chipColumn
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 6

      RowLayout {
        Layout.fillWidth: true
        Label { text: chip.title; kind: "label" }
        Item { Layout.fillWidth: true }
        Label {
          visible: chip.available && chip.temp >= 0
          text: Math.round(chip.temp) + "°C"
          color: root.tempColor(chip.temp)
          font.pixelSize: Theme.font.small
          font.weight: Font.Bold
        }
      }

      Label {
        text: chip.available ? root.percent(chip.value) : "—"
        font.pixelSize: Theme.font.section
        font.weight: Font.Bold
      }

      Label {
        Layout.fillWidth: true
        text: chip.available ? chip.model : "No GPU found"
        kind: "muted"
        font.pixelSize: Theme.font.label
        elide: Text.ElideRight
      }

      // The last minute
      Canvas {
        id: graph
        visible: chip.available
        Layout.fillWidth: true
        implicitHeight: 40
        readonly property var points: chip.history
        onPointsChanged: requestPaint()
        onWidthChanged: requestPaint()
        onPaint: {
          const ctx = getContext("2d");
          ctx.reset();
          const n = SystemStats.historyLength;
          const list = points;
          if (list.length < 2) return;
          const step = width / (n - 1);
          const x0 = width - (list.length - 1) * step;
          ctx.beginPath();
          for (let i = 0; i < list.length; i++) {
            const x = x0 + i * step;
            const y = height - 2 - list[i] * (height - 4);
            if (i === 0) ctx.moveTo(x, y);
            else ctx.lineTo(x, y);
          }
          ctx.lineWidth = 2;
          ctx.lineJoin = "round";
          ctx.strokeStyle = chip.lineColor;
          ctx.stroke();
          // Soft fill under the line
          ctx.lineTo(width, height);
          ctx.lineTo(x0, height);
          ctx.closePath();
          ctx.fillStyle = Qt.rgba(chip.lineColor.r, chip.lineColor.g, chip.lineColor.b, 0.15);
          ctx.fill();
        }
      }

      ColumnLayout {
        id: extraColumn
        Layout.fillWidth: true
        spacing: 4
      }
    }
  }

  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Chip {
      title: "CPU"
      model: SystemStats.cpuModel + (SystemStats.threads > 0 ? " · " + SystemStats.threads + " threads" : "")
      value: SystemStats.cpu
      temp: SystemStats.cpuTemp
      history: SystemStats.cpuHistory
      lineColor: Theme.accent

      Label { text: "Per thread"; kind: "muted"; font.pixelSize: Theme.font.label }
      Item {
        id: coreBars
        Layout.fillWidth: true
        implicitHeight: 18

        Row {
          anchors.fill: parent
          spacing: 2
          Repeater {
            model: SystemStats.cores
            Rectangle {
              id: coreBar
              required property real modelData
              width: Math.max(2, (coreBars.width - (SystemStats.cores.length - 1) * 2) / Math.max(1, SystemStats.cores.length))
              height: 18
              radius: 1
              color: Theme.alpha(Theme.text, 0.1)
              Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: Math.max(1, parent.height * coreBar.modelData)
                radius: 1
                color: Theme.accent
              }
            }
          }
        }
      }
    }

    Chip {
      title: "GPU"
      available: SystemStats.gpuKind !== ""
      model: SystemStats.gpuModel
      value: SystemStats.gpu
      temp: SystemStats.gpuTemp
      history: SystemStats.gpuHistory
      lineColor: Theme.palette.dots[5] ?? Theme.accent

      Label {
        visible: SystemStats.vramTotal > 0
        text: "Video memory " + SystemStats.bytes(SystemStats.vramUsed) + " / " + SystemStats.bytes(SystemStats.vramTotal)
        kind: "muted"
        font.pixelSize: Theme.font.label
        Layout.fillWidth: true
        elide: Text.ElideRight
      }
      Rectangle {
        visible: SystemStats.vramTotal > 0
        Layout.fillWidth: true
        implicitHeight: 6
        radius: 3
        color: Theme.alpha(Theme.text, 0.1)
        Rectangle {
          width: parent.width * Math.min(1, SystemStats.vramUsed / Math.max(1, SystemStats.vramTotal))
          height: parent.height
          radius: 3
          color: Theme.palette.dots[5] ?? Theme.accent
        }
      }
    }
  }

  // --- Memory, disk, network ---------------------------------------------------------------
  component Meter: ColumnLayout {
    id: meter
    property string title
    property string value
    property string sub
    property real fraction: 0
    property color barColor: Theme.accent

    Layout.fillWidth: true
    spacing: 5

    Accessible.role: Accessible.ProgressBar
    Accessible.name: title + " " + value

    RowLayout {
      Layout.fillWidth: true
      Label { text: meter.title; kind: "label" }
      Item { Layout.fillWidth: true }
      Label { text: meter.value; font.weight: Font.Bold; font.pixelSize: Theme.font.small }
    }
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 6
      radius: 3
      color: Theme.alpha(Theme.text, 0.1)
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, meter.fraction))
        height: parent.height
        radius: 3
        color: meter.barColor
        Behavior on width { NumberAnimation { duration: Theme.anim.toggle } }
      }
    }
    Label {
      visible: text !== ""
      text: meter.sub
      kind: "muted"
      font.pixelSize: Theme.font.label
    }
  }

  Rectangle {
    Layout.fillWidth: true
    implicitHeight: meters.implicitHeight + 24
    radius: Theme.radiusCard
    color: Theme.item

    ColumnLayout {
      id: meters
      x: 12
      y: 12
      width: parent.width - 24
      spacing: 12

      Meter {
        title: "Memory"
        value: SystemStats.bytes(SystemStats.memUsed) + " / " + SystemStats.bytes(SystemStats.memTotal)
        fraction: SystemStats.memUsed / Math.max(1, SystemStats.memTotal)
        barColor: Theme.good
        sub: SystemStats.swapTotal > 0 ? "Swap " + SystemStats.bytes(SystemStats.swapUsed) + " / " + SystemStats.bytes(SystemStats.swapTotal) : ""
      }
      Meter {
        title: "Disk /"
        value: SystemStats.diskTotal > 0 ? SystemStats.bytes(SystemStats.diskUsed) + " / " + SystemStats.bytes(SystemStats.diskTotal) : "…"
        fraction: SystemStats.diskUsed / Math.max(1, SystemStats.diskTotal)
        barColor: Theme.warn
      }
      Meter {
        title: "Network"
        value: "↓ " + SystemStats.rate(SystemStats.netDown) + "  ↑ " + SystemStats.rate(SystemStats.netUp)
        // Fills up to 100 Mbit/s, so normal browsing is visible
        fraction: Math.min(1, SystemStats.netDown * 8 / 100000000)
        barColor: Theme.palette.dots[4] ?? Theme.accent
      }
    }
  }

  // --- Busiest processes --------------------------------------------------------------------
  Rectangle {
    id: procBox
    Layout.fillWidth: true
    implicitHeight: procColumn.implicitHeight + 20
    radius: Theme.radiusCard
    color: Theme.item

    // The process waiting for a second click
    property string confirmPid: ""

    Timer {
      id: confirmReset
      interval: 3000
      onTriggered: procBox.confirmPid = ""
    }

    ColumnLayout {
      id: procColumn
      x: 10
      y: 10
      width: parent.width - 20
      spacing: 2

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 34
        Label { text: "Processes"; kind: "label"; Layout.fillWidth: true }
        Label { text: "CPU"; kind: "label"; Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight }
        Label { text: "Memory"; kind: "label"; Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
      }

      Repeater {
        model: SystemStats.processes

        RowLayout {
          id: proc
          required property var modelData
          readonly property bool confirming: procBox.confirmPid === modelData.pid

          Layout.fillWidth: true
          implicitHeight: 30
          spacing: 0

          Label {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            text: proc.confirming ? "Stop " + proc.modelData.name + "?" : proc.modelData.name
            color: proc.confirming ? Theme.error : Theme.text
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
          }
          Label {
            Layout.preferredWidth: 48
            horizontalAlignment: Text.AlignRight
            text: proc.modelData.cpu.toFixed(1) + "%"
            color: proc.modelData.cpu >= 10 ? Theme.warn : Theme.subtext
            font.pixelSize: Theme.font.small
          }
          Label {
            Layout.preferredWidth: 64
            horizontalAlignment: Text.AlignRight
            text: SystemStats.bytes(proc.modelData.mem)
            color: Theme.subtext
            font.pixelSize: Theme.font.small
          }
          IconButton {
            Layout.leftMargin: 6
            size: 28
            icon: "close"
            variant: proc.confirming ? "dangerSoft" : "plain"
            accessibleName: proc.confirming ? "Click again to stop " + proc.modelData.name : "Stop " + proc.modelData.name
            onClicked: {
              if (proc.confirming) {
                procBox.confirmPid = "";
                SystemStats.kill(proc.modelData.pid);
              } else {
                procBox.confirmPid = proc.modelData.pid;
                confirmReset.restart();
              }
            }
          }
        }
      }
    }
  }
}
