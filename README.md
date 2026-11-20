# quickshell-config

## Structure

| Folder | What's in it |
|---|---|
| `config/` | `Theme` (colours, sizes, spacing, animation timings), `Palettes` (the 12 themes), `Config` (settings from `settings.json`) |
| `components/` | Building blocks from the design: `Button`, `IconButton`, `Toggle`, `Segmented`, `PillSlider`, `Chip`, `Kbd`, `ListRow`, `GlassPanel`, `Card`, `Label`, `Icon` |
| `modules/bar/` | The bar: `Workspaces`, `MediaPill`, `ClockPill`, `Tray`, `StatusPill` |
| `modules/notifications/` | Notification pop-ups (stack, fan out on hover) and the card used everywhere |
| `modules/clockpanel/` | Clock panel: month calendar and notification history |
| `modules/osd/` | Pop-up for volume, microphone, brightness, keyboard layout and Caps Lock |
| `modules/launcher/` | Launcher: apps, favorites, calculator, quicklinks (`yt`, `aw`, `aur`, `gh`…), system and window commands, `kill`, your scripts, `>` commands |
| `modules/quicksettings/` | Quick settings panel: toggles, sliders, and network, Bluetooth and sound pages |
| `services/` | `Hypr` (Hyprland actions for Lua and old configs), `Panels` (which panel is open), `Session` (caffeine, night light, brightness, power profiles) |
| `dev/` | `Gallery`: test window with every component |
| `widgets/` | Dropdowns and services from the old bar (moving over feature by feature) |
| `hyprland/` | `quickshell.lua`: Hyprland layer rules (glass blur), loaded from `hyprland.lua` |

Rules:
- No hard-coded colours or sizes: always use `Theme`.
- Every control is a pill: `radius: Theme.pill(height)`.
- Animations use `Theme.anim.*`, so the speed setting and "Off" work everywhere.

`settings.json` is created on first start, next to `shell.qml`. It is per machine and not in git.

## Launcher scripts

Executable files in `scripts/launcher/` show up in the launcher. See `scripts/launcher/README.md`.

## Hyprland

Add this line to `~/.config/hypr/hyprland.lua` for the glass blur:

```lua
pcall(dofile, os.getenv("HOME") .. "/.config/quickshell/hyprland/quickshell.lua")
```

## IPC

| Command | What it does |
|---|---|
| `qs ipc call quicksettings toggle` | Open or close quick settings (Super + A) |
| `qs ipc call quicksettings open network` | Open a page directly: `main`, `network`, `bluetooth`, `audio` |
| `qs ipc call notifications toggle` | Clock panel on the notifications tab (Super + N) |
| `qs ipc call notifications calendar` | Clock panel on the calendar tab |
| `qs ipc call notifications dnd` | Do not disturb on/off (Super + Shift + N) |
| `qs ipc call notifications clear` | Dismiss all notifications |
| `qs ipc call osd caps` | Show the Caps Lock state (bound to Caps Lock) |
| `qs ipc call osd brightness` | Re-read and show the brightness (bound to the brightness keys) |
| `qs ipc call launcher toggle` | Launcher (Super + Space) |
| `qs ipc call launcher search <text>` | Launcher with text already typed |
| `qs ipc call gallery toggle` | Component gallery |

## Component gallery

```bash
QS_GALLERY=1 qs -p .
```

Or, with the shell already running:

```bash
qs ipc call gallery toggle
```

Theme and animation speed can be changed live at the top of the window.

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
