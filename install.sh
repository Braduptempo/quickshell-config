#!/usr/bin/env bash
# install.sh: sets up this shell on Arch Linux with Hyprland (Lua config).
#
#   ./install.sh            asks before every step
#   ./install.sh --yes      yes to everything
#   ./install.sh --dry-run  only shows what it would do
#   ./install.sh --minimal  only the packages the shell can't do without
#
# Also works straight from GitHub:
#   curl -fsSL https://raw.githubusercontent.com/Braduptempo/quickshell-config/main/install.sh | bash
#
# Steps: packages (pacman), the config in ~/.config/quickshell, the line in
# hyprland.lua, starting the shell with Hyprland, the system services, and
# (not with --minimal) the SDDM login screen and Spotify (Spicetify).
# Nothing is overwritten without asking; an existing config is backed up.
set -euo pipefail

REPO_URL="https://github.com/Braduptempo/quickshell-config.git"
TARGET="$HOME/.config/quickshell"
HYPR_DIR="$HOME/.config/hypr"
HYPR_LUA="$HYPR_DIR/hyprland.lua"
HYPR_LINE='pcall(dofile, os.getenv("HOME") .. "/.config/quickshell/hyprland/quickshell.lua")'

yes_all=0
dry=0
minimal=0
for arg in "$@"; do
  case "$arg" in
    -y|--yes) yes_all=1 ;;
    -n|--dry-run) dry=1 ;;
    --minimal) minimal=1 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)"; exit 1 ;;
  esac
done

# --- Output and questions -----------------------------------------------------------------
bold=$'\e[1m'; dim=$'\e[2m'; green=$'\e[32m'; yellow=$'\e[33m'; red=$'\e[31m'; reset=$'\e[0m'
step() { printf '\n%s== %s%s\n' "$bold" "$1" "$reset"; }
say() { printf '   %s\n' "$1"; }
ok() { printf '   %s✓%s %s\n' "$green" "$reset" "$1"; }
warn() { printf '   %s!%s %s\n' "$yellow" "$reset" "$1"; }
fail() { printf '%s✗ %s%s\n' "$red" "$1" "$reset"; exit 1; }

# ask "Question?" -> 0 for yes. Reads the terminal, so `curl | bash` works too.
ask() {
  if [ "$yes_all" = 1 ]; then return 0; fi
  if [ "$dry" = 1 ]; then printf '   %s? %s [yes in a dry run]%s\n' "$dim" "$1" "$reset"; return 0; fi
  local answer=""
  printf '   ? %s [Y/n] ' "$1"
  read -r answer < /dev/tty || answer="n"
  case "$answer" in ""|y|Y|yes|j|J|ja) return 0 ;; *) return 1 ;; esac
}

# run cmd args… : shows it, and runs it unless this is a dry run
run() {
  printf '   %s$ %s%s\n' "$dim" "$*" "$reset"
  if [ "$dry" = 0 ]; then "$@"; fi
}

# append_line FILE TEXT : adds text to the end of a file
append_line() {
  printf '   %s>> %s: %s%s\n' "$dim" "$1" "$2" "$reset"
  if [ "$dry" = 0 ]; then printf '\n%s\n' "$2" >> "$1"; fi
}

# --- Checks ----------------------------------------------------------------------------------
step "Checking the system"
command -v pacman >/dev/null || fail "This script is for Arch Linux (pacman not found)."
[ "$(id -u)" != 0 ] || fail "Run it as your own user, not as root; it asks for sudo itself."
ok "Arch Linux, user $(id -un)"
if [ "$dry" = 1 ]; then warn "Dry run: nothing is installed or changed."; fi

# --- Packages --------------------------------------------------------------------------------
step "Packages"
required=(quickshell hyprland networkmanager pipewire wireplumber pipewire-pulse upower libnotify wl-clipboard curl ttf-jetbrains-mono)
# "packages|what they're for"
optional=(
  "bluez bluez-utils|Bluetooth"
  "cliphist|clipboard history"
  "grim slurp gpu-screen-recorder jq|screenshots and recording"
  "awww qt6-multimedia qt6-multimedia-ffmpeg ffmpeg|wallpapers (images and videos)"
  "hyprsunset|night light"
  "brightnessctl|brightness keys"
  "hyprpicker|colour picker"
  "libqalculate fd wtype|launcher: calculator, file search, snippets"
  "pacman-contrib|update count"
  "udisks2|drives"
  "power-profiles-daemon|power profiles"
  "playerctl|media keys"
)

missing() {
  local p
  for p in "$@"; do pacman -Q "$p" >/dev/null 2>&1 || printf '%s\n' "$p"; done
}

mapfile -t need < <(missing "${required[@]}")
if [ "${#need[@]}" -eq 0 ]; then
  ok "Everything the shell needs is installed"
