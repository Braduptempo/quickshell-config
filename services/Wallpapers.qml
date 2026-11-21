// Wallpapers.qml
// The wallpapers in ~/Pictures/wallpapers: images and GIFs with awww (or
// swww), videos (mp4, webm, mkv, mov) played by the shell itself
// (modules/wallpaper/VideoWallpaper.qml). Under a video awww shows a still
// frame of it, so the lock screen and the wallpaper theme have a picture.
//   Wallpapers.set(path)           on the chosen screen(s), with the transition
//   Wallpapers.preview(path)       the same, for browsing; restore() undoes it
//   Wallpapers.toggleFavorite(path), random()
// Favourites, fit, transition, screen and "change every 30 min" are kept in
// the shell's state folder. Small thumbnails are made once (ImageMagick) in
// ~/.cache/quickshell/wallpapers.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  property double closedAt: 0

  onOpenChanged: {
    if (open) {
      refresh();
    } else {
      closedAt = Date.now();
    }
  }

  function toggle(onScreen: ShellScreen): void {
    if (open) {
      open = false;
    } else if (Date.now() - closedAt > 250) {
      screen = onScreen;
      open = true;
    }
  }

  readonly property string home: Quickshell.env("HOME")
  readonly property string folder: home + "/Pictures/wallpapers"
  readonly property string thumbDir: home + "/.cache/quickshell/wallpapers"
  readonly property string tool: hasAwww ? "awww" : "swww"
  property bool hasAwww: true
  property bool available: false

  // [{ path, name, thumb, video }]
  property var items: []

  function isVideo(path: string): bool {
    return /\.(mp4|webm|mkv|mov)$/i.test(path);
  }
  // A full-size still of a video, for awww under it
  function posterFor(path: string): string {
    return thumbDir + "/posters/" + path.split("/").pop().replace(/\.[^.]+$/, "") + ".jpg";
  }
  // output name -> path
  property var current: ({})

  // --- Saved choices ------------------------------------------------------------------
  FileView {
    path: Quickshell.statePath("wallpaper.json")
    watchChanges: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => {
      if (error === FileViewError.FileNotFound) writeAdapter();
    }

    JsonAdapter {
      id: saved
      property var favorites: []
      // "crop" fills the screen, "fit" shows all of it
      property string fit: "crop"
      // "fade", "wipe" or "grow"
      property string transition: "fade"
      // "" = every screen, or an output name
      property string output: ""
      property bool rotate: false
      // output name -> video playing there
      property var videos: ({})
    }
  }

  property alias favorites: saved.favorites
  property alias fit: saved.fit
  property alias transition: saved.transition
  property alias output: saved.output
  property alias rotate: saved.rotate

  function isFavorite(path: string): bool {
    return favorites.indexOf(path) >= 0;
  }

  function toggleFavorite(path: string): void {
    favorites = isFavorite(path) ? favorites.filter(f => f !== path) : favorites.concat([path]);
  }

  // --- Finding them ---------------------------------------------------------------------
  function refresh(): void {
    listProc.running = true;
    queryProc.running = true;
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["sh", "-c",
      "command -v awww >/dev/null && echo tool:awww || { command -v swww >/dev/null && echo tool:swww; };" +
      "find \"$1\" -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif'" +
      " -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) | sort -f",
      "sh", root.folder]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n").filter(l => l !== "");
        const tool = lines.find(l => l.startsWith("tool:"));
        root.available = tool !== undefined;
        root.hasAwww = tool === "tool:awww";
        root.items = lines.filter(l => !l.startsWith("tool:")).map(path => {
          const file = path.split("/").pop();
          return {
            path,
            name: file.replace(/\.[^.]+$/, "").replace(/[-_]+/g, " "),
            thumb: root.thumbDir + "/" + file.replace(/\.[^.]+$/, "") + ".jpg",
            video: root.isVideo(path)
          };
        });
        thumbProc.running = true;
      }
    }
  }

  // Thumbnails that don't exist yet; the picker shows the full image meanwhile
  property int thumbsMade: 0

  Process {
    id: thumbProc
    command: ["sh", "-c",
      "mkdir -p \"$1\"; shift;" +
      "for f in \"$@\"; do t=\"$THUMBS/$(basename \"${f%.*}\").jpg\"; [ -s \"$t\" ] && continue;" +
      " case \"$f\" in" +
      // Videos: a frame a second in, with ffmpeg
      "  *.mp4|*.MP4|*.webm|*.mkv|*.mov) command -v ffmpeg >/dev/null && ffmpeg -loglevel error -y -ss 1 -i \"$f\" -frames:v 1" +
      "   -vf 'scale=384:216:force_original_aspect_ratio=increase,crop=384:216' -q:v 4 \"$t\" && echo made ;;" +
      "  *) command -v magick >/dev/null && magick \"$f[0]\" -thumbnail 384x216^ -gravity center -extent 384x216 -quality 85 \"$t\" 2>/dev/null && echo made ;;" +
      " esac; done",
      "sh", root.thumbDir].concat(root.items.map(i => i.path))
    environment: ({ THUMBS: root.thumbDir })
    stdout: SplitParser {
      onRead: root.thumbsMade++
    }
  }

  Process {
    id: queryProc
    command: ["sh", "-c", "(awww query || swww query) 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const map = {};
        for (const line of text.split("\n")) {
          const m = line.match(/^:?\s*([^:]+):.*image:\s*(.+)$/);
          if (m) map[m[1].trim()] = m[2].trim();
        }
        root.current = map;
      }
    }
  }

  // Videos per screen: while browsing, the one being tried
  property var previewVideos: null
  readonly property var videos: previewVideos ?? saved.videos

  function videoFor(output: string): string {
    return videos[output] ?? "";
  }

  // The wallpaper on the screen the picker is for (or any screen); a video
  // counts over the still under it
  readonly property string currentPath: {
    const name = output !== "" ? output : (screen?.name ?? "");
    return saved.videos[name] ?? current[name] ?? Object.values(saved.videos)[0] ?? Object.values(current)[0] ?? "";
  }

  // --- Setting them ------------------------------------------------------------------------
  function transitionArgs(fast: bool): var {
    if (fast) return ["--transition-type", "fade", "--transition-duration", "0.4", "--transition-fps", "60"];
    switch (transition) {
    case "wipe": return ["--transition-type", "wipe", "--transition-angle", "30", "--transition-duration", "1", "--transition-fps", "60"];
    case "grow": return ["--transition-type", "grow", "--transition-pos", "center", "--transition-duration", "1", "--transition-fps", "60"];
    default: return ["--transition-type", "fade", "--transition-duration", "0.8", "--transition-fps", "60"];
    }
  }

  // keep: false while browsing (the video only plays until restore() or set())
  function apply(path: string, fast: bool, keep: bool): void {
    if (path === "") return;
    const targets = output !== "" ? [output] : Quickshell.screens.map(s => s.name);
    const map = Object.assign({}, keep ? saved.videos : videos);
    for (const name of targets) {
      if (isVideo(path)) map[name] = path;
      else delete map[name];
    }
    if (keep) {
      saved.videos = map;
      previewVideos = null;
    } else {
      previewVideos = map;
    }
    if (!available) return;
    const args = [tool, "img", isVideo(path) ? posterFor(path) : path, "--resize", fit === "fit" ? "fit" : "crop"].concat(transitionArgs(fast));
    if (output !== "") args.push("--outputs", output);
    if (!isVideo(path)) {
      Quickshell.execDetached(args);
      return;
    }
    // The still is made once, then shown under the video
    Quickshell.execDetached(["sh", "-c",
      "p=\"$1\"; f=\"$2\"; shift 2; mkdir -p \"$(dirname \"$p\")\";" +
      " [ -s \"$p\" ] || ffmpeg -loglevel error -y -ss 1 -i \"$f\" -frames:v 1 -q:v 2 \"$p\"; exec \"$@\"",
      "sh", posterFor(path), path].concat(args));
  }

  // What was on screen before browsing, so Esc can put it back
  property var before: ({})
  property bool previewing: false

  function preview(path: string): void {
    if (!previewing) {
      before = Object.assign({}, current);
      previewing = true;
    }
    previewDelay.path = path;
    previewDelay.restart();
  }

  // Waits for a pause in browsing, so holding an arrow key doesn't queue up images
  Timer {
    id: previewDelay
    property string path: ""
    interval: 350
    onTriggered: root.apply(path, true, false)
  }

  function set(path: string): void {
    previewDelay.stop();
    previewing = false;
    apply(path, false, true);
    const map = Object.assign({}, current);
    for (const name of output !== "" ? [output] : Quickshell.screens.map(s => s.name)) map[name] = path;
    current = map;
  }

  function restore(): void {
    previewDelay.stop();
    if (!previewing) return;
    previewing = false;
    // The saved videos come back by themselves
    previewVideos = null;
    for (const name of Object.keys(before)) {
      Quickshell.execDetached([tool, "img", before[name], "--outputs", name, "--resize", fit === "fit" ? "fit" : "crop"].concat(transitionArgs(true)));
    }
  }

  function random(): string {
    const pool = items.filter(i => i.path !== currentPath);
    return pool.length > 0 ? pool[Math.floor(Math.random() * pool.length)].path : "";
  }

  // --- Change every 30 minutes ---------------------------------------------------------------
  Timer {
    running: root.rotate && root.items.length > 1
    interval: 30 * 60 * 1000
    repeat: true
    onTriggered: {
      const favs = root.items.filter(i => root.isFavorite(i.path) && i.path !== root.currentPath);
      const pool = favs.length > 0 ? favs : root.items.filter(i => i.path !== root.currentPath);
      if (pool.length > 0) root.set(pool[Math.floor(Math.random() * pool.length)].path);
    }
  }
}
