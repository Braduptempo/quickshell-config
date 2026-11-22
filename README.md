# quickshell-config

A desktop shell for Hyprland, built with [Quickshell](https://quickshell.outfoxxed.me): bar, panels, launcher, lock screen, notifications and a settings window. Everything is translucent glass and can be set up from Settings (Super + ,), without editing files.

- [Install](#install)
- [Keybinds](#keybinds)
- [What's in it](#whats-in-it)
- [Settings](#settings)
- [IPC](#ipc)
- [Development](#development)
- [Checks](#checks)

## Install

Needs Arch Linux, Quickshell 0.3 or newer and Hyprland with a Lua config (`hyprland.lua`).

### With the script

```bash
curl -fsSL https://raw.githubusercontent.com/Braduptempo/quickshell-config/main/install.sh | bash
```

Or from a clone: `./install.sh`. It asks before every step:

1. installs the packages below with pacman (`--minimal`: only the required ones);
2. puts this config in `~/.config/quickshell` (an existing other config is moved to a backup first);
3. adds the line for the shell's rules and keys to `hyprland.lua`, and starts the shell with Hyprland unless something already does;
4. turns on NetworkManager, Bluetooth and power profiles.

`--dry-run` shows what it would do without changing anything, `--yes` answers yes to everything. Running it again is safe: what's already done is skipped.

### By hand

```bash
git clone https://github.com/Braduptempo/quickshell-config ~/.config/quickshell
```

Add this line at the end of `~/.config/hypr/hyprland.lua`. It loads the glass blur, the keybinds below, and the monitor and input settings made in Settings:

```lua
pcall(dofile, os.getenv("HOME") .. "/.config/quickshell/hyprland/quickshell.lua")
```

Start the shell (and add the same to your autostart):

```bash
qs -d
```

Start it like this, not with `qs -p <folder>`: the keybinds call `qs ipc call …` without a path, so they only reach the shell in `~/.config/quickshell`.

### Programs it uses

Arch package names, all in the official repos. Everything except the first group is optional: a feature whose program is missing is hidden or says what to install.

| For | Packages |
|---|---|
| The basics | `quickshell`, `hyprland`, `networkmanager`, `pipewire` + `wireplumber`, `upower`, `libnotify` (`notify-send`), `wl-clipboard`, `curl` |
| Bluetooth | `bluez`, `bluez-utils` (and `systemctl enable --now bluetooth`) |
| Clipboard history | `cliphist` |
| Screenshots and recording | `grim`, `slurp`, `gpu-screen-recorder` |
| Wallpapers | `awww` (or `swww`); videos play in the shell itself (`qt6-multimedia`, `qt6-multimedia-ffmpeg`), with `ffmpeg` for their thumbnails |
| Night light | `hyprsunset` |
| Brightness | `brightnessctl` |
| Colour picker (launcher, theme editor) | `hyprpicker` |
| Launcher calculator | `libqalculate` (`qalc`) |
| Update count | `pacman-contrib` (`checkupdates`), and `yay` or `paru` for the AUR |
| Drives | `udisks2` |
| Power profiles | `power-profiles-daemon` |

## Keybinds

From `hyprland/quickshell.lua`. Settings → Keybinds lists every bind, including your own.

| Keys | What it does |
|---|---|
| Super + Space | Launcher |
| Super + X | Main menu (also the button at the far left of the bar; right click it for the launcher) |
| Super + A | Quick settings |
| Super + N | Notifications (Super + Shift + N: do not disturb) |
| Super + , | Settings |
| Super + T / Super + W | Theme picker / wallpaper picker |
| Super + Shift + V | Clipboard history |
| Super + L | Lock |
| Super + Esc | Power menu |
| Alt + Tab | Window switcher (release Alt to switch) |
| Super + Tab | Overview of all workspaces |
| Super + Alt + ← / → | Focus the screen on the left / right |
| Super + Alt + Shift + ← / → | Move the window to the screen on the left / right |
| Super + Alt + Tab | Next screen |
| Super + Alt + H / L | The same with vim keys (+ Shift moves the window) |
| Super + 1…0 / + Shift | Workspace 1…10 of the screen you're on / move the window there (each screen has its own 1–9) |
| Print | Screenshot and recording toolbar (Shift: area right away, Ctrl: whole screen) |
| Super + P / Super + Shift + P | Screenshot of an area / a window (replaces hyprshot) |
| Alt + F10 | Save the replay buffer (the last 30 s – 5 min) |
| Super + Shift + R / Super + Ctrl + R | Recording toolbar / stop recording |

No Print key? Super + Shift + R opens the same toolbar.

## What's in it

**Bar.** The main menu button (tools, settings, lock and power; right click for the launcher), workspaces, what's playing (title and artist), clock and date, tray, and a status pill with network, Bluetooth, volume and battery. Optional pills: window title, clipboard, privacy (camera, microphone or screen in use), updates, drives, recording. Top or bottom, on one screen or all.

**Panels from the bar.**
- *Quick settings:* Wi-Fi, Ethernet, Bluetooth, do not disturb, night light, caffeine, microphone, volume per app and per device, system stats, and the charge of every battery. Without a Bluetooth adapter it says why (service off, blocked, no hardware) and can fix the usual causes.
- *Clock panel:* four tabs. Overview (today's events, the weather and the latest notifications), Calendar (month, the chosen day, and your own events with New event), Weather (the next 24 hours and 7 days with rain, wind, UV and the sun) and Notifications. The weather can show next to the clock too.
- *Media menu:* cover, controls, seeking, the player's volume, and every player with its own play/pause.
- *Extras menu:* updates and drives.

**Launcher.** Apps and favourites, calculator, quick links (`yt`, `aw`, `aur`, `gh`…), system and window commands, emoji, snippets (`;`), your own scripts, and `>` for shell commands.

**Notifications.** Pop-ups that stack, history, do not disturb, quiet hours, and muted apps.

**Lock screen.** Clock, the weather, what's playing, battery, notification count, and the wallpaper of each screen. Locks after a set idle time and before suspend.

**Windows.** Alt + Tab with live previews, and an overview of every workspace.

**Screenshots and recording.** Area, window or screen; recording with or without sound, pause, and a timer in the bar. A replay buffer keeps the last 30 s to 5 min of the screen in memory and saves it on Alt + F10, like ShadowPlay (Replay in the capture toolbar; a yellow pill in the bar while it runs; optionally on at login). Draw on a screenshot before saving or copying it: arrows, boxes, the pen, text, numbered steps, a highlighter, blur over private details and crop ("Edit" on the screenshot notification, or the Edit toggle in the capture toolbar to always open it).

**Power.** Power menu (lock, suspend, log out, restart, shut down) with scheduling, a polkit password dialog, low and critical battery warnings, and power profiles.

**Pickers.** Theme and wallpaper, each with search and previews.

**On-screen pop-ups.** Volume, microphone, brightness, keyboard layout and Caps Lock.

## Settings

Settings (Super + ,) changes everything right away and saves it in `settings.json`, next to `shell.qml`. The file is created on first start, is per machine and is not in git. Edits by hand are picked up live.

| Page | What you set |
|---|---|
| Theme | 12 themes, your own themes (New theme: every colour, light or dark), a theme from your wallpaper, accent (presets, your own hex or pipette, or from the wallpaper with any theme); bar glass, panels, corners, blur, borders and shadows, with a live preview |
| Wallpaper, Font, Animations | Wallpaper folder, font and size, speed and style of the panels |
| Bar & panels | Position, style (floating, attached, pills only), size, which pills show, tray click, other screens |
| Sound | Maximum volume, feedback click, following new devices |
| Network & Bluetooth | Saved networks, VPNs, paired devices |
| Notifications | Do not disturb, quiet hours, muted apps |
| Calendars, Weather | ICS calendars (Google, Outlook, Nextcloud…), your place for the weather |
| Displays | Resolution, refresh rate, scale, position, primary screen |
| Night light | Strength, and a schedule (sunset or fixed times) |
| Keyboard & mouse | Layouts, repeat rate, pointer speed, touchpad |
| Power & idle | Lock after, power profile, battery warnings |
| Privacy & lock | What the lock screen shows (and a preview of it), clipboard history |
| Keybinds, Default apps, About | Every bind; browser, files, terminal and more; versions |

Monitor and input settings are written to `hyprland/monitors.lua` and `hyprland/input.lua` (per machine, not in git), loaded after your own Hyprland config. Delete them to go back to yours.

## IPC

Everything the keybinds do can be called from a script: `qs ipc call <target> <function>`. `qs ipc show` lists them all.

| Target | Functions |
|---|---|
| `launcher` | `toggle`, `search <text>` |
| `mainmenu` | `toggle` |
| `quicksettings` | `toggle`, `open <page>` (`main`, `network`, `bluetooth`, `audio`) |
| `settings` | `toggle`, `open <page>` (`theme`, `wallpaper`, `power`, …) |
| `notifications` | `toggle`, `overview`, `calendar`, `weather`, `tab <name>` (switch while open), `dnd`, `clear` |
| `media` | `toggle` |
| `clipboard` | `toggle` |
| `pickers` | `theme`, `wallpaper`, `random`, `set <file>` (a picture or video as wallpaper) |
| `lock` | `lock`, `suspend` |
| `power` | `toggle`, `open <letter>`, `cancel` (a scheduled action) |
| `capture` | `toggle`, `shot <region\|window\|screen>`, `record <region\|window\|screen>`, `pause`, `stop`, `edit <file>` (draw on a picture), `editSave`, `editCopy`, `replay` (start / stop the replay buffer), `replaySave`, `replayStop` |
| `windows` | `next`, `previous`, `commit`, `cancel`, `overview`, `workspace <n>`, `moveToWorkspace <n>` |
| `extras` | `open <updates\|drives>`, `check` |
| `osd` | `caps`, `brightness` |
| `gallery` | `toggle` |

## Development

### Folders

| Folder | What's in it |
|---|---|
| `config/` | `Theme` (colours, sizes, animation timings), `Palettes` (built-in and your own themes), `Config` (settings from `settings.json`) |
| `components/` | Building blocks: `Button`, `IconButton`, `Toggle`, `Segmented`, `Dropdown`, `PillSlider`, `TextField`, `Chip`, `Kbd`, `ListRow`, `GlassPanel`, `Card`, `Label`, `Icon` |
| `services/` | State and system access, one singleton each: `Media`, `Lock`, `Power`, `Clipboard`, `Capture`, `Weather`, `Calendar`, `BatteryWarning`, `BluetoothCheck`, … |
| `modules/` | Every window and panel: `bar`, `quicksettings`, `clockpanel`, `media`, `launcher`, `lock`, `settings`, `windows`, … |
| `widgets/` | Network, sound and battery services from the first bar |
| `hyprland/` | `quickshell.lua`: layer rules, keybinds, and loading the per-machine files |
| `scripts/` | `capture.sh`, `ci/` checks, and `launcher/` (your scripts) |
| `snippets/` | Launcher snippets, see `snippets/README.md` |
| `dev/` | `Gallery`: a test window with every component |

Rules:
- No hard-coded colours or sizes: always use `Theme`.
- Every control is a pill: `radius: Theme.pill(height)`; any other radius goes through `Theme.r(n)`, so the Corners setting reaches it.
- Animations use `Theme.anim.*`, so the speed setting and "Off" work everywhere.
- Panels with text use `Theme.panelSolid`, so they stay readable over bright windows.

### Testing safely

A second copy can run next to your shell. Keybinds keep going to your own shell; call the test copy with `-p`:

```bash
qs -p ~/projects/quickshell-dev
```

```bash
qs ipc -p ~/projects/quickshell-dev call quicksettings toggle
```

These variables make the risky parts safe to try:

| Variable | What it does |
|---|---|
| `QS_POWER_DRYRUN=1` | Power actions (and the critical-battery action) only show a notification |
| `QS_LOCK_TEST=1` | The lock screen really locks, but unlocks by itself after 20 seconds |
| `QS_BATTERY_FAKE=<percent>` | Pretends to be a discharging battery at that level |
| `QS_FAKE=<states>` | Shows states without causing them, comma-separated: `wifi-off`, `no-internet`, `portal`, `bt-off`, `no-audio`, `load`, `annotate-demo` (the drawing editor opens with one of each shape) |
| `QS_BT_FAKE=<problem>` | Shows the Bluetooth hint: `service`, `blocked`, `hardblocked`, `notinstalled`, `nohardware` |
| `QS_CLIPHIST_DB=<file>` | Clipboard history from another cliphist database |
| `QS_GALLERY=1` | Opens the component gallery at start |

For example:

```bash
QS_BATTERY_FAKE=4 QS_POWER_DRYRUN=1 qs -p ~/projects/quickshell-dev
```

### Component gallery

```bash
QS_GALLERY=1 qs -p .
```

Or, with the shell already running:

```bash
qs ipc call gallery toggle
```

Theme and animation speed can be changed live at the top of the window.

### Launcher scripts

Executable files in `scripts/launcher/` show up in the launcher. See `scripts/launcher/README.md`.

## Checks

Every push and every pull request into `develop` or `main` runs GitHub Actions (`.github/workflows/ci.yml`):

| Job | What it checks | Blocks a merge |
|---|---|---|
| Lint | `qmldir` entries point to existing files, no QML syntax errors, no missing imports, the number of qmllint warnings doesn't go up, `shellcheck` on the scripts | Yes |
| Load test | Starts the config in a headless sway for 10 seconds and fails on load errors or JavaScript errors from our own files | Yes |

Run them locally:

```bash
scripts/ci/lint.sh
```

```bash
scripts/ci/load-test.sh
```

The load test uses your running session, so you briefly see a second bar.

When you remove qmllint warnings, lock in the lower count:

```bash
scripts/ci/lint.sh --update
```
