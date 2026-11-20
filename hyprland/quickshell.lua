-- Quickshell rules for Hyprland (Lua config).
-- Loaded from ~/.config/hypr/hyprland.lua with:
--   pcall(dofile, os.getenv("HOME") .. "/.config/quickshell/hyprland/quickshell.lua")
--
-- Every Quickshell layer uses a namespace starting with "quickshell"
-- (bar, panels, OSD). Hyprland blurs what is behind them, which turns the
-- translucent panels into glass. Quickshell animates its panels itself, so
-- Hyprland's layer animation is turned off for them to avoid double motion.

hl.layer_rule({
    name  = "quickshell-glass",
    match = { namespace = "^quickshell" },

    blur         = true,
    -- Only blur behind pixels that are at least 20% opaque, so the rounded
    -- corners and shadows don't get a blurred box around them
    ignore_alpha = 0.2,
    no_anim      = true,
})

-- Shell keybinds. They call Quickshell over IPC, so they work as long as
-- the shell runs (`qs ipc show` lists every target).
hl.bind("SUPER + A", hl.dsp.exec_cmd("qs ipc call quicksettings toggle"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))
hl.bind("SUPER + SHIFT + N", hl.dsp.exec_cmd("qs ipc call notifications dnd"))
-- Clipboard history (Super + V stays "float window" from modules/keybinds.lua)
hl.bind("SUPER + SHIFT + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))

-- On-screen pop-ups. Volume and microphone are picked up automatically.
-- Brightness keys: tell the shell to re-read the level after brightnessctl.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("sleep 0.05; qs ipc call osd brightness"), { locked = true, repeating = true, non_consuming = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sleep 0.05; qs ipc call osd brightness"), { locked = true, repeating = true, non_consuming = true })
-- Caps Lock has no event; this bind doesn't swallow the key
hl.bind("Caps_Lock", hl.dsp.exec_cmd("qs ipc call osd caps"), { non_consuming = true })

-- Launcher: takes Super + Space over from the menu in modules/keybinds.lua
-- (this file is loaded after it). Remove these two lines to get rofi back.
hl.unbind("SUPER + space")
hl.bind("SUPER + space", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
