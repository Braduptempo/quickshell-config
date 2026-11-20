// LauncherTools.qml
// The launcher modes that need an extra program. Each one only shows up
// when its program is installed:
//   qalc        calculator with units, percentages and currency
//   fd          file search ("/report" or "f report")
//   wtype       typing emoji (":laugh") and snippets (";qml") into the window
//   hyprpicker  colour picker ("color")
// Answers arrive asynchronously; `updated` tells the launcher to search again.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  signal updated()

  property bool hasQalc: false
  property bool hasFd: false
  property bool hasWtype: false
  property bool hasPicker: false

  Process {
    command: ["sh", "-c", "for t in qalc fd wtype hyprpicker; do command -v \"$t\" >/dev/null && echo \"$t\"; done"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const tools = text.split("\n");
        root.hasQalc = tools.includes("qalc");
        root.hasFd = tools.includes("fd");
        root.hasWtype = tools.includes("wtype");
        root.hasPicker = tools.includes("hyprpicker");
      }
    }
  }

  // Types text into the window that had focus, once the launcher is gone.
  // Without wtype it is only copied.
  function typeText(text: string): void {
    if (hasWtype) Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy; sleep 0.25; wtype -- \"$1\"", "sh", text]);
    else Quickshell.execDetached(["wl-copy", text]);
  }

  // --- Calculator (qalc) --------------------------------------------------------
  property string calcQuery: ""
  property string calcAnswer: ""
  property string answeredQuery: ""

  // qalc reads "in" as inches and gives mixed units ("3 mi + 188 yd"):
  // "5 km in miles" -> "5 km to -miles", "20% of 85" -> "20% * 85"
  function qalcExpression(text: string): string {
    let expr = text.trim();
    expr = expr.replace(/(\d+(?:[.,]\d+)?)\s*%\s+of\s+/i, "$1% * ");
    expr = expr.replace(/\s+(?:in|to)\s+-?(\S.*)$/i, " to -$1");
    return expr;
  }

  // Returns the answer when it is ready, otherwise "" and asks qalc
  function calc(text: string): string {
    const q = text.trim();
    if (!hasQalc || q.length < 2 || !/\d/.test(q)) return "";
    if (q === answeredQuery) return calcAnswer;
    if (q !== calcQuery) {
      calcQuery = q;
      calcTimer.restart();
    }
    return "";
  }

  Timer {
    id: calcTimer
    interval: 120
    onTriggered: {
      if (qalcProc.running) return;
      qalcProc.query = root.calcQuery;
      qalcProc.command = ["qalc", "-t", root.qalcExpression(root.calcQuery)];
      qalcProc.running = true;
    }
  }

  Process {
    id: qalcProc
    property string query: ""
    stdout: StdioCollector {
      onStreamFinished: {
        const answer = (text.trim().split("\n")[0] ?? "").trim();
        const input = qalcProc.query.replace(/\s+/g, "");
        // qalc also answers plain words ("firefox" -> "0 B"); only keep real answers
        const useful = answer !== "" && answer.replace(/\s+/g, "") !== input && !/error|warning|^0 B$/i.test(answer);
        root.answeredQuery = qalcProc.query;
        root.calcAnswer = useful ? answer : "";
        root.updated();
      }
    }
    // Typed on while qalc was busy: run again for the newest text
    onExited: if (root.calcQuery !== query) calcTimer.restart()
  }

  // --- Files (fd) -------------------------------------------------------------------
  property string fileQuery: ""
  property var files: []

  function findFiles(text: string): var {
    const q = text.trim();
    if (!hasFd || q.length < 2) return [];
    if (q !== fileQuery) {
      fileQuery = q;
      files = [];
      fileTimer.restart();
    }
    return files;
  }

  Timer {
    id: fileTimer
    interval: 200
    onTriggered: {
      if (fdProc.running) return;
      fdProc.query = root.fileQuery;
      fdProc.command = ["fd", "--ignore-case", "--max-results", "40", "--exclude", ".git", "--exclude", "node_modules", "--", root.fileQuery, Quickshell.env("HOME")];
      fdProc.running = true;
    }
  }

  Process {
    id: fdProc
    property string query: ""
    stdout: StdioCollector {
      onStreamFinished: {
        const home = Quickshell.env("HOME");
        // Shortest paths first: those are usually what you mean
        root.files = text.split("\n").filter(p => p !== "").sort((a, b) => a.length - b.length).slice(0, 12).map(path => {
          const clean = path.replace(/\/$/, "");
          const parts = clean.split("/");
          return { path: clean, name: parts.pop(), folder: parts.join("/").replace(home, "~"), isDir: path.endsWith("/") };
        });
        root.updated();
      }
    }
    onExited: if (root.fileQuery !== query) fileTimer.restart()
  }

  // --- Emoji -------------------------------------------------------------------------
  property var emoji: []

  FileView {
    path: Quickshell.shellPath("data/emoji.json")
    onLoaded: {
      try {
        root.emoji = JSON.parse(text());
      } catch (e) {
        root.emoji = [];
      }
    }
  }

  function findEmoji(text: string): var {
    const words = text.trim().toLowerCase().split(/\s+/).filter(w => w !== "");
    const matches = words.length === 0 ? emoji.slice(0, 40)
                  : emoji.filter(e => words.every(w => e[1].includes(w)));
    // Names that start with the word first ("smile" before "cat with wry smile")
    const first = words[0] ?? "";
    return matches.sort((a, b) => (b[1].startsWith(first) ? 1 : 0) - (a[1].startsWith(first) ? 1 : 0)).slice(0, 30);
  }

  // --- Colours (hyprpicker) -----------------------------------------------------------
  FileView {
    path: Quickshell.statePath("colors.json")
    watchChanges: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: colorState
      // Newest first, at most 8
      property var recent: []
    }
  }

  property alias recentColors: colorState.recent

  function pickColor(): void {
    if (!hasPicker || pickProc.running) return;
    pickProc.running = true;
  }

  Process {
    id: pickProc
    // Starts after the launcher has closed, so you can click anywhere
    command: ["sh", "-c", "sleep 0.3; hyprpicker -f hex"]
    stdout: StdioCollector {
      onStreamFinished: {
        const hex = text.trim().toUpperCase();
        if (!/^#[0-9A-F]{6}$/.test(hex)) return;
        colorState.recent = [hex].concat(colorState.recent.filter(c => c !== hex)).slice(0, 8);
        Quickshell.execDetached(["wl-copy", hex]);
        Quickshell.execDetached(["notify-send", "-a", "Color picker", "Copied " + hex, "RGB " + root.rgb(hex)]);
        root.updated();
      }
    }
  }

  function rgb(hex: string): string {
    const n = parseInt(hex.slice(1), 16);
    return ((n >> 16) & 255) + ", " + ((n >> 8) & 255) + ", " + (n & 255);
  }

  // --- Snippets (snippets/*.txt) -------------------------------------------------------
  readonly property string snippetsDir: Quickshell.shellPath("snippets")
  property var snippets: []

  function refreshSnippets(): void {
    snippetProc.running = true;
  }

  Process {
    id: snippetProc
    command: ["find", root.snippetsDir, "-maxdepth", "1", "-type", "f", "-name", "*.txt"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        root.snippets = text.split("\n").filter(p => p !== "").sort().map(path => ({ path, name: path.split("/").pop().replace(/\.txt$/, "") }));
        root.updated();
      }
    }
  }

  function typeFile(path: string): void {
    if (hasWtype) Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"; sleep 0.25; wtype - < \"$1\"", "sh", path]);
    else Quickshell.execDetached(["sh", "-c", "wl-copy < \"$1\"", "sh", path]);
  }
}
