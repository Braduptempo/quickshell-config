// Clipboard.qml
// Clipboard history on top of cliphist. Items are plain objects:
//   { id, line, preview, kind, size?, added, pinned }
// kind: "text", "code", "link", "color" or "image".
//
// The shell starts the cliphist watchers itself (once, they outlive reloads),
// so nothing has to go in the Hyprland autostart. Passwords that password
// managers mark as sensitive are never stored (cliphist skips them).
// Pins and "copied at" times live in the shell's state folder; pins match on
// the preview text, because cliphist gives an item a new id when it is
// copied again.
//
// For testing: QS_CLIPHIST_DB=/some/test.db uses another database and starts
// no watchers.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null

  property bool available: false
  property var items: []
  // Bumped after every refresh
  property int revision: 0

  readonly property string testDb: Quickshell.env("QS_CLIPHIST_DB") ?? ""
  readonly property var cliphist: testDb !== "" ? ["cliphist", "-db-path", testDb] : ["cliphist"]
  // The same, quoted for `sh -c`
  readonly property string cliphistCmd: cliphist.map(a => "'" + a.replace(/'/g, "'\\''") + "'").join(" ")
  readonly property string tempDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-clipboard"

  // A click on the bar button closes it via the focus grab first; don't reopen
  property double closedAt: 0
  onOpenChanged: if (!open) closedAt = Date.now()

  function toggle(onScreen: ShellScreen): void {
    if (open) {
      open = false;
    } else if (Date.now() - closedAt > 250) {
      screen = onScreen;
      refresh();
      open = true;
    }
  }

  // --- Watchers -------------------------------------------------------------------
  Process {
    command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-paste >/dev/null && echo yes"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        root.available = text.trim() === "yes";
        if (!root.available) return;
        if (root.testDb === "") {
          // Started detached and only once, so a shell reload doesn't lose or double them
          Quickshell.execDetached(["sh", "-c",
            "pgrep -f 'wl-paste --type text --watch cliphist' >/dev/null || setsid -f wl-paste --type text --watch cliphist store;" +
            "pgrep -f 'wl-paste --type image --watch cliphist' >/dev/null || setsid -f wl-paste --type image --watch cliphist store"]);
        }
        changes.running = true;
        root.refresh();
      }
    }
  }

  // Prints a line whenever the clipboard changes; cliphist stores it a moment later
  Process {
    id: changes
    command: ["wl-paste", "--watch", "echo", "changed"]
    stdout: SplitParser {
      onRead: refreshDelay.restart()
    }
  }

  Timer {
    id: refreshDelay
    interval: 300
    onTriggered: root.refresh()
  }

  // --- Stored state ---------------------------------------------------------------
  FileView {
    path: Quickshell.statePath("clipboard.json")
    watchChanges: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: state
      // preview texts of pinned items
      property var pins: []
      // cliphist id -> first time the shell saw it (ms)
      property var seen: ({})
    }
  }

  property alias pins: state.pins
  property alias seen: state.seen

  // --- Reading the history -----------------------------------------------------------
  function refresh(): void {
    if (!available) return;
    if (listProc.running) refreshDelay.restart();
    else listProc.running = true;
  }

  Process {
    id: listProc
    command: root.cliphist.concat(["list"])
    stdout: StdioCollector {
      onStreamFinished: root.parse(text)
    }
  }

  function kindOf(preview: string): var {
    const image = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+)x(\d+) \]\]$/);
    if (image) return { kind: "image", size: image[3] + " × " + image[4], format: image[2], bytes: image[1] };
    if (/^\[\[ binary data/.test(preview)) return { kind: "image", size: "", format: "", bytes: "" };
    if (/^(#[0-9a-f]{3}|#[0-9a-f]{6}|#[0-9a-f]{8}|rgba?\([\d\s,.%]+\)|hsla?\([\d\s,.%deg]+\))$/i.test(preview)) return { kind: "color" };
    if (/^(https?|ftp|file):\/\/\S+$/i.test(preview)) return { kind: "link" };
    if (/^\s*(import|export|const|let|var|function|def|class|#include|package|fn|pub|return|if|for)\b|[{};]\s*$|=>|::|\)\s*\{/.test(preview)) return { kind: "code" };
    return { kind: "text" };
  }

  function parse(text: string): void {
    const now = Date.now();
    const seen = {};
    const list = [];
    for (const line of text.split("\n")) {
      const tab = line.indexOf("\t");
      if (tab < 1) continue;
      const id = line.slice(0, tab);
      const preview = line.slice(tab + 1);
      seen[id] = root.seen[id] ?? now;
      list.push(Object.assign({ id, line, preview, added: seen[id], pinned: root.pins.indexOf(preview) >= 0 }, kindOf(preview)));
    }
    // Forget pins whose item is gone, unless the list is empty (cliphist not ready)
    if (list.length > 0) {
      const previews = list.map(i => i.preview);
      const pins = root.pins.filter(p => previews.indexOf(p) >= 0);
      if (pins.length !== root.pins.length) root.pins = pins;
    }
    if (JSON.stringify(seen) !== JSON.stringify(root.seen)) root.seen = seen;
    items = list;
    revision++;
  }

  // "now", "4 min", "3 h", "2 days"
  function age(ms: real): string {
    const min = Math.floor((Date.now() - ms) / 60000);
    if (min < 1) return "now";
    if (min < 60) return min + " min";
    const h = Math.floor(min / 60);
    if (h < 24) return h + " h";
    const days = Math.floor(h / 24);
    return days + (days === 1 ? " day" : " days");
  }

  function kindLabel(kind: string): string {
    return { text: "Text", code: "Code", link: "Link", color: "Color", image: "Image" }[kind] ?? "Text";
  }

  // "PNG image"
  function imageTitle(item: var): string {
    return (item.format !== "" ? item.format.toUpperCase() + " image" : "Image");
  }

  function meta(item: var): string {
    const parts = [kindLabel(item.kind)];
    if (item.kind === "image" && item.size !== "") parts.push(item.size);
    parts.push(age(item.added));
    return parts.join(" · ");
  }

  // Search text and a filter: "all", "text" (text + code), "image", "link", "color"
  function matches(item: var, filter: string, q: string): bool {
    if (filter === "text" && item.kind !== "text" && item.kind !== "code") return false;
    if (filter !== "all" && filter !== "text" && item.kind !== filter) return false;
    return q === "" || item.preview.toLowerCase().includes(q.toLowerCase());
  }

  // Pinned first, then newest first (cliphist's own order)
  function filtered(filter: string, q: string): var {
    const list = items.filter(i => matches(i, filter, q));
    return list.filter(i => i.pinned).concat(list.filter(i => !i.pinned));
  }

  function count(filter: string): int {
    return items.filter(i => matches(i, filter, "")).length;
  }

  // --- Actions ----------------------------------------------------------------------
  // `decode` feeds the item to a shell snippet as stdin
  function withItem(id: string, script: string, extra: var): void {
    const decode = root.cliphistCmd + " decode \"$1\"";
    Quickshell.execDetached(["sh", "-c", script.replace(/DECODE/g, decode), "sh", id].concat(extra ?? []));
  }

  function copy(item: var): void {
    withItem(item.id, "DECODE | wl-copy", []);
  }

  // Into the window that had focus, after this one has closed. Text is typed
  // (works in terminals too); images are pasted with Ctrl + V.
  function paste(item: var): void {
    if (!LauncherTools.hasWtype) {
      copy(item);
      return;
    }
    if (item.kind === "image") withItem(item.id, "DECODE | wl-copy; sleep 0.3; wtype -M ctrl -k v -m ctrl", []);
    else withItem(item.id, "DECODE | wl-copy; sleep 0.3; DECODE | wtype -", []);
  }

  function togglePin(item: var): void {
    root.pins = item.pinned ? root.pins.filter(p => p !== item.preview) : root.pins.concat([item.preview]);
    parseAgain();
  }

  function remove(item: var): void {
    if (item.pinned) root.pins = root.pins.filter(p => p !== item.preview);
    items = items.filter(i => i.id !== item.id);
    revision++;
    withItem(item.id, "echo \"$1\" | " + root.cliphistCmd + " delete", []);
  }

  // Everything except pinned items
  function clearUnpinned(): void {
    const ids = items.filter(i => !i.pinned).map(i => i.id);
    if (ids.length === 0) return;
    items = items.filter(i => i.pinned);
    revision++;
    Quickshell.execDetached(["sh", "-c", "printf '%s\\n' \"$@\" | " + root.cliphistCmd + " delete", "sh"].concat(ids));
  }

  function saveImage(item: var): void {
    const name = "Clipboard-" + Qt.formatDateTime(new Date(), "yyyy-MM-dd-HHmmss") + "." + (item.format || "png");
    const dir = Quickshell.env("HOME") + "/Pictures";
    withItem(item.id, "mkdir -p \"$2\" && DECODE > \"$2/$3\" && notify-send -a Clipboard 'Image saved' \"$3 in Pictures\"", [dir, name]);
  }

  // Pins changed: recompute `pinned` without asking cliphist again
  function parseAgain(): void {
    items = items.map(i => Object.assign({}, i, { pinned: root.pins.indexOf(i.preview) >= 0 }));
    revision++;
  }

  // --- Preview of one item ---------------------------------------------------------------
  // Full text of a text item, or the file path of an image
  property string previewId: ""
  property string previewText: ""
  property string previewImage: ""

  function loadPreview(item: var): void {
    if (!item) {
      previewId = "";
      return;
    }
    if (item.id === previewId) return;
    previewId = item.id;
    previewText = "";
    previewImage = "";
    previewProc.running = false;
    if (item.kind === "image") {
      const file = tempDir + "/" + item.id + "." + (item.format || "png");
      previewProc.target = file;
      previewProc.command = ["sh", "-c", "mkdir -p \"$2\"; [ -s \"$3\" ] || " + root.cliphistCmd + " decode \"$1\" > \"$3\"; echo done", "sh", item.id, tempDir, file];
    } else {
      previewProc.target = "";
      previewProc.command = ["sh", "-c", root.cliphistCmd + " decode \"$1\" | head -c 6000", "sh", item.id];
    }
    previewProc.forId = item.id;
    previewProc.running = true;
  }

  Process {
    id: previewProc
    property string target: ""
    property string forId: ""
    stdout: StdioCollector {
      onStreamFinished: {
        if (previewProc.forId !== root.previewId) return;
        if (previewProc.target !== "") root.previewImage = "file://" + previewProc.target;
        else root.previewText = text;
      }
    }
  }
}
