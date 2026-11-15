hl.config({
    general = {
        gaps_in = 3,
        gaps_out = 5,
        border_size = 1,
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding = 0,
        active_opacity = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled = false,
        },

        blur = {
            enabled = false,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },

    dwindle = {
        preserve_split = true,
        force_split = 2,
        use_active_for_splits = true,
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        allow_session_lock_restore = true,
        focus_on_activate = true,
        anr_missed_pings = 3,
        on_focus_under_fullscreen = 1,
        initial_workspace_tracking = 1,
    },

    cursor = {
        hide_on_key_press = true,
        no_hardware_cursors = false,
    },
})

-- =========================
-- Curve & Animazioni
-- =========================
-- Default curves and animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } }
)-- Default springs
hl.curve("easy",           { type = "spring", mass = 1, stiffness = 71.2633, dampening = 15.8273644 })

hl.animation({ leaf = "global",      enabled = true,  speed = 10,  bezier = "default" })
hl.animation({ leaf = "border",      enabled = true,  speed = 2,   bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 1.5, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 1.5, bezier = "quick",        style = "popin 87%" })
hl.animation({ leaf = "windowsMove", enabled = false })
hl.animation({ leaf = "fadeIn",      enabled = true,  speed = 1.7, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",     enabled = true,  speed = 1.5, bezier = "almostLinear" })
hl.animation({ leaf = "fade",        enabled = true,  speed = 3,   bezier = "quick" })
hl.animation({ leaf = "layers",      enabled = false })
hl.animation({ leaf = "workspaces",  enabled = false })