else
  say "Needed: ${need[*]}"
  if ask "Install them?"; then run sudo pacman -S --needed "${need[@]}"; else warn "Skipped: the shell won't start without them"; fi
fi

if [ "$minimal" = 0 ]; then
  extra=()
  for group in "${optional[@]}"; do
    read -r -a pkgs <<< "${group%%|*}"
    mapfile -t gone < <(missing "${pkgs[@]}")
    if [ "${#gone[@]}" -gt 0 ]; then
      say "For ${group#*|}: ${gone[*]}"
      extra+=("${gone[@]}")
    fi
  done
  if [ "${#extra[@]}" -eq 0 ]; then
    ok "All optional packages are installed"
  elif ask "Install the optional ones too? Features without them stay hidden."; then
    run sudo pacman -S --needed "${extra[@]}"
  fi
fi

# --- The config ------------------------------------------------------------------------------
step "The config in $TARGET"
here="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || true)"
if [ -n "$here" ] && [ -f "$here/shell.qml" ] && [ "$here" = "$TARGET" ]; then
  ok "Running from $TARGET itself"
elif [ -d "$TARGET/.git" ] && git -C "$TARGET" remote get-url origin 2>/dev/null | grep -q "quickshell-config"; then
  ok "Already there"
  if ask "Update it (git pull)?"; then run git -C "$TARGET" pull --ff-only; fi
elif [ -e "$TARGET" ]; then
  backup="$TARGET.backup-$(date +%Y%m%d-%H%M%S)"
  warn "$TARGET holds another config"
  if ask "Move it to $backup and put this one there?"; then
    run mv "$TARGET" "$backup"
    run git clone "$REPO_URL" "$TARGET"
  else
    fail "Stopped: the shell needs $TARGET."
  fi
else
  if ask "Download it there (git clone)?"; then
    command -v git >/dev/null || run sudo pacman -S --needed git
    run git clone "$REPO_URL" "$TARGET"
  else
    fail "Stopped: the shell needs $TARGET."
  fi
fi

# --- Hyprland -------------------------------------------------------------------------------
step "Hyprland"
if [ -f "$HYPR_LUA" ]; then
  if grep -qF "quickshell/hyprland/quickshell.lua" "$HYPR_LUA"; then
    ok "hyprland.lua loads the shell's rules and keys"
  elif ask "Add the line for the shell's rules and keys to hyprland.lua?"; then
    append_line "$HYPR_LUA" "-- Quickshell: glass blur, layer rules and keys, kept in the quickshell repo
