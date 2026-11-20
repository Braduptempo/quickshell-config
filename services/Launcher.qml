// Launcher.qml
// Search for the launcher: apps (ranked by match and how often you open
// them), a calculator, shell commands (start with ">") and a web search
// as last resort. Launch counts live in the shell's state folder.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  // Text to start with when opening (IPC `launcher search …`)
  property string initialQuery: ""

  function toggle(onScreen: ShellScreen): void {
    if (open) {
      open = false;
    } else {
      initialQuery = "";
      screen = onScreen;
      open = true;
    }
  }

  function openWith(onScreen: ShellScreen, query: string): void {
    initialQuery = query;
    screen = onScreen;
    open = true;
  }

  // --- Launch counts ("frecency light") -------------------------------------
  FileView {
    id: stateFile
    path: Quickshell.statePath("launcher.json")
    watchChanges: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: state
      // app id -> { count, last }
      property var launches: ({})
    }
  }

  function boostFor(id: string): real {
    const entry = state.launches[id];
    if (!entry) return 0;
    const days = (Date.now() - entry.last) / 86400000;
    // Often and recently used apps rise; old habits fade over a few weeks
    return Math.min(entry.count, 30) * Math.exp(-days / 21);
  }

  function remember(id: string): void {
    const launches = Object.assign({}, state.launches);
    const entry = launches[id] ?? { count: 0, last: 0 };
    launches[id] = { count: entry.count + 1, last: Date.now() };
    state.launches = launches;
  }

  // --- Apps ---------------------------------------------------------------------
  readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)

  function scoreApp(app: DesktopEntry, q: string): real {
    const name = app.name.toLowerCase();
    let score = 0;
    if (name === q) score = 100;
    else if (name.startsWith(q)) score = 80;
    else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) score = 65;
    else if (name.includes(q)) score = 50;
    else if ((app.genericName ?? "").toLowerCase().includes(q)) score = 35;
    else if ((app.keywords ?? []).some(k => k.toLowerCase().startsWith(q))) score = 30;
    else if (fuzzy(name, q)) score = 20;
    else if ((app.comment ?? "").toLowerCase().includes(q)) score = 10;
    if (score === 0) return 0;
    return score + boostFor(app.id);
  }

  // First letters of the words, e.g. "vsc" matches "Visual Studio Code"
  function fuzzy(text: string, q: string): bool {
    const initials = text.split(/[\s\-_.]+/).filter(w => w !== "").map(w => w[0]).join("");
    return q.length >= 2 && initials.startsWith(q);
  }

  // --- Calculator -------------------------------------------------------------
  // Only digits, operators and a few math words reach the evaluator, so
  // nothing else can run
  function calculate(text: string): string {
    let expr = text.trim().toLowerCase().replace(/,/g, ".").replace(/×/g, "*").replace(/÷/g, "/");
    if (!/[0-9]/.test(expr) || !/[+\-*/^%()]|sqrt|sin|cos|tan|log|ln|pi/.test(expr)) return "";
    if (!/^[0-9+\-*/^%().\s]*(?:(?:sqrt|sin|cos|tan|log|ln|abs|round|pi|e)[0-9+\-*/^%().\s]*)*$/.test(expr)) return "";
    expr = expr.replace(/\^/g, "**")
      .replace(/\bsqrt\b/g, "Math.sqrt").replace(/\bsin\b/g, "Math.sin").replace(/\bcos\b/g, "Math.cos")
      .replace(/\btan\b/g, "Math.tan").replace(/\blog\b/g, "Math.log10").replace(/\bln\b/g, "Math.log")
      .replace(/\babs\b/g, "Math.abs").replace(/\bround\b/g, "Math.round")
      .replace(/\bpi\b/g, "Math.PI").replace(/\be\b/g, "Math.E");
    try {
      const value = Function('"use strict"; return (' + expr + ");")();
      if (typeof value !== "number" || !isFinite(value)) return "";
      return String(Math.round(value * 1e10) / 1e10);
    } catch (e) {
      return "";
    }
  }

  // --- Results -------------------------------------------------------------------
  // Each result: { kind, title, subtitle, icon, app?, value? }
  function search(text: string): var {
    const q = text.trim().toLowerCase();
    const results = [];

    if (q.startsWith(">")) {
      const cmd = text.trim().slice(1).trim();
      if (cmd !== "") results.push({ kind: "command", title: cmd, subtitle: "Run in a shell", icon: "arrow-right", value: cmd });
      return results;
    }

    const calc = calculate(text);
    if (calc !== "") results.push({ kind: "calc", title: calc, subtitle: text.trim() + " =", icon: "plus", value: calc });

    if (q === "") {
      // Nothing typed: your most used apps first, then A–Z
      const sorted = apps.slice().sort((a, b) => boostFor(b.id) - boostFor(a.id) || a.name.localeCompare(b.name));
      for (const app of sorted.slice(0, 8)) results.push(appResult(app));
      return results;
    }

    const scored = [];
    for (const app of apps) {
      const s = scoreApp(app, q);
      if (s > 0) scored.push({ app, s });
    }
    scored.sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name));
    for (const item of scored.slice(0, 8)) results.push(appResult(item.app));

    if (results.length === 0 || q.length > 2) {
      results.push({ kind: "web", title: "Search the web for \"" + text.trim() + "\"", subtitle: "Opens your browser", icon: "search", value: text.trim() });
    }
    return results;
  }

  function appResult(app: DesktopEntry): var {
    return { kind: "app", title: app.name, subtitle: app.genericName || app.comment || "", icon: app.icon, app };
  }

  function activate(result: var): void {
    if (!result) return;
    switch (result.kind) {
    case "app":
      remember(result.app.id);
      result.app.execute();
      break;
    case "calc":
      Quickshell.execDetached(["wl-copy", result.value]);
      break;
    case "command":
      Quickshell.execDetached(["sh", "-c", result.value]);
      break;
    case "web":
      Qt.openUrlExternally("https://duckduckgo.com/?q=" + encodeURIComponent(result.value));
      break;
    }
    open = false;
  }
}
