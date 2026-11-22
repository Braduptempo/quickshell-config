#!/usr/bin/env python3
"""Pass the shell's theme on to other apps: GTK 3/4 and Spotify (Spicetify).

Run by services/AppTheme.qml whenever the theme, accent or wallpaper palette
changes, with the palette as JSON:

    app-theme.py '{"light": false, "base": "#1a1b26", "accent": "#7aa2f7", ...}'

Keys: light, crust, base, surface, overlay, text, subtext, accent, good,
warn, error (the same as config/Palettes.qml).

GTK
    Writes ~/.config/gtk-{3,4}.0/quickshell-colors.css and imports it from
    gtk.css (the line is added once; the rest of gtk.css stays yours). Sets
    the dark/light preference, and nudges running GTK 3 apps to re-read
    their CSS.

Spotify
    Needs spicetify and its "text" theme (~/.config/spicetify/Themes/text).
    Builds a theme "Glass" from text's user.css plus apps/spicetify/glass.css,
    writes a colour scheme "Quickshell", and runs `spicetify refresh`. The
    extension apps/spicetify/quickshell-live.js then reloads the colours in
    a running Spotify. The first run switches Spicetify to Glass and runs
    `spicetify apply` once.

Every file is only written when its content changes.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
REPO = Path(__file__).resolve().parent.parent
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", HOME / ".config"))
KEYS = ["crust", "base", "surface", "overlay", "text", "subtext", "accent", "good", "warn", "error"]


def write(path: Path, text: str) -> bool:
    """Write only when different. True when the file changed."""
    try:
        if path.read_text() == text:
            return False
    except FileNotFoundError:
        pass
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(text)
    tmp.replace(path)
    return True


def run(*cmd: str) -> None:
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False, timeout=60)


def hexpart(c: str) -> str:
    return c.lstrip("#")[:6].lower()


def rgb(c: str) -> str:
    h = hexpart(c)
    return f"{int(h[0:2], 16)}, {int(h[2:4], 16)}, {int(h[4:6], 16)}"


# --- GTK ---------------------------------------------------------------------

def gtk_css(p: dict) -> str:
    on_accent = p["base"] if p["light"] else p["crust"]
    named = {
        # GTK 3 / Adwaita
        "theme_bg_color": p["base"], "theme_fg_color": p["text"],
        "theme_base_color": p["crust"], "theme_text_color": p["text"],
        "theme_selected_bg_color": p["accent"], "theme_selected_fg_color": on_accent,
        "insensitive_bg_color": p["base"], "insensitive_fg_color": p["subtext"],
        "theme_unfocused_bg_color": p["base"], "theme_unfocused_fg_color": p["text"],
        "borders": p["overlay"], "unfocused_borders": p["overlay"],
        # libadwaita
        "accent_color": p["accent"], "accent_bg_color": p["accent"], "accent_fg_color": on_accent,
        "window_bg_color": p["base"], "window_fg_color": p["text"],
        "view_bg_color": p["crust"], "view_fg_color": p["text"],
        "headerbar_bg_color": p["crust"], "headerbar_fg_color": p["text"],
        "headerbar_backdrop_color": p["base"], "headerbar_border_color": p["overlay"],
        "sidebar_bg_color": p["crust"], "sidebar_fg_color": p["text"],
        "sidebar_backdrop_color": p["base"],
        "card_bg_color": p["surface"], "card_fg_color": p["text"],
        "popover_bg_color": p["surface"], "popover_fg_color": p["text"],
        "dialog_bg_color": p["base"], "dialog_fg_color": p["text"],
        "destructive_bg_color": p["error"], "destructive_fg_color": on_accent,
        "success_color": p["good"], "warning_color": p["warn"], "error_color": p["error"],
    }
    lines = ["/* Made by quickshell (scripts/app-theme.py) from the shell's theme. */",
             "/* Changes here are overwritten; put your own rules in gtk.css. */", ""]
    lines += [f"@define-color {k} {v};" for k, v in named.items()]
    # libadwaita 1.6+ reads CSS variables
    lines += ["", ":root {"]
    lines += [f"  --{k.replace('_', '-')}: {v};" for k, v in named.items()]
    lines += ["}", ""]
    return "\n".join(lines)


def gtk(p: dict) -> None:
    css = gtk_css(p)
    changed = False
    for ver in ("gtk-3.0", "gtk-4.0"):
        d = CONFIG / ver
        changed |= write(d / "quickshell-colors.css", css)
        main = d / "gtk.css"
        line = '@import url("quickshell-colors.css");'
        cur = main.read_text() if main.exists() else ""
        if line not in cur:
            write(main, line + "\n" + cur)
            changed = True

    if not shutil.which("gsettings"):
        return
    schema = "org.gnome.desktop.interface"
    run("gsettings", "set", schema, "color-scheme", "prefer-light" if p["light"] else "prefer-dark")
    theme = "Adwaita" if p["light"] else "Adwaita-dark"
    if changed:
        # GTK 3 only re-reads CSS when the theme name changes: flip it once
        run("gsettings", "set", schema, "gtk-theme", "HighContrast")
    run("gsettings", "set", schema, "gtk-theme", theme)


# --- Spotify -------------------------------------------------------------------

def spicetify_scheme(p: dict) -> str:
    c = {
        "text": p["text"], "subtext": p["subtext"],
        "main": p["base"], "main-elevated": p["surface"],
        "highlight": p["surface"], "highlight-elevated": p["overlay"],
        "sidebar": p["crust"], "player": p["base"],
        "card": p["surface"], "shadow": p["crust"],
        "selected-row": p["text"],
        "button": p["accent"], "button-active": p["accent"], "button-disabled": p["overlay"],
        "tab-active": p["surface"],
        "notification": p["accent"], "notification-error": p["error"],
        "misc": p["overlay"],
        # used by the text theme
        "accent": p["accent"], "accent-active": p["accent"], "accent-inactive": p["crust"],
        "banner": p["accent"], "header": p["subtext"],
        "border-active": p["accent"], "border-inactive": p["overlay"],
    }
    width = max(len(k) for k in c)
    body = "\n".join(f"{k:<{width}} = {hexpart(v)}" for k, v in c.items())
    return f"; Made by quickshell (scripts/app-theme.py)\n[Quickshell]\n{body}\n"


def spicetify_config(field: str) -> str:
    # -q would hide the value too
    out = subprocess.run(["spicetify", "config", field], capture_output=True, text=True, check=False)
    return out.stdout.strip()


def spicetify_list(field: str) -> list:
    return [x.strip() for x in spicetify_config(field).replace("|", "\n").splitlines() if x.strip()]


def spotify(p: dict) -> None:
    if not shutil.which("spicetify"):
        return
    root = CONFIG / "spicetify"
    text_theme = root / "Themes" / "text" / "user.css"
    if not text_theme.exists():
        return

    theme = root / "Themes" / "Glass"
    css = text_theme.read_text() + "\n" + (REPO / "apps" / "spicetify" / "glass.css").read_text()
    changed = write(theme / "user.css", css)
    changed |= write(theme / "color.ini", spicetify_scheme(p))
    ext = "quickshell-live.js"
    changed |= write(root / "Extensions" / ext, (REPO / "apps" / "spicetify" / ext).read_text())

    first = (spicetify_config("current_theme") != "Glass"
             or spicetify_config("color_scheme") != "Quickshell"
             or ext not in spicetify_list("extensions"))
    if first:
        args = ["spicetify", "-q", "config", "current_theme", "Glass", "color_scheme", "Quickshell"]
        if ext not in spicetify_list("extensions"):
            args += ["extensions", ext]
        run(*args)
        run("spicetify", "-q", "apply")
    elif changed:
        run("spicetify", "-q", "refresh")


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[0], file=sys.stderr)
        return 2
    raw = json.loads(sys.argv[1])
    p = {k: str(raw[k]) for k in KEYS}
    p["light"] = bool(raw.get("light", False))
    for step in (gtk, spotify):
        try:
            step(p)
        except Exception as e:  # one app failing shouldn't stop the others
            print(f"app-theme: {step.__name__}: {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