$HYPR_LINE"
  fi

  # Start the shell with Hyprland, unless something already does
  if grep -rqsE 'qs (kill; qs )?-d|exec.*quickshell' "$HYPR_DIR"; then
    ok "Hyprland already starts the shell"
  elif ask "Start the shell with Hyprland?"; then
    starts='hl.exec_cmd("qs -d")'
    if pacman -Q awww >/dev/null 2>&1 && ! grep -rqs 'awww-daemon' "$HYPR_DIR"; then
      starts="$starts
  hl.exec_cmd(\"awww-daemon\")"
    fi
    append_line "$HYPR_LUA" "-- Start the shell (and the wallpaper daemon) with Hyprland
hl.on(\"hyprland.start\", function()
  $starts
end)"
  fi
elif [ -f "$HYPR_DIR/hyprland.conf" ]; then
  warn "Found hyprland.conf but no hyprland.lua: the shell's keys and rules need the Lua config."
  say "Once you use hyprland.lua, add this line at the end:"
  say "  $HYPR_LINE"
else
  warn "No Hyprland config yet. Start Hyprland once, then run this script again."
fi

# --- Services -------------------------------------------------------------------------------
step "System services"
services=(NetworkManager)
if pacman -Q bluez >/dev/null 2>&1; then services+=(bluetooth); fi
if pacman -Q power-profiles-daemon >/dev/null 2>&1; then services+=(power-profiles-daemon); fi
off=()
for s in "${services[@]}"; do
  if ! systemctl is-enabled --quiet "$s" 2>/dev/null || ! systemctl is-active --quiet "$s" 2>/dev/null; then off+=("$s"); fi
done
if [ "${#off[@]}" -eq 0 ]; then
  ok "Running: ${services[*]}"
elif ask "Turn on ${off[*]} (now and at every boot)?"; then
  run sudo systemctl enable --now "${off[@]}"
fi

if [ "$minimal" = 0 ]; then
  # --- Login screen (SDDM) ---------------------------------------------------------------------
  # The lock screen's look for SDDM: apps/sddm/install.sh (sudo) installs the theme and the
  # folder the shell keeps its colours and wallpaper in (scripts/app-theme.py fills it)
  step "Login screen (SDDM)"
  sddm_theme=/usr/share/sddm/themes/quickshell
  if ! pacman -Q sddm >/dev/null 2>&1; then
    say "SDDM isn't installed: skipped (the shell's login screen is an SDDM theme)"
  elif [ -d "$sddm_theme" ] && cmp -s "$TARGET/apps/sddm/quickshell/Main.qml" "$sddm_theme/Main.qml" \
       && [ -d /var/lib/quickshell-sddm ] && grep -rqs '^Current=quickshell' /etc/sddm.conf.d; then
    ok "SDDM uses the shell's login screen"
  elif [ -d "$sddm_theme" ]; then
    if ask "Update the shell's login screen for SDDM?"; then run sudo "$TARGET/apps/sddm/install.sh"; fi
  elif ask "Give SDDM the shell's login screen (the lock screen's look, follows your theme)?"; then
    run sudo "$TARGET/apps/sddm/install.sh"
  fi

  # --- Spotify (Spicetify) ---------------------------------------------------------------------
  # Spotify follows the shell's theme through Spicetify and its "text" theme; scripts/app-theme.py
  # builds the Glass theme on top of it and runs `spicetify apply` the next time the shell starts
  step "Spotify"
  spotify_dir=""
  if pacman -Q spotify-launcher >/dev/null 2>&1; then
    spotify_dir="$HOME/.local/share/spotify-launcher/install/usr/share/spotify"
  elif pacman -Q spotify >/dev/null 2>&1; then
    spotify_dir="/opt/spotify"
  fi
  aur=""
  for helper in yay paru; do command -v "$helper" >/dev/null && { aur="$helper"; break; }; done
  spicetify_conf="$HOME/.config/spicetify/config-xpui.ini"
  text_theme="$HOME/.config/spicetify/Themes/text"

  if [ -z "$spotify_dir" ]; then
    if command -v flatpak >/dev/null && flatpak list 2>/dev/null | grep -qi spotify; then
      warn "Spotify from Flatpak can't be themed by Spicetify; spotify-launcher can"
    else
      say "Spotify isn't installed (spotify-launcher or spotify): skipped"
    fi
  elif [ ! -d "$spotify_dir" ] || [ ! -f "$HOME/.config/spotify/prefs" ]; then
    warn "Start Spotify once (and log in), then run this script again so it can follow your theme"
  else
    # spicetify itself, from the AUR
    if ! command -v spicetify >/dev/null; then
      if [ -z "$aur" ]; then
        warn "Spicetify comes from the AUR: install yay or paru, then run this script again"
      elif ask "Install Spicetify (AUR) so Spotify follows the shell's theme?"; then
        run "$aur" -S --needed spicetify-cli
      fi
    fi

    if command -v spicetify >/dev/null || [ "$dry" = 1 ]; then
      # Where Spotify is: spicetify finds /opt/spotify, not spotify-launcher's copy
      if ! grep -qE "^spotify_path\s*=\s*$spotify_dir\s*$" "$spicetify_conf" 2>/dev/null; then
        run spicetify -q config spotify_path "$spotify_dir" prefs_path "$HOME/.config/spotify/prefs"
      fi
      # The AUR's /opt/spotify belongs to root; Spicetify has to write in it (its own advice)
      if [ ! -w "$spotify_dir" ] || [ ! -w "$spotify_dir/Apps" ]; then
        if ask "Let your user change $spotify_dir so Spicetify can theme it?"; then
          run sudo chmod a+wr "$spotify_dir"
          run sudo chmod -R a+wr "$spotify_dir/Apps"
        fi
      fi
      # The "text" theme the shell's Glass theme builds on
      if [ -f "$text_theme/user.css" ]; then
        ok "Spicetify's text theme is there"
      elif ask "Download Spicetify's text theme (the shell's Glass theme builds on it)?"; then
        tmp="$(mktemp -d)"
        run git clone -q --depth 1 --filter=blob:none --sparse https://github.com/spicetify/spicetify-themes "$tmp/themes"
        run git -C "$tmp/themes" sparse-checkout set text
        run mkdir -p "$HOME/.config/spicetify/Themes"
        run cp -r "$tmp/themes/text" "$text_theme"
        rm -rf "$tmp"
      fi
      # A backup of the untouched Spotify, which `spicetify apply` needs
      if awk '/^\[Backup\]/{f=1;next} /^\[/{f=0} f && /^version *= *[^ ]/{b=1} END{exit !b}' "$spicetify_conf" 2>/dev/null; then
        ok "Spicetify has a backup of Spotify"
      else
        run spicetify -q backup
      fi
      say "The shell themes Spotify the next time it starts (or after you pick a theme)."
    fi
  fi
fi

# --- Done -----------------------------------------------------------------------------------
step "Done"
if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  if ask "Start the shell now (and reload Hyprland)?"; then
    run hyprctl reload
    run sh -c "qs kill >/dev/null 2>&1; qs -d"
  fi
else
  say "Log in to Hyprland and the shell starts by itself."
fi
say "Super + Space: launcher · Super + A: quick settings · Super + , : settings · Super + X: main menu"
