return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        -- popup immediato
        delay = 0,
        preset = "helix",

        win = {
            border = "single",
            no_overlap = false
        },

        plugins = {
            presets = {
                operators = true,
                motions = true,
                text_objects = true,
                windows = true,
                nav = true,
                z = true,
                g = true,
            },
        },
    },
    keys = {
        {
            "<leader>?",
            function()
                require("which-key").show({ global = false })
            end,
            desc = "Buffer Local Keymaps (which-key)",
        },
    },
}
