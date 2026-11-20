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
