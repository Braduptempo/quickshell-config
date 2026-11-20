// Drives.qml
// Removable drives (USB sticks, SD cards, external disks): listed with lsblk,
// mounted, opened and ejected with udisksctl. `udisksctl monitor` tells when
// one is plugged in or removed; a notification says so.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // [{ device, name, size, mountpoint, label }] partitions you can mount
  property var drives: []
  property bool started: false

  function refresh(): void {
    list.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: list
    command: ["lsblk", "-J", "-b", "-o", "PATH,NAME,LABEL,SIZE,TYPE,MOUNTPOINT,HOTPLUG,RM,TRAN,MODEL,VENDOR,FSTYPE"]
    stdout: StdioCollector {
      onStreamFinished: {
        let data = [];
        try {
          data = JSON.parse(text).blockdevices ?? [];
        } catch (e) {
          return;
        }
        const out = [];
        for (const disk of data) {
          const removable = disk.hotplug === true || disk.rm === true || disk.tran === "usb";
          if (!removable || disk.type !== "disk") continue;
          const model = [disk.vendor, disk.model].filter(s => s && s.trim() !== "").map(s => s.trim()).join(" ");
          const parts = (disk.children ?? []).filter(p => p.fstype);
          // A stick without a partition table is a filesystem itself
          for (const p of parts.length > 0 ? parts : (disk.fstype ? [disk] : [])) {
            out.push({
              device: p.path,
              name: p.label || model || p.name,
              model,
              size: root.bytes(p.size),
              mountpoint: p.mountpoint ?? ""
            });
          }
        }
        const before = root.drives.map(d => d.device);
        if (root.started) {
          for (const d of out) {
            if (before.indexOf(d.device) < 0) Quickshell.execDetached(["notify-send", "-a", "Drives", "-i", "drive-removable-media", d.name + " connected", d.size + " · open it from the bar"]);
          }
        }
        root.drives = out;
        root.started = true;
      }
    }
  }

  // Plugged in or removed: look again
  Process {
    running: true
    command: ["udisksctl", "monitor"]
    stdout: SplitParser {
      onRead: data => {
        if (/Added|Removed|Changed/.test(data)) refreshDelay.restart();
      }
    }
  }

  Timer {
    id: refreshDelay
    interval: 700
    onTriggered: root.refresh()
  }

  function bytes(n: real): string {
    if (n >= 1e12) return (n / 1e12).toFixed(1) + " TB";
    if (n >= 1e9) return Math.round(n / 1e9) + " GB";
    return Math.round(n / 1e6) + " MB";
  }

  // Mounts (when needed) and opens it in the file manager
  function open(drive: var): void {
    Quickshell.execDetached(["sh", "-c",
      "m=$(lsblk -no MOUNTPOINT \"$1\" | head -1); [ -n \"$m\" ] || m=$(udisksctl mount -b \"$1\" | sed -n 's/.* at \\(.*\\)$/\\1/p'); [ -n \"$m\" ] && xdg-open \"$m\"",
      "sh", drive.device]);
    refreshDelay.restart();
  }

  function mount(drive: var): void {
    Quickshell.execDetached(["udisksctl", "mount", "-b", drive.device]);
    refreshDelay.restart();
  }

  // Unmounts and powers it off, then tells you it's safe
  function eject(drive: var): void {
    Quickshell.execDetached(["sh", "-c",
      "udisksctl unmount -b \"$1\" >/dev/null 2>&1; disk=/dev/$(lsblk -no PKNAME \"$1\" | head -1); [ \"$disk\" = /dev/ ] && disk=\"$1\";" +
      "if udisksctl power-off -b \"$disk\" 2>/dev/null; then notify-send -a Drives \"Safe to remove\" \"$2\"; else notify-send -a Drives \"Couldn't eject $2\" \"Close the files that are open on it and try again\"; fi",
      "sh", drive.device, drive.name]);
    refreshDelay.restart();
  }
}
