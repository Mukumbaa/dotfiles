hl.window_rule({ name = "windowrule-1", match = { class = ".*" }, suppress_event = "maximize" })

hl.window_rule({
    name = "windowrule-2",
    match = {
        class = "^$",
        title = "^$",
        xwayland = 1,
        float = true,
        fullscreen = false,
        pin = false
    },
    no_focus = true
})

hl.window_rule({
    name = "windowrule-3",
    match = { class = "(menus)" },
    float = true,
    center = true,
    size = "1200 700",
    pin = true
})

-- hl.window_rule({
--     name = "windowrule-4",
--     tag = "+pip",
--     match = { title = "(Picture.?in.?[Pp]icture)" }
-- })

-- hl.window_rule({
--     name = "windowrule-5",
--     match = { tag = "pip" },
--     float = true,
--     keep_aspect_ratio = false,
--     opacity = "1 1",
--     move = "40 ((monitor_h*1)-h-40)",
--     border_size = 2,
--     border_color = "rgb(f6c177)",
--     rounding = 10
-- })

hl.window_rule({
    name = "windowrule-6",
    match = { class = "^(algo)$" },
    float = true,
    pin = true,
    size = "300 360",
    center = true,
    rounding = 10
})

-- hl.window_rule({
--     name = "geometrydash",
--     match = { class = "^(steam_app_322170)$" },
--     center = true
-- })

hl.layer_rule({
    name = "layerrule-1",
    match = { namespace = "logout_dialog" },
    dim_around = true,
    blur = true
})

hl.layer_rule({
    match = { class = "selector" },
    no_anim = true
})

hl.window_rule({
  match = {
    class = "^(xdg-desktop-portal-gtk)$",
  },
  float = true,
  size = {800, 500},
  center = true,
})
-- Dialoghi di autenticazione Polkit e pinentry (GPG)
hl.window_rule({
    match = { class = "^(polkit-gnome-authentication-agent-1|org.kde.polkit-kde-authentication-agent-1|pinentry.*)$" },
    float = true,
    center = true,
    pin = true,
    border_color = "rgb(eb6f92)",
})
hl.window_rule({
    name = "ghidra-popups-fix",
    match = {
        class = "^(ghidra-Ghidra)$",
        title = "^$", -- i popup delle variabili/tooltip spesso non hanno titolo
    },
    no_anim = true,
    no_shadow = true,
    no_focus = true,
})
hl.window_rule({
    name = "ghidra-tooltips-fix",
    match = {
        class = "^(ghidra-Ghidra)$",
        title = "^(win.*)$", -- Java assegna win0, win1, win2... ai popup
    },
    float = true,
    no_initial_focus = true,
    no_focus = true,
    no_anim = true,
    no_shadow = true,
    -- Forza il popup a comparire ESATTAMENTE sotto al cursore (spostato di 15px in basso a destra)
    move = "onscreen cursor 15 15",
})
hl.window_rule({
    name = "ghidra-codebrowser-tile",
    match = {
        class = "^(ghidra-Ghidra)$",
        title = "^(CodeBrowser.*)$",
    },
    tile = true,
})
