#!/usr/bin/env bash
# Installs the Quickshell SDDM theme (the login screen in the style of the
# lock screen) and turns it on. Run with sudo from your own account:
#
#   sudo apps/sddm/install.sh            install or update the theme
#   sudo apps/sddm/install.sh --remove   back to the theme you had before
#
# What it does:
#   - copies apps/sddm/quickshell to /usr/share/sddm/themes/quickshell
#   - makes /var/lib/quickshell-sddm, owned by you: the shell writes its
#     colours, font, wallpaper and avatar there (scripts/app-theme.py),
#     since SDDM can't read your home folder
#   - links theme.conf.user in the theme to the theme.conf in that folder
#   - sets the theme in /etc/sddm.conf.d/zz-quickshell.conf (the last file
#     there wins); a Current= in /etc/sddm.conf itself would still win, so
#     that line is commented out (a copy is kept as /etc/sddm.conf.quickshell-bak)
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
theme_dir=/usr/share/sddm/themes/quickshell
sync_dir=/var/lib/quickshell-sddm
conf=/etc/sddm.conf.d/zz-quickshell.conf

[ "$(id -u)" = 0 ] || { echo "Run it with sudo: sudo $0" >&2; exit 1; }
owner="${SUDO_USER:-}"
[ -n "$owner" ] && [ "$owner" != root ] || { echo "Run it with sudo from your own account, not as root." >&2; exit 1; }

if [ "${1:-}" = "--remove" ]; then
  rm -f "$conf"
  rm -rf "$theme_dir" "$sync_dir"
  if [ -f /etc/sddm.conf.quickshell-bak ]; then
    mv /etc/sddm.conf.quickshell-bak /etc/sddm.conf
  fi
  echo "Removed. SDDM uses the theme it had before from the next login screen on."
  exit 0
fi

# The theme
install -d -m 755 "$theme_dir"
install -m 644 "$here"/quickshell/{Main.qml,Icon.qml,metadata.desktop,theme.conf} "$theme_dir"/

# The folder the shell writes to
install -d -m 755 -o "$owner" -g "$(id -gn "$owner")" "$sync_dir"
[ -e "$sync_dir/theme.conf" ] || install -m 644 -o "$owner" "$here/quickshell/theme.conf" "$sync_dir/theme.conf"
ln -sfn "$sync_dir/theme.conf" "$theme_dir/theme.conf.user"

# Turn it on
install -d -m 755 /etc/sddm.conf.d
printf '[Theme]\nCurrent=quickshell\n' > "$conf"
chmod 644 "$conf"
if [ -f /etc/sddm.conf ] && grep -qE '^\s*Current\s*=' /etc/sddm.conf; then
  [ -f /etc/sddm.conf.quickshell-bak ] || cp -p /etc/sddm.conf /etc/sddm.conf.quickshell-bak
  sed -i -E 's/^(\s*Current\s*=)/# \1/' /etc/sddm.conf
fi

echo "Installed. The shell fills in your theme within a few seconds of its next change,"
echo "or right away: qs kill; qs -d"
echo "Try it without logging out: sddm-greeter-qt6 --test-mode --theme $theme_dir"
