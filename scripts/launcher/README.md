# Launcher scripts

Every executable file in this folder shows up in the launcher (Super + Space)
when you type part of its name. Enter runs it from this folder,
Ctrl + Enter opens it in your editor.

Example, `scripts/launcher/random-wallpaper.sh`:

```sh
#!/bin/sh
awww img "$(find ~/Pictures/wallpapers -type f | shuf -n 1)"
```

Make it executable with `chmod +x`.
