// SystemStats.qml
// CPU, GPU, memory, disk, network and the busiest processes, for the system
// page in quick settings. It only measures while something asks for it
// (`active`), so it costs nothing when the panel is closed.
//
// CPU and memory come from /proc, CPU temperature from hwmon (k10temp or
// coretemp), the GPU from nvidia-smi or the amdgpu files in /sys, and the
// processes from `top` (its second sample, so the numbers are current).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  // Set by the panels that show these numbers
  readonly property bool active: Panels.quickSettingsOpen
  // How many seconds of history the graphs show
  readonly property int historyLength: 60

  // --- CPU -------------------------------------------------------------------------
  property string cpuModel: ""
  property int threads: 0
  property real cpu: 0
  property var cores: []
  property var cpuHistory: []
  property real cpuTemp: -1
  property var lastStat: null

  // --- GPU -------------------------------------------------------------------------
  // "nvidia", "amd" or "" (none found)
  property string gpuKind: ""
  property string gpuModel: ""
  property real gpu: 0
  property real gpuTemp: -1
  property real vramUsed: 0
  property real vramTotal: 0
  property var gpuHistory: []

  // --- Memory, disk, network ---------------------------------------------------------
  property real memUsed: 0
  property real memTotal: 0
  property real swapUsed: 0
  property real swapTotal: 0
  property real diskUsed: 0
  property real diskTotal: 0
  property real netDown: 0
  property real netUp: 0
  property var lastNet: null

  property var processes: []

  // --- What this machine has (once) -----------------------------------------------------
  property string cpuTempPath: ""
  property string amdPath: ""

  Process {
    running: true
    command: ["sh", "-c",
      "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2;" +
      "nproc;" +
      "for h in /sys/class/hwmon/hwmon*; do n=$(cat $h/name 2>/dev/null);" +
      "  case $n in k10temp|coretemp|zenpower|cpu_thermal) echo $h/temp1_input; break;; esac; done | head -1;" +
      "if command -v nvidia-smi >/dev/null && nvidia-smi -L >/dev/null 2>&1; then echo nvidia; nvidia-smi --query-gpu=name --format=csv,noheader | head -1;" +
      "else for c in /sys/class/drm/card*/device; do [ -f $c/gpu_busy_percent ] && echo amd && echo $c && break; done; fi"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n").map(l => l.trim());
        root.cpuModel = (lines[0] ?? "").replace(/\s+\d+-Core Processor$/, "").replace(/^AMD /, "").replace(/\(R\)|\(TM\)/g, "");
        root.threads = parseInt(lines[1] ?? "0") || 0;
        root.cpuTempPath = lines[2] ?? "";
        if (lines[3] === "nvidia") {
          root.gpuKind = "nvidia";
          root.gpuModel = (lines[4] ?? "").replace(/^NVIDIA /, "");
        } else if (lines[3] === "amd") {
          root.gpuKind = "amd";
          root.amdPath = lines[4] ?? "";
          root.gpuModel = "AMD GPU";
        }
      }
    }
  }

  // --- Sampling ------------------------------------------------------------------------
  property int ticks: 0

  Timer {
    running: root.active
    interval: 1000
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload();
      memFile.reload();
      netFile.reload();
      if (root.cpuTempPath !== "") tempProc.running = true;
      if (root.ticks % 2 === 0) {
        if (root.gpuKind === "nvidia") nvidiaProc.running = true;
        else if (root.gpuKind === "amd") amdProc.running = true;
        topProc.running = true;
      }
      if (root.ticks % 30 === 0) diskProc.running = true;
      root.ticks++;
      root.gpuHistory = root.push(root.gpuHistory, root.gpu);
    }
  }

  // The bar's load pill: a slow look every 5 s while the panel is closed
  // (Settings → Bar & panels → High load). Two hot samples in a row count.
  property int hotSamples: 0
  readonly property bool heavy: hotSamples >= 2 || Fake.has("load")
  readonly property real hottest: Math.max(cpuTemp, gpuTemp)

  Timer {
    running: !root.active && Config.bar.showLoad
    interval: 5000
    repeat: true
    onTriggered: {
      statFile.reload();
      if (root.cpuTempPath !== "") tempProc.running = true;
      if (root.gpuKind === "nvidia") nvidiaProc.running = true;
      else if (root.gpuKind === "amd") amdProc.running = true;
    }
  }

  // Judged every 5 s, open or closed
  Timer {
    running: Config.bar.showLoad
    interval: 5000
    repeat: true
    onTriggered: {
      const hot = root.cpu >= 90 || root.gpu >= 90 || root.hottest >= 85;
      root.hotSamples = hot ? Math.min(root.hotSamples + 1, 2) : 0;
    }
  }

  // Start fresh each time, so a graph never jumps over the time it was closed
  onActiveChanged: {
    if (!active) return;
    ticks = 0;
    lastStat = null;
    lastNet = null;
    cpuHistory = [];
    gpuHistory = [];
  }

  function push(list: var, value: real): var {
    const next = list.concat([value]);
    return next.length > historyLength ? next.slice(next.length - historyLength) : next;
  }

  FileView {
    id: statFile
    path: "/proc/stat"
    onLoaded: root.parseStat(text())
  }

  function parseStat(text: string): void {
    const now = {};
    for (const line of text.split("\n")) {
      if (!line.startsWith("cpu")) break;
      const parts = line.trim().split(/\s+/);
      const values = parts.slice(1).map(Number);
      const idle = values[3] + (values[4] ?? 0);
      const total = values.reduce((a, b) => a + b, 0);
      now[parts[0]] = { idle, total };
    }
    const before = lastStat;
    lastStat = now;
    if (!before) return;
    const usage = key => {
      const a = before[key], b = now[key];
      if (!a || !b || b.total === a.total) return 0;
      return Math.max(0, Math.min(1, 1 - (b.idle - a.idle) / (b.total - a.total)));
    };
    cpu = usage("cpu");
    cores = Object.keys(now).filter(k => k !== "cpu").map(usage);
    cpuHistory = push(cpuHistory, cpu);
  }

  FileView {
    id: memFile
    path: "/proc/meminfo"
    onLoaded: {
      const value = name => {
        const m = text().match(new RegExp("^" + name + ":\\s+(\\d+)", "m"));
        return m ? parseInt(m[1]) * 1024 : 0;
      };
      root.memTotal = value("MemTotal");
      root.memUsed = root.memTotal - value("MemAvailable");
      root.swapTotal = value("SwapTotal");
      root.swapUsed = root.swapTotal - value("SwapFree");
    }
  }

  FileView {
    id: netFile
    path: "/proc/net/dev"
    onLoaded: {
      let rx = 0, tx = 0;
      for (const line of text().split("\n").slice(2)) {
        const m = line.trim().match(/^([^:]+):\s*(.*)$/);
        if (!m) continue;
        const name = m[1].trim();
        // Only real interfaces: not loopback, containers or VPN tunnels counted twice
        if (name === "lo" || /^(veth|docker|br-|virbr)/.test(name)) continue;
        const f = m[2].split(/\s+/).map(Number);
        rx += f[0];
        tx += f[8];
      }
      const now = { rx, tx, at: Date.now() };
      const before = root.lastNet;
      root.lastNet = now;
      if (!before) return;
      const seconds = Math.max(0.001, (now.at - before.at) / 1000);
      root.netDown = Math.max(0, (now.rx - before.rx) / seconds);
      root.netUp = Math.max(0, (now.tx - before.tx) / seconds);
    }
  }

  Process {
    id: tempProc
    command: ["cat", root.cpuTempPath]
    stdout: StdioCollector {
      onStreamFinished: {
        const v = parseInt(text);
        root.cpuTemp = isNaN(v) ? -1 : v / 1000;
      }
    }
  }

  Process {
    id: nvidiaProc
    command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = text.split("\n")[0].split(",").map(s => parseFloat(s));
        if (f.length < 4 || f.some(isNaN)) return;
        root.gpu = f[0] / 100;
        root.gpuTemp = f[1];
        root.vramUsed = f[2] * 1048576;
        root.vramTotal = f[3] * 1048576;
      }
    }
  }

  Process {
    id: amdProc
    command: ["sh", "-c", "cd \"$1\" && cat gpu_busy_percent mem_info_vram_used mem_info_vram_total; cat hwmon/hwmon*/temp1_input 2>/dev/null | head -1", "sh", root.amdPath]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = text.split("\n").map(Number);
        root.gpu = (f[0] || 0) / 100;
        root.vramUsed = f[1] || 0;
        root.vramTotal = f[2] || 0;
        root.gpuTemp = f[3] ? f[3] / 1000 : -1;
      }
    }
  }

  Process {
    id: diskProc
    command: ["df", "-B1", "--output=used,size", "/"]
    stdout: StdioCollector {
      onStreamFinished: {
        const f = (text.split("\n")[1] ?? "").trim().split(/\s+/).map(Number);
        root.diskUsed = f[0] || 0;
        root.diskTotal = f[1] || 0;
      }
    }
  }

  // The second sample of `top` measures the last half second, not since boot
  Process {
    id: topProc
    command: ["sh", "-c", "top -b -n 2 -d 0.5 -w 512 | awk '/^top -/{n++} n==2' | sed -n '8,13p'"]
    stdout: StdioCollector {
      onStreamFinished: {
        const list = [];
        for (const line of text.split("\n")) {
          const f = line.trim().split(/\s+/);
          if (f.length < 12) continue;
          list.push({
            pid: f[0],
            name: f.slice(11).join(" "),
            // top counts 100% per thread; show it as a share of the whole CPU
            cpu: parseFloat(f[8]) / Math.max(1, root.threads),
            mem: root.parseSize(f[5])
          });
        }
        root.processes = list.slice(0, 6);
      }
    }
  }

  // top's RES: plain KiB, or with m / g / t
  function parseSize(text: string): real {
    const m = text.match(/^([\d.]+)([kmgt]?)$/i);
    if (!m) return 0;
    const factor = { "": 1024, k: 1024, m: 1048576, g: 1073741824, t: 1099511627776 }[m[2].toLowerCase()];
    return parseFloat(m[1]) * factor;
  }

  function kill(pid: string): void {
    Quickshell.execDetached(["kill", pid]);
    topProc.running = true;
  }

  // "6.5 GB", "512 MB"
  function bytes(n: real): string {
    if (n >= 1099511627776) return (n / 1099511627776).toFixed(1) + " TB";
    if (n >= 1073741824) return (n / 1073741824).toFixed(1) + " GB";
    return Math.round(n / 1048576) + " MB";
  }

  // Network speed: "48 Mbit/s", "4.2 Mbit/s", "14 kbit/s"
  function rate(bytesPerSecond: real): string {
    const bits = bytesPerSecond * 8;
    if (bits >= 10000000) return Math.round(bits / 1000000) + " Mbit/s";
    if (bits >= 1000000) return (bits / 1000000).toFixed(1) + " Mbit/s";
    return Math.round(bits / 1000) + " kbit/s";
  }
}
