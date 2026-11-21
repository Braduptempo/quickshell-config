// Launcher.qml
// Everything the launcher can find. Each result is a plain object:
//   { key, section, title, subtitle, icon, appIcon?, hint, confirm?, run() }
// and apps also carry `app` so the Ctrl + K menu can act on them.
//
// What you can type:
//   (nothing)         favorites and your most used apps
//   an app name       apps, plus matching system commands and scripts
//   a sum             the calculator; Enter copies the answer
//   yt lofi           quicklinks: a keyword, then what to search for
//   > command         runs in a shell
//   window …          act on the window that had focus
//   kill firefox      stop a process (Ctrl + Enter: force)
//   no match          search the web, ArchWiki or the AUR, or run it
// With extra programs (services/LauncherTools.qml):
//   5 km in miles     calculator with units and currency (qalc)
//   /report, f report file search (fd)
//   :laugh            emoji, typed into the window (wtype)
//   ;qml              snippets from snippets/*.txt
//   color             pick a colour from the screen (hyprpicker)
//   clip ssh          clipboard history, pasted into the window (cliphist)
//
// Launch counts, favorites and hidden apps live in the shell's state folder.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Hyprland
import "../config"

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  // Text to start with when opening (IPC `launcher search …`)
  property string initialQuery: ""
  // Bumped when async data (processes, scripts) arrives, so the window re-runs search
  property int revision: 0

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

  onOpenChanged: {
    if (open) {
      scriptsProc.running = true;
      LauncherTools.refreshSnippets();
    }
  }

  Connections {
    target: LauncherTools
    function onUpdated() { root.revision++; }
  }

  Connections {
    target: Clipboard
    function onRevisionChanged() { if (root.open) root.revision++; }
  }

  // --- Stored state ---------------------------------------------------------------
  FileView {
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
      // app ids, in the order you pinned them
      property var favorites: []
      // app ids you don't want to see
      property var hidden: []
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

  function isFavorite(id: string): bool {
    return state.favorites.indexOf(id) >= 0;
  }

  function toggleFavorite(id: string): void {
    state.favorites = isFavorite(id) ? state.favorites.filter(f => f !== id) : state.favorites.concat([id]);
    revision++;
  }

  function hide(id: string): void {
    state.hidden = state.hidden.concat([id]);
    state.favorites = state.favorites.filter(f => f !== id);
    revision++;
  }

  // --- Apps ---------------------------------------------------------------------
  readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay && state.hidden.indexOf(a.id) < 0)

  function scoreText(name: string, q: string): real {
    if (name === q) return 100;
    if (name.startsWith(q)) return 80;
    if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 65;
    if (name.includes(q)) return 50;
    if (initials(name, q)) return 20;
    return 0;
  }

  function scoreApp(app: DesktopEntry, q: string): real {
    let score = scoreText(app.name.toLowerCase(), q);
    if (score === 0 && (app.genericName ?? "").toLowerCase().includes(q)) score = 35;
    if (score === 0 && (app.keywords ?? []).some(k => k.toLowerCase().startsWith(q))) score = 30;
    if (score === 0 && (app.comment ?? "").toLowerCase().includes(q)) score = 10;
    return score === 0 ? 0 : score + boostFor(app.id);
  }

  // First letters of the words, e.g. "vsc" matches "Visual Studio Code"
  function initials(text: string, q: string): bool {
    const letters = text.split(/[\s\-_.]+/).filter(w => w !== "").map(w => w[0]).join("");
    return q.length >= 2 && letters.startsWith(q);
  }

  function appResult(app: DesktopEntry, section: string): var {
    return {
      key: "app:" + app.id, section, app,
      title: app.name, subtitle: app.genericName || app.comment || "",
      appIcon: app.icon, icon: "image", hint: "Application",
      run: () => { remember(app.id); app.execute(); }
    };
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

  // --- Quicklinks: keyword + search terms ---------------------------------------
  readonly property var quicklinks: [
    { keyword: "yt", name: "YouTube", url: "https://www.youtube.com/results?search_query=%s" },
    { keyword: "g", name: "Google", url: "https://www.google.com/search?q=%s" },
    { keyword: "ddg", name: "DuckDuckGo", url: "https://duckduckgo.com/?q=%s" },
    { keyword: "gh", name: "GitHub", url: "https://github.com/search?q=%s" },
    { keyword: "aw", name: "ArchWiki", url: "https://wiki.archlinux.org/index.php?search=%s" },
    { keyword: "aur", name: "AUR", url: "https://aur.archlinux.org/packages?K=%s" },
    { keyword: "pkg", name: "Arch packages", url: "https://archlinux.org/packages/?q=%s" },
    { keyword: "w", name: "Wikipedia", url: "https://en.wikipedia.org/w/index.php?search=%s" },
    { keyword: "qs", name: "Quickshell docs", url: "https://quickshell.org/docs/search/?q=%s" }
  ]

  function openUrl(template: string, terms: string): void {
    Qt.openUrlExternally(template.replace("%s", encodeURIComponent(terms)));
  }

  // --- System commands ------------------------------------------------------------
  readonly property var systemCommands: {
    const list = [];
    const add = (title, subtitle, icon, run, confirm, words) => list.push({ key: "sys:" + title, section: "Commands", title, subtitle, icon, hint: "Command", run, confirm: confirm ?? "", words: words ?? [] });
    const wifi = Networking.wifiEnabled;
    add(wifi ? "Turn Wi-Fi off" : "Turn Wi-Fi on", "Network", wifi ? "wifi-off" : "wifi", () => Networking.wifiEnabled = !wifi, "", ["wifi", "wlan", "wireless", "network"]);
    const adapter = Bluetooth.defaultAdapter;
    if (adapter) add(adapter.enabled ? "Turn Bluetooth off" : "Turn Bluetooth on", "Bluetooth", "bluetooth", () => adapter.enabled = !adapter.enabled, "", ["bt", "bluetooth"]);
    add(Notifications.dnd ? "Turn Do not disturb off" : "Turn Do not disturb on", "Notifications", "moon", () => Notifications.dnd = !Notifications.dnd, "", ["dnd", "focus", "quiet", "silent"]);
    add("Clear notifications", "Notifications", "bell", () => Notifications.clearAll(), "", ["dismiss"]);
    add(Session.caffeine ? "Turn caffeine off" : "Turn caffeine on", "Keep the screen awake", "activity", () => Session.caffeine = !Session.caffeine, "", ["awake", "idle", "sleep"]);
    if (Session.nightLightAvailable) add(Session.nightLight ? "Turn night light off" : "Turn night light on", "Display", "sun", () => Session.nightLight = !Session.nightLight, "", ["redshift", "warm", "blue light"]);
    if (LauncherTools.hasPicker) add("Pick a color", "From the screen, copies the hex code", "palette", () => LauncherTools.pickColor(), "", ["color", "colour", "hex", "picker", "hyprpicker"]);
    if (Clipboard.available) add("Clipboard history", "Super + Shift + V", "clipboard", () => Clipboard.toggle(null), "", ["clipboard", "paste", "copied", "cliphist"]);
    add("Workspace overview", "Super + Tab · all windows, drag them between workspaces", "region", () => Windows.toggleOverview(null), "", ["overview", "workspaces", "windows", "expose", "mission control"]);
    add("Settings", "Super + ,", "settings", () => Panels.openSettings(null, ""), "", ["settings", "preferences", "config", "options"]);
    add("Change theme", "Super + T · " + Config.appearance.theme, "palette", () => Panels.toggleThemePicker(null), "", ["theme", "colors", "colours", "dark", "light"]);
    add("Change wallpaper", "Super + W", "image", () => Wallpapers.toggle(null), "", ["wallpaper", "background"]);
    if (Wallpapers.items.length > 1) add("Random wallpaper", "From ~/Pictures/wallpapers", "shuffle", () => Wallpapers.set(Wallpapers.random()), "", ["random", "wallpaper", "shuffle"]);
    add("System monitor", "CPU, GPU, memory, disk, network, processes", "activity", () => Panels.openQuickSettings(null, "system"), "", ["system", "monitor", "cpu", "ram", "memory", "gpu", "task manager", "htop", "temperature"]);
    add("Quick settings", "Open the panel", "settings", () => Panels.openQuickSettings(null, "main"), "", ["qs", "settings", "volume"]);
    add("Notifications", "Open the history", "bell", () => Panels.openClockPanel(null, "notifications"));
    add("Calendar", "Open the month view", "calendar", () => Panels.openClockPanel(null, "calendar"));
    add("Reload shell", "Restart Quickshell, apps stay open", "restart", () => Quickshell.reload(false), "", ["restart shell", "quickshell"]);
    add("Show hidden apps again", state.hidden.length + " hidden", "image", () => { state.hidden = []; root.revision++; });
    add("Screenshot", "Print or Super + Shift + R · area, window or screen", "photo", () => Capture.toggle(null), "", ["screenshot", "capture", "print", "snip"]);
    if (Capture.hasRecorder && !Capture.recording) add("Record screen", "Choose what to record", "record", () => { Capture.mode = "record"; Capture.toggle(null); }, "", ["record", "video", "screencast"]);
    if (Capture.recording) add("Stop recording", Capture.elapsedText + " recorded · Super + Ctrl + R", "stop", () => Capture.stop(), "", ["stop", "record"]);
    add("Power menu", "Super + Esc", "power", () => Power.toggle(null), "", ["power", "shutdown", "reboot", "logout"]);
    if (Power.scheduled) add("Cancel scheduled " + (Power.action(Power.scheduledId)?.label ?? "").toLowerCase(), "At " + Power.scheduledTime, "close", () => Power.cancelSchedule(), "", ["cancel", "power"]);
    add("Lock screen", "Super + L", "lock", () => Lock.lock(), "", ["lock", "away"]);
    add("Suspend", "Lock and sleep until a key is pressed", "moon", () => Lock.suspend(), "", ["sleep"]);
    add("Log out", "Close everything and leave Hyprland", "logout", () => Hypr.exit(), "Press Enter again to log out", ["logout", "sign out", "exit"]);
    add("Restart", "Restart the computer", "restart", () => Quickshell.execDetached(["systemctl", "reboot"]), "Press Enter again to restart", ["reboot"]);
    add("Shut down", "Turn the computer off", "power", () => Quickshell.execDetached(["systemctl", "poweroff"]), "Press Enter again to shut down", ["poweroff", "power off", "turn off"]);
    return list;
  }

  // --- Window commands (act on the window that had focus) ----------------------
  function windowCommands(rest: string): var {
    const list = [];
    const add = (title, subtitle, icon, run) => list.push({ key: "win:" + title, section: "Window", title, subtitle, icon, hint: "Window", run });
    const active = Hyprland.activeToplevel;
    const name = active ? (active.title || "") : "";
    add("Float or tile", name, "image", () => Hypr.windowFloat());
    add("Pseudo-tile", name, "image", () => Hypr.windowPseudo());
    add("Close window", name, "close", () => Hypr.windowClose());
    const ws = parseInt(rest);
    if (!isNaN(ws) && ws > 0) {
      add("Move to workspace " + ws, name, "arrow-right", () => Hypr.windowToWorkspace(ws));
    } else {
      for (let i = 1; i <= 5; i++) add("Move to workspace " + i, name, "arrow-right", () => Hypr.windowToWorkspace(i));
    }
    return list;
  }

  // --- Processes ("kill name") ---------------------------------------------------
  property var processes: []
  property string processQuery: ""

  Process {
    id: psProc
    command: ["ps", "-eo", "pid=,comm=,%cpu=,rss=", "--sort=-%cpu"]
    stdout: StdioCollector {
      onStreamFinished: {
        const rows = [];
        for (const line of text.split("\n")) {
          const m = line.trim().match(/^(\d+)\s+(.+?)\s+([\d.]+)\s+(\d+)$/);
          if (m) rows.push({ pid: m[1], name: m[2], cpu: parseFloat(m[3]), mem: parseInt(m[4]) * 1024 });
        }
        root.processes = rows;
        root.revision++;
      }
    }
  }

  function formatBytes(bytes: real): string {
    if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB";
    return Math.round(bytes / 1048576) + " MB";
  }

  function processResults(q: string): var {
    if (q !== processQuery) {
      processQuery = q;
      psProc.running = true;
    }
    return processes.filter(p => q === "" || p.name.toLowerCase().includes(q)).slice(0, 8).map(p => ({
      key: "kill:" + p.pid, section: "Processes", icon: "close", hint: "Kill",
      title: p.name, subtitle: "PID " + p.pid + " · CPU " + p.cpu.toFixed(1) + "% · " + formatBytes(p.mem),
      run: () => Quickshell.execDetached(["kill", p.pid]),
      runAlt: () => Quickshell.execDetached(["kill", "-9", p.pid]),
      altHint: "Ctrl + Enter: force"
    }));
  }

  // --- Your scripts (scripts/launcher/) ---------------------------------------------
  readonly property string scriptsDir: Quickshell.shellPath("scripts/launcher")
  property var scripts: []

  Process {
    id: scriptsProc
    command: ["find", root.scriptsDir, "-maxdepth", "1", "-type", "f", "-perm", "-u+x"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.scripts = text.split("\n").filter(p => p !== "").sort();
        root.revision++;
      }
    }
  }

  function scriptResults(q: string): var {
    return scripts.map(path => {
      const file = path.split("/").pop();
      const name = file.replace(/\.[a-z]+$/, "").replace(/[-_]/g, " ");
      return { path, file, name };
    }).filter(s => q === "" || scoreText(s.name.toLowerCase(), q) > 0 || s.file.toLowerCase().includes(q)).map(s => ({
      key: "script:" + s.path, section: "Scripts", icon: "arrow-right", hint: "Script",
      title: s.name, subtitle: s.file,
      run: () => Quickshell.execDetached(["sh", "-c", "cd \"$1\" && \"$2\"", "sh", root.scriptsDir, s.path]),
      runAlt: () => DefaultApps.inTerminal("${EDITOR:-nvim} \"$1\"", [s.path]),
      altHint: "Ctrl + Enter: edit"
    }));
  }

  // --- Search --------------------------------------------------------------------
  function search(text: string): var {
    const trimmed = text.trim();
    const q = trimmed.toLowerCase();
    const first = q.split(/\s+/)[0];
    const rest = trimmed.slice(first.length).trim();
    let results = [];

    // > command
    if (q.startsWith(">")) {
      const cmd = trimmed.slice(1).trim();
      if (cmd !== "") results.push({ key: "cmd", section: "Run", title: cmd, subtitle: "Run in a shell", icon: "arrow-right", hint: "Command", run: () => Quickshell.execDetached(["sh", "-c", cmd]) });
      return results;
    }

    // kill <name>
    if (first === "kill") return processResults(rest.toLowerCase());

    // :emoji
    if (q.startsWith(":") && LauncherTools.emoji.length > 0) {
      return LauncherTools.findEmoji(q.slice(1)).map(e => ({
        key: "emoji:" + e[0], section: "Emoji", glyph: e[0], title: e[1].charAt(0).toUpperCase() + e[1].slice(1),
        subtitle: LauncherTools.hasWtype ? "Typed into your window and copied" : "Copied", icon: "image", hint: "Emoji",
        run: () => LauncherTools.typeText(e[0])
      }));
    }

    // ;snippet
    if (q.startsWith(";")) {
      const term = q.slice(1);
      const list = LauncherTools.snippets.filter(sn => term === "" || sn.name.toLowerCase().includes(term));
      if (list.length === 0) return [{ key: "snip:none", section: "Snippets", title: "No snippets yet", subtitle: "Add .txt files to the snippets folder", icon: "plus", hint: "", run: () => Quickshell.execDetached(["xdg-open", LauncherTools.snippetsDir]) }];
      return list.map(sn => ({
        key: "snip:" + sn.path, section: "Snippets", title: sn.name, subtitle: LauncherTools.hasWtype ? "Typed into your window and copied" : "Copied",
        icon: "clipboard", hint: "Snippet", altHint: "Ctrl + Enter: edit",
        run: () => LauncherTools.typeFile(sn.path),
        runAlt: () => DefaultApps.inTerminal("${EDITOR:-nvim} \"$1\"", [sn.path])
      }));
    }

    // /file or f file
    if (LauncherTools.hasFd && (q.startsWith("/") || ((first === "f" || first === "file") && rest !== ""))) {
      const term = q.startsWith("/") ? trimmed.slice(1) : rest;
      return LauncherTools.findFiles(term).map(f => ({
        key: "file:" + f.path, section: "Files", title: f.name, subtitle: f.folder, icon: f.isDir ? "folder" : "file",
        hint: f.isDir ? "Folder" : "File", altHint: "Ctrl + Enter: show in folder",
        run: () => Qt.openUrlExternally("file://" + f.path),
        runAlt: () => Qt.openUrlExternally("file://" + f.path.split("/").slice(0, -1).join("/"))
      }));
    }

    // color: pick from the screen, or copy a recent one
    if (LauncherTools.hasPicker && (first === "color" || first === "colour" || first === "pick" || first === "hex")) {
      const list = [{ key: "color:pick", section: "Color", title: "Pick a color from the screen", subtitle: "Click anywhere; the hex code is copied", icon: "palette", hint: "hyprpicker", run: () => LauncherTools.pickColor() }];
      for (const hex of LauncherTools.recentColors) {
        list.push({ key: "color:" + hex, section: "Recent colors", title: hex, subtitle: "RGB " + LauncherTools.rgb(hex), swatch: hex, icon: "palette", hint: "Copy", run: () => Quickshell.execDetached(["wl-copy", hex]) });
      }
      return list;
    }

    // clip <text>: clipboard history
    if (Clipboard.available && (first === "clip" || first === "clipboard" || first === "cb")) {
      const list = [{ key: "clip:open", section: "Clipboard", title: "Open clipboard history", subtitle: "Pins, images and previews · Super + Shift + V", icon: "clipboard", hint: "Window", run: () => Clipboard.toggle(root.screen) }];
      for (const item of Clipboard.filtered("all", rest).slice(0, 8)) {
        list.push({
          key: "clip:" + item.id, section: rest === "" ? "Recent" : "Matches",
          title: item.kind === "image" ? Clipboard.imageTitle(item) : item.preview, subtitle: Clipboard.meta(item),
          icon: ({ text: "text", code: "code", link: "link", image: "image", color: "droplet" })[item.kind] ?? "text",
          swatch: item.kind === "color" ? item.preview : "",
          hint: item.pinned ? "Pinned" : "", altHint: "Enter paste · Ctrl + Enter copy",
          run: () => Clipboard.paste(item),
          runAlt: () => Clipboard.copy(item)
        });
      }
      return list;
    }

    // window …
    if (first === "window" || first === "win") return windowCommands(rest);

    // yt lofi
    const link = quicklinks.find(l => l.keyword === first);
    if (link && rest !== "") {
      results.push({ key: "link:" + link.keyword, section: "Quicklinks", title: link.name + ": " + rest, subtitle: link.url.replace("%s", rest).replace(/^https?:\/\//, ""), icon: "search", hint: "Quicklink", run: () => openUrl(link.url, rest) });
    }

    // Sum: qalc when installed (units, %, currency), the built-in one meanwhile
    const calc = LauncherTools.calc(trimmed) || calculate(trimmed);
    if (calc !== "") results.push({ key: "calc", section: "Calculator", title: calc, subtitle: trimmed + " =", icon: "plus", hint: "Enter to copy", big: true, run: () => Quickshell.execDetached(["wl-copy", calc]) });

    // Nothing typed: favorites, then the most used apps
    if (q === "") {
      const favorites = state.favorites.map(id => apps.find(a => a.id === id)).filter(a => a);
      for (const app of favorites) results.push(appResult(app, "Favorites"));
      const used = apps.filter(a => !isFavorite(a.id) && boostFor(a.id) > 0)
        .sort((a, b) => boostFor(b.id) - boostFor(a.id)).slice(0, 6);
      for (const app of used) results.push(appResult(app, "Frequently used"));
      if (results.length === 0) {
        for (const app of apps.slice().sort((a, b) => a.name.localeCompare(b.name)).slice(0, 8)) results.push(appResult(app, "Applications"));
      }
      return results;
    }

    // Apps
    const scored = [];
    for (const app of apps) {
      const s = scoreApp(app, q) + (isFavorite(app.id) ? 15 : 0);
      if (s > 0) scored.push({ app, s });
    }
    scored.sort((a, b) => b.s - a.s || a.app.name.localeCompare(b.app.name));
    for (const item of scored.slice(0, 7)) results.push(appResult(item.app, "Applications"));

    // System commands and scripts that match
    // Hyphens don't count, so "wifi" finds "Wi-Fi"
    const plain = q.replace(/-/g, "");
    const commands = systemCommands.filter(c => scoreText(c.title.toLowerCase().replace(/-/g, ""), plain) > 0
                                            || c.subtitle.toLowerCase().startsWith(q)
                                            || c.words.some(w => w.startsWith(plain)));
    results = results.concat(commands.slice(0, 4));
    results = results.concat(scriptResults(q).slice(0, 4));

    // Nothing found: offer what to do with the text
    if (results.length === 0) {
      const section = "Use \"" + trimmed + "\" with…";
      results.push({ key: "fb:web", section, title: "Search the web", subtitle: "DuckDuckGo", icon: "search", hint: "Web", run: () => openUrl("https://duckduckgo.com/?q=%s", trimmed) });
      results.push({ key: "fb:wiki", section, title: "Search the ArchWiki", subtitle: "wiki.archlinux.org", icon: "search", hint: "Web", run: () => openUrl("https://wiki.archlinux.org/index.php?search=%s", trimmed) });
      results.push({ key: "fb:aur", section, title: "Search the AUR", subtitle: "aur.archlinux.org", icon: "search", hint: "Web", run: () => openUrl("https://aur.archlinux.org/packages?K=%s", trimmed) });
      results.push({ key: "fb:run", section, title: "Run as a command", subtitle: trimmed, icon: "arrow-right", hint: "Command", run: () => Quickshell.execDetached(["sh", "-c", trimmed]) });
    }
    return results;
  }

  // --- Ctrl + K: what you can do with an app ------------------------------------------
  function actionsFor(result: var): var {
    if (!result || !result.app) return [];
    const app = result.app;
    const list = [{ title: "Open", icon: "arrow-right", run: result.run }];
    for (let i = 1; i <= 5; i++) {
      list.push({ title: "Open on workspace " + i, icon: "image", run: () => { Hypr.focusWorkspace(i); remember(app.id); app.execute(); } });
    }
    for (const action of app.actions ?? []) {
      list.push({ title: action.name, icon: "chevron-right", run: () => action.execute() });
    }
    list.push({ title: isFavorite(app.id) ? "Remove from favorites" : "Pin to favorites", icon: "star", keepOpen: true, run: () => toggleFavorite(app.id) });
    list.push({ title: "Hide from results", icon: "close", keepOpen: true, run: () => hide(app.id) });
    return list;
  }
}
