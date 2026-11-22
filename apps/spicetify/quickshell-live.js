// quickshell-live.js — Spicetify extension
// Reloads the theme's colours and CSS while Spotify is open, so a theme change
// in Quickshell shows up without restarting Spotify. scripts/app-theme.py
// writes the new colours and runs `spicetify refresh`, which replaces
// colors.css and user.css next to Spotify's own files; this notices that and
// swaps the stylesheets in place.
(function quickshellLive() {
  const files = ["colors.css", "user.css"];
  const last = {};

  async function check() {
    for (const name of files) {
      try {
        const res = await fetch("/" + name, { cache: "no-store" });
        if (!res.ok) continue;
        const text = await res.text();
        if (last[name] !== undefined && last[name] !== text) {
          const link = [...document.querySelectorAll("link.userCSS")]
            .find(l => new URL(l.href).pathname === "/" + name);
          if (link) link.href = "/" + name + "?t=" + Date.now();
        }
        last[name] = text;
      } catch (e) {
        // Spotify is starting or closing: try again next round
      }
    }
  }

  check();
  setInterval(check, 2000);
})();
