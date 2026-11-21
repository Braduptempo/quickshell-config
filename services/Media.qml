// Media.qml
// Which media player the bar and the media menu control.
// By default the one that is playing (or the first one); picking a player in
// the media menu sticks until that player goes away.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  property bool open: false
  property ShellScreen screen: null
  // Left edge of the media pill, so the menu opens right below it
  property real anchorX: 180
  property double closedAt: 0

  onOpenChanged: if (!open) closedAt = Date.now()

  function toggle(onScreen: ShellScreen, x: real): void {
    if (open) {
      open = false;
    } else if (Date.now() - closedAt > 250) {
      screen = onScreen;
      anchorX = x;
      open = true;
    }
  }

  readonly property var players: Mpris.players.values

  // Chosen in the menu; cleared when that player closes
  property string pickedId: ""

  readonly property MprisPlayer player: {
    const list = players;
    const picked = list.find(p => p.uniqueId === pickedId);
    if (picked) return picked;
    const playing = list.find(p => p.isPlaying);
    if (playing) return playing;
    return list.length > 0 ? list[0] : null;
  }

  function pick(p: MprisPlayer): void {
    pickedId = p ? p.uniqueId : "";
  }

  // "1:24"
  function formatTime(seconds: real): string {
    const s = Math.max(0, Math.floor(seconds));
    const h = Math.floor(s / 3600);
    const m = Math.floor(s % 3600 / 60);
    const rest = String(s % 60).padStart(2, "0");
    return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + rest : m + ":" + rest;
  }

  // Short name of a player: "Spotify", "Firefox"
  function nameOf(p: MprisPlayer): string {
    if (!p) return "";
    const name = (p.identity || p.desktopEntry || p.dbusName || "Player").replace(/^Mozilla /, "");
    return name.charAt(0).toUpperCase() + name.slice(1);
  }

  // The app's own icon name ("spotify", "firefox"), or ""
  function iconOf(p: MprisPlayer): string {
    if (!p) return "";
    const entry = DesktopEntries.heuristicLookup(p.desktopEntry || p.identity || "");
    return entry ? entry.icon : "";
  }

  // The Hyprland window the player plays in: the same app, and for a
  // browser with several windows the one whose title has the track in it
  function windowOf(p: MprisPlayer): var {
    if (!p) return null;
    const keys = [p.desktopEntry, p.identity, p.dbusName.split(".")[3] ?? ""]
      .filter(k => k && k !== "")
      .map(k => k.toLowerCase().replace(/^mozilla /, ""));
    const same = Windows.windows.filter(w => {
      const app = w.app.toLowerCase();
      return keys.some(k => app === k || app.endsWith("." + k) || app.includes(k) || k.includes(app));
    });
    if (same.length === 0) return null;
    return same.find(w => p.trackTitle !== "" && w.title.includes(p.trackTitle)) ?? same[0];
  }

  function canShow(p: MprisPlayer): bool {
    return windowOf(p) !== null || (p?.canRaise ?? false);
  }

  // Go to the player's window, on whatever workspace or screen it is
  function show(p: MprisPlayer): void {
    const w = windowOf(p);
    if (w) Hypr.run("hl.dsp.focus({ window = \"address:" + w.address + "\" })", "focuswindow address:" + w.address);
    else if (p?.canRaise) p.raise();
  }

  function stateOf(p: MprisPlayer): string {
    if (!p) return "";
    const what = p.isPlaying ? "Playing" : p.playbackState === MprisPlaybackState.Paused ? "Paused" : "Stopped";
    return p.trackTitle !== "" ? what + " · " + p.trackTitle : what;
  }
}
