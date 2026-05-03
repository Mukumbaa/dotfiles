
hl.config({
    input = {
        kb_layout = "it,us",
        kb_variant = ",altgr-intl",
        kb_model = "",
        kb_options = "ctrl:nocaps",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0.1,
        touchpad = {
            natural_scroll = true,
            scroll_factor = 0.5
        }
    },
})
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.device(
{
    name = "logitech-wireless-receiver-mouse",
    sensitivity = -0.5
})
