-- hl.config({
--     monitor = {
--         ",2880x1800@90,auto,1.8,vrr,0"
--     }
-- })

hl.monitor({
    output = "eDP-1",
    mode = "2880x1800@90",
    position = "0x0",
    scale = "1.8",
    vrr = 0
})
hl.workspace_rule({ workspace = "1", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "3", monitor = "eDP-1" })
hl.workspace_rule({ workspace = "5", monitor = "eDP-1" })
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto-left",
    scale = "1"
})
