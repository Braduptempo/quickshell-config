// DefaultApps.qml
// Which app opens web links, folders, text, images, video, music, mail and
// PDFs, for Settings → Default apps. Read and written with xdg-mime, so every
// app follows the same choice (saved in ~/.config/mimeapps.list). The terminal
// has no such standard; the shell keeps its own (Config.apps.terminal).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"

Singleton {
  id: root

  readonly property var kinds: [
    { key: "web", label: "Web browser", icon: "search", mimes: ["x-scheme-handler/https", "x-scheme-handler/http", "text/html"] },
    { key: "files", label: "File manager", icon: "folder", mimes: ["inode/directory"] },
    { key: "text", label: "Text editor", icon: "text", mimes: ["text/plain"] },
    { key: "images", label: "Images", icon: "image", mimes: ["image/png", "image/jpeg", "image/webp", "image/gif"] },
    { key: "video", label: "Video", icon: "camera", mimes: ["video/mp4", "video/x-matroska", "video/webm"] },
    { key: "music", label: "Music", icon: "music", mimes: ["audio/mpeg", "audio/flac", "audio/ogg"] },
    { key: "mail", label: "Email", icon: "bell", mimes: ["x-scheme-handler/mailto"] },
    { key: "pdf", label: "PDF", icon: "file", mimes: ["application/pdf"] }
  ]

  // kind -> desktop file id ("zen.desktop")
  property var current: ({})
  // kind -> [desktop file ids that can open it]
  property var options: ({})

  function refresh(): void {
    scan.running = true;
  }

  Component.onCompleted: refresh()

  // Every app's MimeType line, then the current default per kind
  Process {
    id: scan
    command: ["sh", "-c",
      "for d in \"$HOME/.local/share/applications\" /usr/share/applications /var/lib/flatpak/exports/share/applications; do" +
      "  [ -d \"$d\" ] || continue; for f in \"$d\"/*.desktop; do" +
      "    grep -q '^NoDisplay=true' \"$f\" && continue;" +
      "    m=$(grep -m1 '^MimeType=' \"$f\" | cut -d= -f2); [ -n \"$m\" ] && echo \"app|$(basename \"$f\")|$m\"; done; done;" +
      "shift; for k in \"$@\"; do echo \"default|${k%%=*}|$(xdg-mime query default \"${k#*=}\" 2>/dev/null)\"; done",
      "sh", "x"].concat(root.kinds.map(k => k.key + "=" + k.mimes[0]))
    stdout: StdioCollector {
      onStreamFinished: {
        const options = {};
        const current = {};
        for (const k of root.kinds) options[k.key] = [];
        for (const line of text.split("\n")) {
          const [type, a, b] = line.split("|");
          if (type === "app") {
            const mimes = (b ?? "").split(";");
            for (const k of root.kinds) {
              if (k.mimes.some(m => mimes.indexOf(m) >= 0) && options[k.key].indexOf(a) < 0) options[k.key].push(a);
            }
          } else if (type === "default") {
            current[a] = (b ?? "").trim();
          }
        }
        root.options = options;
        root.current = current;
      }
    }
  }

  function set(kind: string, desktopId: string): void {
    const k = kinds.find(x => x.key === kind);
    if (!k || desktopId === "") return;
    Quickshell.execDetached(["xdg-mime", "default", desktopId].concat(k.mimes));
    const map = Object.assign({}, current);
    map[kind] = desktopId;
    current = map;
  }

  // "zen.desktop" -> "Zen Browser"
  function nameOf(desktopId: string): string {
    if (desktopId === "") return "Nothing set";
    const id = desktopId.replace(/\.desktop$/, "");
    const entry = DesktopEntries.applications.values.find(a => a.id === id);
    return entry ? entry.name : id;
  }

  // --- Terminal ------------------------------------------------------------------------
  // Installed terminals: their command, e.g. "kitty"
  readonly property var terminals: {
    const list = DesktopEntries.applications.values
      .filter(a => (a.categories ?? []).indexOf("TerminalEmulator") >= 0 && (a.command ?? []).length > 0)
      .map(a => ({ name: a.name, command: a.command[0].split("/").pop() }));
    return list.filter((t, i) => list.findIndex(o => o.command === t.command) === i);
  }

  // Runs a command line in the chosen terminal: `terminal -e sh -c "…"`
  function inTerminal(script: string, args: var): void {
    Quickshell.execDetached([Config.apps.terminal, "-e", "sh", "-c", script, "sh"].concat(args ?? []));
  }
}
